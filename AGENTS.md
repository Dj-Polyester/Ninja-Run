# Large-task orchestration

`TASK.md` describes the complete target product, not a single atomic implementation task.

Do not attempt to implement the entire specification in one pass.

The parent agent acts as the lead engineer and must decompose TASK.md into milestones before major implementation begins.

Maintain a working milestone plan in `PLAN.md`.

For each milestone:

1. inspect the relevant repository state
2. identify dependencies on earlier milestones
3. delegate repository investigation to `explorer` when useful
4. split implementation into independent subtasks
5. delegate implementation to `implementer`
6. parallelize only subtasks that do not modify overlapping systems
7. integrate returned changes
8. delegate validation to `tester`
9. resolve failures
10. use `reviewer` for major architectural or cross-system changes
11. update `PLAN.md`
12. proceed to the next milestone only when the current milestone is functional

## Subagent policy

Use `explorer` for:

* mapping assets to intended features
* finding spritesheets and animations
* examining existing scenes/scripts
* locating related resources
* determining existing project conventions

Use `implementer` for:

* normal feature implementation
* scene creation
* game logic
* UI implementation
* automated tests
* bug fixes

Multiple implementers may run in parallel only when their file ownership does not overlap.

Use `tester` after each meaningful milestone.

Use `reviewer` for:

* core architecture
* procedural-generation architecture
* persistent player progression
* save/load
* complex ability interactions
* weapon/enemy framework design
* major integration milestones

Do not invoke reviewer for repetitive content creation.

## Completion

Do not claim TASK.md is complete until every requirement has been mapped to a completed milestone and corresponding tests or validation.
