# Documentation Style

ASTRA documentation should read like a research notebook written by a careful engineer:

- explicit scope,
- explicit assumptions,
- variable meaning and units,
- honest statements about what is stubbed,
- links between architecture and science.

Avoid empty aspirational prose. If a page describes future work, it should say so directly.

## Naming convention for ASTRA

Use plain ASTRA when you mean the project, framework, website, or research architecture in prose.

Use `ASTRA` when you mean the Julia package, module namespace, import surface, or an API path such as `using ASTRA` or `ASTRA.pack_state(...)`.

In other words:

- "ASTRA is a Julia-native framework" is prose about the project,
- "import `ASTRA` and call `ASTRA.build_toy_problem(...)`" is prose about the code surface.
