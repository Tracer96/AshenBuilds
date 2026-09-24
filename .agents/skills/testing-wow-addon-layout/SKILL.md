---
name: testing-wow-addon-layout
description: Validate WoW 1.12/Turtle WoW addon Lua UI changes when a game client is unavailable.
---

# Testing WoW addon layouts without a client

## Devin Secrets Needed

None.

## Runtime validation

- Use Lua 5.1 for Vanilla/Turtle compatibility (`sudo apt-get install -y lua5.1` when absent).
- Parse every addon Lua file with `find . -type f -name '*.lua' -print0 | xargs -0 -n1 luac5.1 -p`.
- Load the changed Lua file in a small mock of only the WoW frame methods reached by the changed functions; invoke the actual functions rather than copying their logic.
- Prefer real catalog/database fixtures with intentionally unequal text heights so pairing, ordering, and overflow calculations are distinguishable from a broken single-column layout.

## Visual validation

- If the user permits realistic simulation and no game client exists, create the simulator outside the repository and label it prominently as a deterministic simulation.
- Mirror source pixel widths, heights, anchors, line spacing, and scroll range; show those constants in the harness so reviewers can trace evidence back to code.
- Provide explicit controls for empty, one-item, paired, odd-count, and overflow states plus every conditional row branch.
- Verify both wheel and direct scrollbar access. Ensure non-overflow states have no misleading decorative scroll affordance.
- Keep the report explicit that a browser simulation is not in-game rendering; pair visual evidence with exact-function Lua assertions.

## Evidence

- Record only the focused visual flow, not dependency installation or shell output.
- Annotate preconditions, state transitions, and consolidated pass/fail checks.
- Capture top-of-scroll and bottom-of-scroll screenshots, plus conditional before/after states.
