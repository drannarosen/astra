# Jacobian Checks

Finite-difference Jacobian checks are mandatory early validation tools in ASTRA because they force the code to answer a very concrete question: if the state vector changes by a small amount, does the residual respond in the way the solver assumes?

At bootstrap, the Jacobian is itself finite-difference. Later, finite-difference spot checks should become the validation layer for any more sophisticated Jacobian path.
