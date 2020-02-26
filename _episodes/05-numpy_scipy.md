---
title: "Using NumPy and SciPy"
teaching: 0
exercises: 0
questions:
- "How can NumPy and SciPy speed up (and simplify) my program?"
objectives:
- "Use array-wise programming with NumPy/SciPy functions"
- "Replace for-loops with array-wise programming"
- "NumPy and SciPy are implemented outside the Python-GIL; their functions can use multi-processing"
- "Run NumPy/SciPy functions in parallel"
- "Note that sometimes, NumPy is already parallel optimized (compiled with OpenMP)."
keypoints:
- "Use NumPy and SciPy to simplify your loops: their functions are optimised for array-wise processing."
- "NumPy / SciPy functions don't use the GIL, and are easier to run in parallel."
- "Be aware that your own functions passed into SciPy functions (e.g., minimization) can still be slow due to the GIL"
---
FIXME

{% include links.md %}

