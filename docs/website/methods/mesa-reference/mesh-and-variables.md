# Mesh and Variables in MESA

The local MESA evidence for variable ownership and solve basis lives primarily in:

- `star_data/public/star_data_step_input.inc`
- `star_data/public/star_data_step_work.inc`
- `star_data/public/star_data_def.inc`
- `star/private/auto_diff_support.f90`

## file-backed parity

`star_data_step_input.inc` declares the structure-variable indices, including `i_lnd`, `i_lnT`, `i_lnR`, and `i_lum`. The same file states that `i_lum` is the luminosity at the outer face of a cell, while `i_lnR` is the radius at the outer face of a cell and `i_lnd`/`i_lnT` are cell-averaged logarithmic density and temperature variables.

`star_data_step_work.inc` shows the corresponding working arrays, including `T`, `lnT`, `rho`, `lnd`, `L`, `r`, and `lnR`, together with EOS-side derivative storage such as `d_eos_dlnd`, `d_eos_dlnT`, `d_epsnuc_dlnd`, and `d_epsnuc_dlnT`. That is the file-backed ownership map ASTRA is comparing against.

`star_data_def.inc` makes the AD derivative layout explicit by defining slots such as `i_lnd_00`, `i_lnT_00`, and `i_lnR_00` for the centered derivative basis and corresponding `m1`/`p1` neighbors.

The AD wrappers in `auto_diff_support.f90` make the derivative basis explicit:

- `wrap_d_00` sets $\partial \rho / \partial \ln \rho = \rho$,
- `wrap_T_00` sets $\partial T / \partial \ln T = T$,
- `wrap_r_00` sets $\partial r / \partial \ln R = r$,
- `wrap_L_00` sets $\partial L / \partial L = 1$.

In the notation of this page, the key identity is `\partial \rho / \partial \ln \rho`. That is the source-backed pattern ASTRA is following in spirit when it applies chain-rule factors for packed log variables.

The most useful takeaway for ASTRA contributors is not "MESA also uses logs." It is that MESA's solver machinery is explicit about which derivatives belong to logarithmic variables and which remain linear. That is exactly the distinction ASTRA needs to keep visible as its Jacobian coverage expands.

## partial parity

ASTRA's face-centered radius and luminosity with cell-centered temperature and density is partial parity with the MESA layout. The same broad staggering exists, but ASTRA's packed state is much smaller and does not include MESA's extra structure, composition, and transport variables.

## analogy only

Any claim that ASTRA fully reproduces MESA's state vector would be analogy only. MESA's work arrays include many additional quantities not present in ASTRA's bootstrap lane.

## not yet proven

We have not yet demonstrated full ownership equivalence between ASTRA and MESA for every variable, nor have we shown that ASTRA's packed state supports the same solver features that the MESA step machinery does.

## MESA parity checklist

- [x] Variable-location claims are tied to `star_data_step_input.inc` and `star_data_step_work.inc`.
- [x] Derivative-basis claims are tied to `star_data_def.inc` and `auto_diff_support.f90`.
- [ ] ASTRA still needs a row-by-row comparison showing exactly where its packed basis diverges from MESA's broader solve state.
