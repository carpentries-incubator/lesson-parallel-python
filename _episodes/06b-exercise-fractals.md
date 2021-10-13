---
title: "Exercise: Mandelbrot fractals"
teaching: 15
exercises: 75
questions:
- "How do I decide which technique to use where?"
- "How do I put everything together?"
- "Can you show some real life examples?"
objectives:
- "Create a strategy for parallelising existing code."
- "Apply previously discussed methods to problems."
- "Choose the correct abstraction for a problem."
keypoints:
- "You sometimes have to try different strategies to find out what works best."
---

<script type="text/javascript" async
  src="https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.5/MathJax.js?config=TeX-MML-AM_CHTML">
</script>

# The Mandelbrot and Julia fractals

This exercise uses Numpy and Matplotlib.

```python
from matplotlib import pyplot as plt
import numpy as np
```

We will be computing the famous [Mandelbrot
fractal](https://en.wikipedia.org/wiki/Mandelbrot_fractal). The Mandelbrot set is the set of complex
numbers $$c \in \mathbb{C}$$ for which the iteration,

$$z_{n+1} = z_n^2 + c,$$

converges, starting iteration at $$z_0 = 0$$. We can visualize the Mandelbrot set by plotting the
number of iterations needed for the absolute value $$|z_n|$$ to exceed 2 (for which it can be shown
that the iteration always diverges).

![The whole Mandelbrot set](../fig/mandelbrot-all.png)

We may compute the Mandelbrot as follows:

```python
max_iter = 256
width = 256
height = 256
center = -0.8+0.0j
extent = 3.0+3.0j
scale = max((extent / width).real, (extent / height).imag)

result = np.zeros((height, width), int)
for j in range(height):
    for i in range(width):
        c = center + (i - width // 2 + (j - height // 2)*1j) * scale
        z = 0
        for k in range(max_iter):
            z = z**2 + c
            if (z * z.conjugate()).real > 4.0:
                break
        result[j, i] = k
```

Then we can plot with the following code:

```python
fig, ax = plt.subplots(1, 1, figsize=(10, 10))
plot_extent = (width + 1j * height) * scale
z1 = center - plot_extent / 2
z2 = z1 + plot_extent
ax.imshow(result**(1/3), origin='lower', extent=(z1.real, z2.real, z1.imag, z2.imag))
ax.set_xlabel("$\Re(c)$")
ax.set_ylabel("$\Im(c)$")
```

Things become really loads of fun when we start to zoom in. We can play around with the `center` and
`extent` values (and necessarily `max_iter`) to control our window.

```python
max_iter = 1024
center = -1.1195+0.2718j
extent = 0.005+0.005j
```

When we zoom in on the Mandelbrot fractal, we get smaller copies of the larger set!

![Zoom in on Mandelbrot set](../fig/mandelbrot-1.png)

## Julia sets
For each value $$c$$ we can compute the Julia set, namely the set of starting values $$z_1$$ for
which the iteration over $$z_{n+1}=z_n^2 + c$$ converges. Every location on the Mandelbrot image
corresponds to its own unique Julia set.

```python
max_iter = 256
center = 0.0+0.0j
extent = 4.0+3.0j
scale = max((extent / width).real, (extent / height).imag)

result = np.zeros((height, width), int)
c = -1.1193+0.2718j

for j in range(height):
    for i in range(width):
        z = center + (i - width // 2 + (j - height // 2)*1j) * scale
        for k in range(max_iter):
            z = z**2 + c
            if (z * z.conjugate()).real > 4.0:
                break
        result[j, i] = k
```

If we take the center of the last image, we get the following rendering of the Julia set:

![Example of a Julia set](../fig/julia-1.png)

> ## Exercise
> This is not even the worst code. Variables are aptly named and the code is nicely parametrized.
> However, this code utterly lacks in modularity. Think about how to modularize the code.
>
> Make this into a parallel program. What kind of speed-ups do you get? Can you get it efficient
> enough to get an interactive fractal zoomer?
{: .challenge}
