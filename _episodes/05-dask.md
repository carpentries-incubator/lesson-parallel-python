---
title: "Introduction"
teaching: 0
exercises: 0
questions:
- "FIXME"
objectives:
- "FIXME"
keypoints:
- "FIXME"
---

# Forms of parallelism
Dask gives us several abstractions over parallel programming:

- Bag: parallel iterators `map`, `filter`, `groupby`
- Array: parallel `numpy`
- DataFrame: parallel `pandas`
- Delayed: generic

The first three all follow, more or less the same model: S.I.M.D., or **Single Instruction Multiple
Data**. The `Delayed` module is a bit more special: it underlies the functioning of the other three
in that it builds a dependency graph of the computation. It allows for M.I.M.D. or **Multiple
Instruction Multiple Data**, running tasks with complex interdependencies. (There is also Dask
Futures, but we won't go into that)

