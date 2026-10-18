---
name: create-commit-messages
description: Draft and create a conventional commit for staged changes.
---

Write and create a git commit for the current changes following Conventional Commits.

**Steps**

1. Run `git status` and `git diff HEAD` to understand what changed and use our last message as context.
2. Draft the commit message following the format below.
3. Show the message to the user and ask for confirmation before running `git commit`.
5. On confirmation, run `git commit -m "<message>"`.

---

## Format

```
<type>[!](<subsystem>): <short summary>

<body>
```

Append `!` after the type (or subsystem) to signal a breaking change: `feat!:`, `refactor(api)!:`.

### type (required)

Pick the one that best describes the primary intent:

| type | when to use |
|------|-------------|
| `feat` | a new capability or user-visible behavior |
| `fix` | a bug correction |
| `refactor` | restructuring with no behavior change |
| `test` | adding or changing tests only |
| `docs` | documentation only |
| `chore` | tooling, deps, config, CI — no production code |
| `perf` | performance improvement |
| `style` | formatting, whitespace — no logic change |

### subsystem (optional but preferred)

The capability or module affected, in kebab-case. Use the folder name or domain term — e.g. `ci`, `build`, `library`. Omit only when the change is truly cross-cutting.

### short summary (required)

- Imperative mood: "add", "remove", "fix", "introduce", not "added" or "fixes"
- Lowercase after the colon
- No period at the end
- Max 72 characters for the whole first line

### body (include when the diff alone doesn't explain the why)

- Wrap at 72 characters
- Explain the motivation and context, not what the diff already shows
- Use plain prose or short bullet points
- Separate from the summary with a blank line
- Never use em-dashes (—); use a comma, colon, or rephrase instead
- Default to the shortest version that's still true. A one-paragraph body is normal, not a sign of insufficient effort.

### Long form description

- Describe **what changed**, **what the previous behavior was**,
  and **how the new behavior works** at a high level.
- Use plain prose, not bullet points. Wrap lines at ~72 characters.
- Focus on the _why_ and _how_ rather than restating the diff.
- Keep the tone direct and technical without filler phrases.
- Don't exceed a handful of paragraphs; less is more.

### Workflow

- Run a diff to see what changes are present since the last commit.
- Identify the subsystem from the changed file paths.
- Draft the commit message following the format above.
- Apply the commit
- Don't push the commit; leave that to the user.
