---
title: "Introduction to Parallel Programming in Python"
teaching: 0
exercises: 0
questions:
- "How can I improve (speed up) my Python program with parallel programming"
objectives:
- "Explain the normal process of a (Python) program"
- "Explain where concurrent (parallel) processing comes into play"
- "Learn to identify program parts that can be parallized"
- "Demonstrate a brief example of a speed up using paralell programming in Python"
keypoints:
- "Parallel programming can speed up programs"
- "But not always! Repeated operations (loops) are most suitable for speed up"
- "Profile your program to identify the slow and fast parts"
- "Use the `timeit` module to time parts of your program"
- "command line: `python -m timeit your-script.py`"
- "notebook: `%timeit <line of code>` to time a single line"
- "notebook: `%%time <cell with code>` to time a cell"
---
FIXME

{% include links.md %}

