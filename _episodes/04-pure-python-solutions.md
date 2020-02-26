---
title: "Solutions using the default Python library"
teaching: 0
exercises: 0
questions:
- "What possibilities does the standard Python library give for speeding up my program with multi-processing?"
objectives:
- "Use threads"
- "Use multiprocessing"
keypoints:
- "Threads are a good solution if there is a lot of non-processing per process, and if you want to pass data between threads during processing."
- "Multiprocessing creates completely independent (Python) processes. There can be quite a bit of overhead at the start and end."
- "Multiprocessing requires n times the amount of memory (n the number of simultaneous processes): avoid it for large amounts of data."
---
FIXME

{% include links.md %}

