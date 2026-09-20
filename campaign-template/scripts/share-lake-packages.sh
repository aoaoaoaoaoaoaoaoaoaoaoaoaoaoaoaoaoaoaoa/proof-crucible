#!/usr/bin/env bash
set -euo pipefail

INVOCATION_ROOT="$(git rev-parse --show-toplevel)"
readonly INVOCATION_ROOT
GIT_COMMON_DIR="$(git rev-parse --path-format=absolute --git-common-dir)"
readonly GIT_COMMON_DIR
PRIMARY_ROOT="$(dirname -- "$GIT_COMMON_DIR")"
readonly PRIMARY_ROOT
readonly POOL_ROOT="$PRIMARY_ROOT/.lake/shared-packages"
readonly DETACHED_ROOT="$POOL_ROOT/.detached"
readonly HOOK="$GIT_COMMON_DIR/hooks/post-checkout"
readonly HOOK_SOURCE="$PRIMARY_ROOT/.githooks/post-checkout"

die() {
  printf 'share-lake-packages: %s\n' "$*" >&2
  exit 1
}

worktree_root() {
  git -C "$1" rev-parse --show-toplevel
}

assert_same_repository() {
  local common
  common="$(git -C "$1" rev-parse --path-format=absolute --git-common-dir)"
  [[ "$common" == "$GIT_COMMON_DIR" ]] ||
    die "'$1' is not a worktree of '$PRIMARY_ROOT'"
}

package_fingerprint() {
  local root="$1"
  local file
  local -a lock=("$root/lean-toolchain" "$root/lake-manifest.json")

  for file in "${lock[@]}"; do
    [[ -f "$file" ]] || die "missing package lock input '$file'"
  done

  sha256sum "${lock[@]}" |
    cut -d ' ' -f 1 |
    sha256sum |
    cut -d ' ' -f 1
}

directory_is_empty() {
  [[ -z "$(find "$1" -mindepth 1 -maxdepth 1 -print -quit)" ]]
}

assert_pristine_package_tree() {
  local tree="$1"
  local manifest="$2"
  local actual expected head name package remote rev url

  jq -e 'all(.packages[]; .type == "git")' "$manifest" >/dev/null ||
    die "'$manifest' contains a non-Git dependency"

  expected="$(jq -r '.packages[].name' "$manifest" | sort)"
  actual="$(find "$tree" -mindepth 1 -maxdepth 1 -printf '%f\n' | sort)"
  [[ "$actual" == "$expected" ]] ||
    die "'$tree' does not contain exactly the manifest package set"

  while IFS=$'\t' read -r name rev url; do
    package="$tree/$name"
    [[ -d "$package/.git" ]] || die "'$package' is not a Git checkout"

    head="$(git -C "$package" rev-parse HEAD)"
    [[ "$head" == "$rev" ]] ||
      die "'$package' is at $head, expected $rev"

    [[ -z "$(git -C "$package" status --porcelain --untracked-files=all)" ]] ||
      die "'$package' contains uncommitted source"

    remote="$(git -C "$package" remote get-url origin)"
    [[ "${remote%.git}" == "${url%.git}" ]] ||
      die "'$package' has remote '$remote', expected '$url'"
  done < <(jq -r '.packages[] | [.name, .rev, .url] | @tsv' "$manifest")
}

replace_with_link() {
  local packages="$1"
  local pool="$2"
  ln -s "$(package_link_target "$packages" "$pool")" "$packages"
}

package_link_target() {
  local packages="$1"
  local pool="$2"
  realpath --relative-to="$(dirname -- "$packages")" "$pool"
}

path_is_below() {
  local path root
  path="$(readlink -f -- "$1")"
  root="$(readlink -f -- "$2")"
  [[ "$path" == "$root"/* ]]
}

adopt_detached_tree() {
  local packages="$1"
  local tree="$2"
  local pool="$3"
  local manifest="$4"

  assert_pristine_package_tree "$tree" "$manifest"
  if directory_is_empty "$pool"; then
    unlink -- "$packages"
    rmdir -- "$pool"
    mv -- "$tree" "$pool"
    replace_with_link "$packages" "$pool"
  else
    assert_pristine_package_tree "$pool" "$manifest"
    unlink -- "$packages"
    replace_with_link "$packages" "$pool"
    rm -rf -- "$tree"
  fi
}

share_worktree() {
  local root
  root="$(worktree_root "$1")"
  assert_same_repository "$root"

  local manifest="$root/lake-manifest.json"
  local fingerprint
  fingerprint="$(package_fingerprint "$root")"
  local pool="$POOL_ROOT/$fingerprint"
  local lake="$root/.lake"
  local packages="$root/.lake/packages"

  mkdir -p -- "$pool"
  if [[ -L "$lake" ]]; then
    unlink -- "$lake"
    mkdir -- "$lake"
  elif [[ ! -e "$lake" ]]; then
    mkdir -- "$lake"
  elif [[ ! -d "$lake" ]]; then
    die "'$lake' is neither a directory nor a symbolic link"
  fi

  if [[ -L "$packages" ]]; then
    if [[ "$(readlink -- "$packages")" == "$(package_link_target "$packages" "$pool")" ]] &&
      [[ "$(readlink -f -- "$packages")" == "$(readlink -f -- "$pool")" ]]; then
      return
    fi
    local linked
    linked="$(readlink -f -- "$packages")"
    if path_is_below "$linked" "$DETACHED_ROOT"; then
      adopt_detached_tree "$packages" "$linked" "$pool" "$manifest"
      return
    fi
    unlink -- "$packages"
    replace_with_link "$packages" "$pool"
    return
  fi

  if [[ ! -e "$packages" ]]; then
    replace_with_link "$packages" "$pool"
    return
  fi

  [[ -d "$packages" ]] || die "'$packages' is neither a directory nor a symbolic link"

  if directory_is_empty "$packages"; then
    rmdir -- "$packages"
  elif directory_is_empty "$pool"; then
    assert_pristine_package_tree "$packages" "$manifest"
    rmdir -- "$pool"
    mv -- "$packages" "$pool"
  else
    assert_pristine_package_tree "$packages" "$manifest"
    assert_pristine_package_tree "$pool" "$manifest"
    rm -rf -- "$packages"
  fi

  replace_with_link "$packages" "$pool"
}

detach_worktree() {
  local root
  root="$(worktree_root "$1")"
  assert_same_repository "$root"
  local packages="$root/.lake/packages"
  if [[ -L "$packages" ]] && path_is_below "$packages" "$DETACHED_ROOT"; then
    return
  fi

  local active
  active="$(find -H "$DETACHED_ROOT" -mindepth 1 -maxdepth 1 -type d \
    ! -name '.copying.*' -print -quit)"
  [[ -z "$active" ]] ||
    die "another package update is detached at '$active'; reconcile it first"

  share_worktree "$root"
  [[ -L "$packages" ]] || die "'$packages' was not linked after reconciliation"

  local detached source scratch token
  source="$(readlink -f -- "$packages")"
  [[ -d "$source" ]] || die "package link '$packages' has no directory target"
  scratch="$(mktemp -d "$DETACHED_ROOT/.copying.XXXXXXXX")"

  if ! cp -a --reflink=auto "$source/." "$scratch/"; then
    rm -rf -- "$scratch"
    die "could not detach '$packages'"
  fi
  token="${scratch##*/.copying.}"
  detached="$DETACHED_ROOT/$token"
  mv -- "$scratch" "$detached"
  unlink -- "$packages"
  replace_with_link "$packages" "$detached"
}

collect_unused_pools() {
  local field packages pool root target
  local -A live=()

  while IFS= read -r -d '' field; do
    [[ "$field" == worktree\ * ]] || continue
    root="${field#worktree }"
    packages="$root/.lake/packages"
    [[ -L "$packages" ]] || continue
    target="$(readlink -f -- "$packages")"
    [[ -n "$target" ]] && live["$target"]=1
  done < <(git worktree list --porcelain -z)

  while IFS= read -r -d '' pool; do
    target="$(readlink -f -- "$pool")"
    [[ ${live[$target]+present} ]] && continue
    printf 'Collecting unreferenced Lake package pool %s\n' "$pool"
    rm -rf -- "$pool"
  done < <(
    find -H "$POOL_ROOT" -mindepth 1 -maxdepth 1 -type d \
      \( -name '.detached' -o -name '.copying.*' \) -prune -o -type d -print0
    find -H "$DETACHED_ROOT" -mindepth 1 -maxdepth 1 -type d -print0
  )
}

install_hook() {
  [[ -x "$HOOK_SOURCE" ]] || die "missing executable hook source '$HOOK_SOURCE'"
  if [[ -e "$HOOK" || -L "$HOOK" ]]; then
    [[ "$(readlink -f -- "$HOOK")" == "$(readlink -f -- "$HOOK_SOURCE")" ]] ||
      die "refusing to replace existing hook '$HOOK'"
    return
  fi

  local relative
  relative="$(realpath --relative-to="$(dirname -- "$HOOK")" "$HOOK_SOURCE")"
  ln -s "$relative" "$HOOK"
}

share_all() {
  local field root
  local -a roots=()

  while IFS= read -r -d '' field; do
    [[ "$field" == worktree\ * ]] && roots+=("${field#worktree }")
  done < <(git worktree list --porcelain -z)

  for root in "${roots[@]}"; do
    share_worktree "$root"
  done
}

usage() {
  printf '%s\n' \
    'usage: scripts/share-lake-packages.sh [WORKTREE]' \
    '       scripts/share-lake-packages.sh --all' \
    '       scripts/share-lake-packages.sh --detach [WORKTREE]' \
    '       scripts/share-lake-packages.sh --gc' \
    '       scripts/share-lake-packages.sh --install'
}

mkdir -p -- "$DETACHED_ROOT"
exec 9>"$PRIMARY_ROOT/.lake/shared-packages.lock"
flock 9

case "${1:-}" in
  --all)
    [[ $# -eq 1 ]] || { usage >&2; exit 64; }
    share_all
    ;;
  --detach)
    [[ $# -le 2 ]] || { usage >&2; exit 64; }
    detach_worktree "${2:-$INVOCATION_ROOT}"
    ;;
  --gc)
    [[ $# -eq 1 ]] || { usage >&2; exit 64; }
    collect_unused_pools
    ;;
  --install)
    [[ $# -eq 1 ]] || { usage >&2; exit 64; }
    install_hook
    share_all
    ;;
  --help|-h)
    usage
    ;;
  --*)
    usage >&2
    exit 64
    ;;
  *)
    [[ $# -le 1 ]] || { usage >&2; exit 64; }
    share_worktree "${1:-$INVOCATION_ROOT}"
    ;;
esac
