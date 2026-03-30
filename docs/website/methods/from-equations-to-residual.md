# From Equations to Residual

This page shows how ASTRA turns the continuous classical equations into a residual vector. The important bridge is between the `Physics` pages and the solver-side `Methods` pages, especially [Physics: Stellar Structure](../physics/stellar-structure.md).

The physics side of that bridge lives in [Stellar Structure](../physics/stellar-structure.md) and the closure hub pages under [Physics](../physics/index.md).

For many contributors, this is the page where stellar structure stops feeling like four textbook equations and starts feeling like a nonlinear solve. The key idea is simple: ASTRA does not solve for "the right profile" directly. It solves for a packed state vector whose residual should become zero when the discrete equations and boundary conditions are all satisfied at once.

## Unknown vector

ASTRA packs the structure state as

$$
x = \left(\log r_{i+1/2},\; L_{i+1/2},\; \log T_i,\; \log \rho_i \right)
$$

or, in the literal packed storage order,

```text
[ log(radius_face_cm),
  luminosity_face_erg_s,
  log(temperature_cell_k),
  log(density_cell_g_cm3) ]
```

That is the unknown vector the Newton solve updates. The `log(radius` and `log(temperature` choices are there for positivity and conditioning; luminosity stays linear in raw `erg/s` because it crosses zero at the center and is still a physical flux variable.

The code-level owner of that contract is `ASTRA.pack_state(...)` in `src/state.jl`. The methods contract is stricter than a prose summary: if the packed order changes, the residual assembly, Jacobian assembly, and every docs page that reasons about state ownership must change in the same slice.

## Normative packed-state contract

For the current classical lane, the packed structure vector is specified as:

1. all face-centered $\log r$ values,
2. all face-centered $L$ values in $\mathrm{erg\,s^{-1}}$,
3. all cell-centered $\log T$ values,
4. all cell-centered $\log \rho$ values.

That order, basis, and unit convention are part of the numerics contract. Any future refactor that changes them must update the methods docs and the Jacobian logic together.

The packed-variable basis is also the Jacobian basis. The canonical example is $\frac{\partial f}{\partial \log T}$ rather than only $\frac{\partial f}{\partial T}$. When ASTRA differentiates a local closure that is naturally written in physical variables, the numerics layer should apply the chain rule with respect to the packed unknowns:

$$
\frac{\partial f}{\partial \log T} = T \frac{\partial f}{\partial T},
\qquad
\frac{\partial f}{\partial \log \rho} = \rho \frac{\partial f}{\partial \rho},
\qquad
\frac{\partial f}{\partial \log r} = r \frac{\partial f}{\partial r}.
$$

That is the numerically relevant derivative contract because Newton updates the packed state, not an auxiliary vector of raw thermodynamic variables.

This is also why ASTRA can be physically conservative and numerically modern at the same time. The continuous theory still speaks in $r$, $T$, and $\rho$. The solver speaks in $\log r$, $\log T$, and $\log \rho$ wherever that improves conditioning and positivity handling. The two are connected by the chain rule, not by pretending the textbook equations were already written in solver basis.

## Residual vector

The residual vector follows the same physical order:

- center boundary rows,
- interior structure blocks,
- surface boundary rows.

Each interior block contributes the geometry, hydrostatic, luminosity, and transport rows. That ordering is not arbitrary; it matches the ownership of the solve variables and the way the Jacobian is built.

For the current classical lane, the residual length is $4 n_\mathrm{cells} + 2$: two center rows, four interior rows for each of the $n_\mathrm{cells} - 1$ interior blocks, and four surface rows.

## Why this matters

Once the equations are written as a residual vector, ASTRA can ask Newton's method for a coupled correction instead of integrating shell by shell. That is the difference between a true boundary-value solve and a reference-profile comparison.

This strategy is also consistent in spirit with MESA's solve-variable basis: the local MESA mirror uses `i_lnd`, `i_lnT`, `i_lnR`, and linear `i_lum` as primary structure variables, and its AD wrapping exposes derivatives with respect to those same log variables.

## Implementation checklist

- [x] The unknown vector is written in both mathematical and literal packed-storage form.
- [x] The page states that luminosity stays linear while radius, temperature, and density are solved logarithmically.
- [x] The chain-rule conversion from physical derivatives to packed-variable derivatives is explicit.
- [ ] The packed-state contract is linked to a docs test that will fail if the documented ordering drifts.

## MESA parity checklist

- [x] The page states the MESA comparison only as a solve-basis similarity, not as full parity.
- [ ] The similarity claim is expanded with precise file references from the local MESA mirror in the dedicated MESA-reference subtree.

## Open-risk checklist

- [ ] The page should link to a future packed-Jacobian basis audit showing every row family in this basis, not only the currently analytic ones.
