# Lessons Learned

This page records durable lessons that should outlive any one dated note.

Use it for takeaways that would still matter if the original artifact bundle, audit, or cutover were no longer the active topic of the week.

## What belongs here

- repeated numerical failure modes,
- ownership mistakes that were expensive to detect,
- verification habits that caught a real scientific or architectural problem,
- and workflow adjustments that made later slices sharper or safer.

## What does not belong here

- raw experiment logs,
- a second copy of `Progress Summary`,
- or dated notes whose only value is historical chronology.

## Current lessons

### Keep physical ownership and convergence diagnosis separate

Fixing a wrong physical owner is necessary when the solver is enforcing the wrong branch of the equations, but that does not by itself prove convergence or remove all remaining boundary difficulties.

The Bohm-Vitense MLT hard cutover is the current example: ASTRA now puts convective cells on a convective transport branch, which was physically required, but the accepted validation bundle still identifies a broader outer-boundary and surface-family burden.
