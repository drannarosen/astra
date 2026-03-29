# Linear Solvers

The bootstrap uses Julia's dense backslash solve for the Newton update.

That is a placeholder decision, not a long-term endorsement of dense algebra for realistic stellar solves. The important architectural rule is that the nonlinear layer should delegate the update step to a linear-solver boundary instead of hard-coding one strategy everywhere.
