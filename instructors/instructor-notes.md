---
title: Notes for instructors (and lesson devs)
---

## Testing this lesson
A lot of the code in this lesson can be tested using [Entangled](https://entangled.github.io). You may tangle source files by running

```shell
entangled tangle -a
```

A set of source files will appear in `<project-root>/src`, including a Poetry environment for running the tests and benchmarks. You may also run `entangled daemon` if you want to debug the code, changes made to the files in `src` will then be merged back into the lesson material automatically.

``` {.toml file="src/pyproject.toml"}
[tool.poetry]
name = "parallel-python"
version = "0.1.0"
description = "Testing environment for Parallel Python workshop"
authors = ["Johan Hidding <j.hidding@esciencecenter.nl>"]
license = "Apache-2.0"

[tool.poetry.dependencies]
python = ">=3.9, <3.11"
numba = "^0.56.4"
dask = {extras = ["complete"], version = "^2022.12.1"}
richbench = "^1.0.3"
matplotlib = "^3.6.2"
numba-progress = "^0.0.4"

[tool.poetry.dev-dependencies]

[build-system]
requires = ["poetry-core>=1.0.0"]
build-backend = "poetry.core.masonry.api"
```

