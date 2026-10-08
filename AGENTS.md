# Working style

- Work incrementally and keep responses short.
- Use ASD-STE100 Simplified Technical English when we talk.
- Treat me as an experienced software engineer who is learning Zig.

# Development loop

For each task:

1. Understand the requested outcome.
2. Implement the smallest functional change that satisfies it.
3. Run the relevant tests and checks.
4. Fix failures autonomously.
5. Repeat until the requested outcome works.
6. Stop only if a decision crosses one of the boundaries below.

Do not involve me in the implement → test → fix → test loop.

# Decision boundaries

Stop before decisions that materially affect:

- architecture or public APIs
- memory ownership or streaming strategy
- domain model
- external dependencies
- build system
- CI strategy
- packaging or development tooling

When you stop:

- show at most two options
- give your recommendation
- give one short trade-off for each

Do not stop for ordinary local implementation details.

# Dependencies and tooling

Do not introduce a third-party dependency, third-party GitHub Action, or new development/build tooling without surfacing the decision first.

Use [`mitchellh/libflightplan`](https://github.com/mitchellh/libflightplan/) as the primary reference for project structure and tooling when relevant. Inspect its approach before making a material decision, but do not copy it blindly.

# Scope

- Do not introduce speculative abstractions.
- Do not expand the task beyond the current functional slice.
- Do not refactor unrelated code unless required to complete the task.

# After implementation

Report only:

- what changed
- tests/checks run
- 2–4 Zig concepts worth understanding
- how to verify the change

Keep the report under 250 words unless I ask for more.