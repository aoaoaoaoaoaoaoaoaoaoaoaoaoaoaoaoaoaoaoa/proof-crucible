# Compatibility

## Protocol

An event's `protocol` integer selects its complete validity and semantic law.
Protocol 1 became immutable when the first conforming campaign event was
accepted. Any change to accepted fields, required fields, transition rules,
reference meaning, or node identity requires Protocol 2. Existing events are
never migrated or rewritten.

## Distribution

The distribution uses semantic versions independently of the event protocol:

- patch releases repair implementations or clarify prose without changing
  protocol semantics;
- minor releases add compatible commands, projections, or skill guidance;
- major releases may add protocol versions or remove tool compatibility.

Campaigns pin an exact distribution commit through the `.crucible` gitlink.
The gitlink is the sole distribution-version authority inside a campaign.
`crucible.toml` declares the protocol emitted by that campaign, not a duplicate
tool revision.

An upgrade changes only the gitlink, runs `crucible doctor`, the ledger check,
and the campaign's complete formal gate, then lands as a non-node maintenance
commit. Compatible upgrades never rewrite ledger events.
