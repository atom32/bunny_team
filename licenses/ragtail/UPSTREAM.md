# Ragtail rotation-first-fit adaptation

Upstream: https://github.com/euuuuuuan/ragtail-public

Pinned commit: `5d820cd6e9eed9286dd44e8a4d5e02138c929f16` (2026-07-30).

Copyright 2026 Ragtail contributors. The adapted source and test cases are
licensed under Apache-2.0. The verbatim upstream `LICENSE` and `NOTICE` are
preserved beside this record. Their third-party/media references describe the
upstream distribution; those packages and media are **not** included here.

## Source mapping

- Algorithm: `src/logic/grid_inventory.gd`, `_first_fit()`, lines 49-57:
  https://github.com/euuuuuuan/ragtail-public/blob/5d820cd6e9eed9286dd44e8a4d5e02138c929f16/src/logic/grid_inventory.gd#L49-L57
- Tests: `tests/unit/test_grid_inventory.gd`, row-major placement and rotation
  into a vertical gap, lines 42-69:
  https://github.com/euuuuuuan/ragtail-public/blob/5d820cd6e9eed9286dd44e8a4d5e02138c929f16/tests/unit/test_grid_inventory.gd#L42-L69
- Local adaptation: `scripts/ui/stash/stash_layout.gd`,
  `_find_sort_placement()` called only by `sort_items()`.
- Local tests: `tests/stash_rotation_test.gd`, `_test_rotation_gap()` and
  `_test_first_fit_priority()`; other tests exercise this project's own APIs.

## Local modifications (2026-10-16)

- Adapted the row-major, per-cell unrotated-before-rotated search to the
  existing 12-column, expanding warehouse and its `can_place()` implementation.
- Replaced upstream `LootItem`/dictionary placements with existing instance IDs
  and `[x, y, rotated]` arrays. No upstream inventory storage, ownership,
  weight, appraisal, registry, UI, or asset code was imported.
- Limited automatic rotation to the explicit SORT action. `reconcile()`,
  fixed-orientation `find_space()`, manual move/rotation, equipment slots and
  save schema are unchanged.
- Adapted the rotation-gap test to an 11x2 blocker in the existing 12-column
  warehouse; rewrote assertions for the project's scene-based test harness.
  No GUT dependency was added.
- P1 follow-up (2026-10-16): if the adapted search finds no valid placement,
  restore the complete pre-SORT layout instead of storing its negative-coordinate
  sentinel. Added a local fault-injection test for exhausting both orientations
  after a partial sort. The upstream search order, manual operations and save
  schema are unchanged; this failure guard is local code, not another import.
  Rechecked LICENSE/NOTICE byte-for-byte against the pinned commit and corrected
  the source/test line anchors above; neither upstream notice was modified.

Only the identified adaptation is covered by this upstream notice; it does
not relicense unrelated existing project code or any game assets. Preserve
this record, the Apache-2.0 license and applicable upstream notices when
redistributing the adaptation.
