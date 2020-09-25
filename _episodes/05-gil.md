---
title: "The global interpreter lock"
teaching: 30
exercises: 10
questions:
- "What is the GIL?"
- "When do I use multiprocessing, when threading?"
objectives:
- "Understand limitations of the GIL."
- "Understand the difference between multi-processing and threading."
keypoints:
- "The GIL is a design choice: it makes Python programs easier to reason about."
- "You can get around the GIL by using multi-processing."
- "Many numpy routines are not 100% affected by the GIL."
---

- Example with `scipy.integrate` (heavy on the GIL)

- Misconception: you may find people saying that you shouldn't use `threading` based concurrency to
  run CPU bound things. This is not true. If your operation is CPU bound, the core routines should
not be implemented in Python in the first place.

