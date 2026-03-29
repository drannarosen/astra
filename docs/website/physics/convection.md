# Convection

Convection enters ASTRA at bootstrap only as a **criterion hook**, not as a full transport theory.

The current toy hook compares a radiative gradient estimate to the EOS adiabatic gradient and classifies the regime as radiative or convective. That is enough to establish where a future convection model belongs architecturally.

Detailed MLT, overshoot, semiconvection, and thermohaline transport are explicitly deferred.
