# Development Guide

The `Development` section is ASTRA's operational memory. It sits between long-horizon planning and day-to-day implementation.

Use these pages when you need to answer questions like:

- what changed recently,
- what is currently blocked or risky,
- what should happen next,
- and where to record progress without rewriting a full design note.

## Which page to update

Use [Dev Journal](dev-journal/index.md) when you need the dated memory lane. That subsection now separates the high-level [Progress Summary](dev-journal/progress-summary.md) from topic-specific notes and the reusable [Lessons Learned](dev-journal/lessons-learned.md) page.

Use [Changelog](changelog.md) for a durable record of user-visible or architecture-significant repository changes.

Use [Checklists](checklists.md) for developer-facing lane tracking where approval, implementation, verification, and intentional deferrals should stay visible in one place.

Use [Backlog](backlog.md) for planned work that is accepted as real but not yet implemented.

Use [Issues](issues.md) for active risks, unresolved questions, known limitations, or blockers that deserve visibility.

## Dev Journal workflow

The `Dev Journal` subsection is the place to record what happened in a way that helps future contributors reason from evidence instead of memory.

- Use [Progress Summary](dev-journal/progress-summary.md) for the high-level dated rollup.
- Use topic-specific dated notes in `dev-journal/` when a slice needs artifact-backed interpretation, a scientific caution, or a focused audit story that would clutter the rollup.
- Use [Lessons Learned](dev-journal/lessons-learned.md) only for durable takeaways that should survive beyond the original slice.

When a dated note stops informing active work, either collapse its durable takeaway into `lessons-learned.md` or keep it as explicitly historical evidence. Do not leave stale notes pretending to be live guidance.

## Writing rule

These pages are not a substitute for plans, tests, or design notes. They are the short-form memory layer that helps a contributor orient quickly before diving into the longer technical documents.
