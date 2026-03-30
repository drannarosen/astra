# Jacobian Checks

Finite-difference Jacobian checks are mandatory early validation tools in ASTRA because they force the code to answer a very concrete question: if the state vector changes by a small amount, does the residual respond in the way the solver assumes?

At bootstrap, the Jacobian is itself finite-difference. Later, finite-difference spot checks should become the validation layer for any more sophisticated Jacobian path.

This is a particularly important page for new solver contributors because Jacobian validation is easy to overstate. A Jacobian check does not prove the physics is right. It proves something narrower and still essential: the derivative object used by the solver is consistent with the residual definition being differentiated.

For ASTRA, that derivative object must be interpreted in packed-variable basis. A physically sensible derivative in raw $(r, T, \rho, L)$ variables is not enough if the Newton system is actually expressed in $(\log r, \log T, \log \rho, L)$.

The practical validation ladder is therefore:

1. local closure derivatives match finite differences,
2. row-family Jacobian blocks match row-local finite differences,
3. the full solve takes better Newton steps because of those derivatives,
4. only then do we claim a Jacobian improvement helped the solver.

## Validation checklist

- [x] The page states what finite-difference Jacobian checks actually prove.
- [x] The page distinguishes Jacobian validation from full physical validation.
- [ ] The page should link directly to quantitative audit artifacts once ASTRA stores them as durable validation outputs.
