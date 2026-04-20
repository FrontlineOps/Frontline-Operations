# Contributing

## GitHub Commit Message Rule

Commit messages pushed to GitHub must be useful to someone reading history later. Use a clear, standalone message that explains what broke, what changed, and why the change is safe.

Use this style for non-trivial commits:

```text
[SYSTEM_OR_MODULE] functionOrArea: concise summary of the fix/change

Previous behavior: explain the bug, broken state, or old behavior clearly.
Include the visible symptom, bad output, or failure mode when relevant.

New behavior: explain exactly what now happens instead.
Call out whether behavior changed intentionally or was preserved.

Implementation notes: describe important gotchas, control-flow hazards,
diagnostics, logging, performance implications, or compatibility details.

Author: Name
```

## Requirements

- Start with a bracketed system prefix such as `[GTN]`, `[Factions]`, or `[Virtualization]`.
- Explain previous behavior and new behavior in plain language.
- State whether the change preserves behavior or intentionally changes behavior.
- Include relevant task type, config key, log prefix, or file/module name so the cause can be traced later.
- Include testing, RPT evidence, or validation notes when relevant.
- End with an `Author:` line for attribution when preparing GitHub commits.

## Avoid

- Vague one-line commit messages for behavior, performance, mission setup, faction, or systems changes.
- Generic summaries like `fix bug`, `update`, or `cleanup`.
- Performance claims without performance evidence.
- Unconditional diagnostics or logging without explaining why mission makers need to see it.

Rule of thumb: if a mission maker or future developer cannot understand the commit without opening the diff, the commit message is not detailed enough.
