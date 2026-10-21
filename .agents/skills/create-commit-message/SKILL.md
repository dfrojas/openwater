---
name: create-commit-messages
description: Draft, review, or create commit messages using Conventional Commits and adapted Linux kernel guidance. Use when asked to write a commit message, improve one, or commit staged changes.
---

# Create commit messages

Write a commit message that a future reader can understand without the
current conversation. Use Conventional Commits for structure. Explain why
the change belongs in the project, with enough evidence to support it.

## Read the change

Read the repository's contribution instructions. Inspect `git status`,
`git diff`, `git diff --cached`, and `git log --oneline -10`. Use the
conversation for intent and the diff for what actually changed.

Base a pending commit message on the staged diff. Unstaged and untracked
changes are context, not part of that commit. If nothing is staged, identify
the intended files before staging. Stage only changes within the user's
requested commit scope. Never include secrets. A message-only request does
not authorize staging or committing.

If you detect sensitive data, exclude it from the commit and alert the user.
Name the affected file and the kind of data without displaying the value.
If it is already staged, do not commit until it is excluded. Preserve the
working files. This rule also applies when the user wants one combined commit.

If staged changes are unrelated, show a grouping proposal in the chat.
Use one line per group: file paths, `->`, and a short commit summary:

```text
parser.py test_parser.py -> fix(parser): reject empty input
ci.yml -> ci: rename the Linux test job
```

Give one very short sentence explaining why these groups belong in separate
commits. This is a proposal only. Change the grouping in the index and split
the commits only after the user explicitly approves. Preserve partial staging
and keep unstaged edits out. Without approval to split, prepare one commit
with all non-sensitive staged changes. Commit creation still requires the
confirmation described below.

Keep a feature or fix with its supporting tests and docs. Separate unrelated
work, not file types. Keep code moves separate from edits to the moved code
when practical. Each commit should build and work on its own so that
`git bisect` remains useful. Order dependent changes and explain dependencies
that are not clear from the history.

## Write the message

Use this shape. Brackets indicate optional parts and are not literal text:

```text
<type>[(<scope>)][!]: <description>

[body]

[footers]
```

Choose the type from the change's purpose. Use `feat` for a new application
or library feature and `fix` for a bug correction. Other noun types are
allowed. Follow repository usage: `refactor` for restructuring, `perf` for
performance, `docs` for documentation, `test` for tests, `style` for formatting,
`build` for build or dependency changes, `ci` for CI, and `chore` for other
maintenance. These additional types are conventions, not a closed list.

Prefer a scope when one module or capability describes the change. The
scope is a noun in parentheses, such as `(parser)`. Use the repository's
established names, in kebab-case, and omit it for cross-cutting work.

Start the description immediately after the required colon and space.
Write in English, use lowercase types, and begin with an imperative verb:
`reject`, `add`, or `remove`. Make the complete first line at most 72
characters, with no final period. Name the specific change instead of a
filename or a vague action. These style choices are local conventions.
Conventional Commits is case-insensitive except for the breaking-change
footer token, which must be uppercase.

If the summary explains the whole change, stop there:

```text
docs: correct the project name in the README
```

Otherwise, explain the problem, its user-visible effect, and how the change
addresses it. Include the conditions that trigger a bug and any non-obvious
design choice or cost. Describe the mechanism without narrating the diff.
A short error message or reproduction detail can help a future reader find
the fix. A link alone cannot explain it.

The body is optional and free-form, with any number of paragraphs. Separate
it from the description with one blank line. Prefer short paragraphs and
use bullets when clearer. Wrap prose at about 72 characters, but keep URLs
and reference footers intact. Avoid em-dashes. Keep lasting reasoning in
the commit and temporary review notes in the pull request.

Mark an incompatible change with `!` immediately before the colon, a
`BREAKING CHANGE: <description>` footer, or both. This applies to any type.
If `!` is the only marker, the summary must describe the incompatibility.
Use a footer when users need migration instructions:

```text
refactor(api)!: rename parse to parseAlloc

Make the allocation requirement visible at the call site.

BREAKING CHANGE: replace parse(allocator, input) with
  parseAlloc(allocator, input). The old name is removed.
```

`BREAKING-CHANGE` is an equivalent footer token. Prefer `BREAKING CHANGE`
when writing a new message.

Separate optional footers from the body with one blank line, or from the
summary if there is no body. Each footer has a word token, either `: ` or
` #` as its separator, and a string value. Use hyphens instead of whitespace
in tokens, as in `Reviewed-by`. `BREAKING CHANGE` is the exception. Values
can contain spaces and newlines. A value ends where the next valid token
and separator pair begins. Both `Refs: #42` and `Refs #42` are valid.

Under Semantic Versioning, a non-breaking `fix` maps to PATCH, a
non-breaking `feat` to MINOR, and a breaking change of any type to MAJOR.
Other types have no implicit version effect. Use the same discipline during
initial development. Writing a message does not authorize a release.

## Support what you say

When referring to a commit, include its short ID and exact one-line summary:
`Commit <id> ("<summary>")`. Use a GitHub-style seven-character ID, extended
only if needed for uniqueness. Verify both from history:

```sh
git show -s --abbrev=7 --format='%h ("%s")' <commit>
```

Git extends the abbreviation if necessary. Do not guess the ID or rewrite
the original summary. If a known commit introduced the bug, identify it
with `Fixes: <id> ("<summary>")`. A commit that merely touched the same code
is not evidence that it caused the bug.

For example, a regression message connects the failure to its cause and
explains the correction. The hash and scenario here are illustrative:

```text
fix(parser): reject empty input before reading the header

Empty files cause an out-of-bounds read instead of a parse error.
Restore the empty-input check before accessing the header.

Fixes: a1b2c3d ("refactor(parser): centralize header reads")
```

Use `Refs` for related issues and `Closes` only for issues the change
resolves. Include the issue URL when known, and summarize the relevant
discussion in the message. Issue-closing behavior depends on the host.

For a revert, explain why and identify each reverted commit with its ID
and summary. Use `revert` unless the repository has another convention.
Conventional Commits leaves revert semantics to tooling. For a backport,
identify the original commit and explain any adaptation.

Support performance, memory, and size claims with measured before/after
values, the workload, and relevant conditions. State costs as well as gains.
Without measurements, describe the mechanism without claiming a proven gain.
Mention useful validation, but claim only checks that actually ran.

Add credit only when supported by the contribution record. `Reported-by`
credits a report, `Suggested-by` an idea, `Tested-by` successful testing,
`Reviewed-by` an accepted technical review, and `Acked-by` explicit approval.
Use the project's identity format. Obtain permission for private attribution
and `Suggested-by` credit. Do not infer endorsement from silence.

## Check and deliver

Read the message against the intended diff. Check the syntax, breaking-change
markers, references, and claims. Ask whether a future reader can understand
the reason without the current discussion. Remove anything that adds no
useful information.

For a message-only request, return the message in a code block and stop.
When asked to create a commit, show the message and obtain confirmation.
Before committing, recheck the staged diff, run `git diff --cached --check`,
and run relevant repository checks not already run for these changes.
Pass the approved message literally, preserving blank lines and quoting
safely.

If a hook fails, correct the cause within scope and retry a normal commit.
Do not bypass hooks or amend an earlier commit to handle a failed attempt.
After success, inspect `git status` and report the commit ID and summary.
Do not push, amend, rewrite history, or change Git configuration unless
explicitly requested.

## Sources

- [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/)
- [Linux 4.19: Submitting patches](https://www.kernel.org/doc/html/v4.19/process/submitting-patches.html),
  adapted for commit descriptions, logical changes, evidence, and references.
