# Mesh and Variables in MESA

The local MESA evidence lives in `star_data/public/star_data_step_input.inc` and `star_data/public/star_data_step_work.inc`.

## file-backed parity

`star_data_step_input.inc` declares the structure-variable indices, including `i_lnd`, `i_lnT`, `i_lnR`, and `i_lum`. It also states that `i_lum` is the luminosity at the outer face of a cell.

`star_data_step_work.inc` shows the corresponding packed working variables, including `m`, `T`, `rho`, `lnT`, `lnd`, `L`, `r`, and `lnR`. That is the source-backed ownership map ASTRA is comparing against.

## partial parity

ASTRA's face-centered radius and luminosity with cell-centered temperature and density is partial parity with the MESA layout. The same broad staggering exists, but ASTRA's packed state is much smaller and does not include MESA's extra structure, composition, and transport variables.

## analogy only

Any claim that ASTRA fully reproduces MESA's state vector would be analogy only. MESA's work arrays include many additional quantities not present in ASTRA's bootstrap lane.

## not yet proven

We have not yet demonstrated full ownership equivalence between ASTRA and MESA for every variable, nor have we shown that ASTRA's packed state supports the same solver features that the MESA step machinery does.
