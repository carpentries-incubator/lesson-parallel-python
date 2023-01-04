---
title: 'Computing $\pi$'
teaching: 60
exercises: 30
---

:::questions
- How do I parallelize a Python application?
- What is data parallelism?
- What is task parallelism?
:::

:::objectives
- Rewrite a program in a vectorized form.
- Understand the difference between data and task-based parallel programming.
- Apply `numba.jit` to accelerate Python.
:::

# Parallelizing a Python application
In order to recognize the advantages of parallelization we need an algorithm that is easy to parallelize, but still complex enough to take a few seconds of CPU time.
To not scare away the interested reader, we need this algorithm to be understandable and, if possible, also interesting.
We chose a classical algorithm for demonstrating parallel programming: estimating the value of number π.

The algorithm we present is one of the classical examples of the power of Monte-Carlo methods.
This is an umbrella term for several algorithms that use random numbers to approximate exact results.
We chose this algorithm because of its simplicity and straightforward geometrical interpretation.

We can compute the value of π using a random number generator. We count the points falling inside the blue circle M compared to the green square N.
Then π is approximated by the ratio 4M/N.

![Computing Pi](fig/calc_pi_3_wide.svg){alt="the area of a unit sphere contains a multiple of pi"}

:::challenge
## Challenge: Implement the algorithm
Use only standard Python and the function `random.uniform`. The function should have the following
interface:

```python
import random
def calc_pi(N):
    """Computes the value of pi using N random samples."""
    ...
    for i in range(N):
        # take a sample
        ...
    return ...
```

Also make sure to time your function!

::::solution
## Solution

```python
import random

def calc_pi(N):
    M = 0
    for i in range(N):
        # Simulate impact coordinates
        x = random.uniform(-1, 1)
        y = random.uniform(-1, 1)

        # True if impact happens inside the circle
        if x**2 + y**2 < 1.0:
            M += 1
    return 4 * M / N

%timeit calc_pi(10**6)
```

```output
676 ms ± 6.39 ms per loop (mean ± std. dev. of 7 runs, 1 loop each)
```
::::
:::

Before we start to parallelize this program, we need to do our best to make the inner function as
efficient as we can. We show two techniques for doing this: *vectorization* using `numpy` and
*native code generation* using `numba`.

We first demonstrate a Numpy version of this algorithm.

```python
import numpy as np

def calc_pi_numpy(N):
    # Simulate impact coordinates
    pts = np.random.uniform(-1, 1, (2, N))
    # Count number of impacts inside the circle
    M = np.count_nonzero((pts**2).sum(axis=0) < 1)
    return 4 * M / N
```

This is a **vectorized** version of the original algorithm. It nicely demonstrates **data parallelization**,
where a **single operation** is replicated over collections of data.
It contrasts to **task parallelization**, where **different independent** procedures are performed in
parallel (think for example about cutting the vegetables while simmering the split peas).

If we compare with the 'naive' implementation above, we see that our new one is much faster:

```python
%timeit calc_pi_numpy(10**6)
```

```output
25.2 ms ± 1.54 ms per loop (mean ± std. dev. of 7 runs, 10 loops each)
```

:::discussion
## Discussion: is this all better?
What is the downside of the vectorized implementation?
- It uses more memory
- It is less intuitive
- It is a more monolithic approach, i.e. you cannot break it up in several parts
:::

:::challenge
## Challenge: Daskify
Write `calc_pi_dask` to make the Numpy version parallel. Compare speed and memory performance with
the Numpy version. NB: Remember that dask.array mimics the numpy API.

::::solution
## Solution

```python
import dask.array as da

def calc_pi_dask(N):
    # Simulate impact coordinates
    pts = da.random.uniform(-1, 1, (2, N))
    # Count number of impacts inside the circle
    M = da.count_nonzero((pts**2).sum(axis=0) < 1)
    return 4 * M / N

%timeit calc_pi_dask(10**6).compute()
```

```output
4.68 ms ± 135 µs per loop (mean ± std. dev. of 7 runs, 100 loops each)
```
::::
:::

# Using Numba to accelerate Python code
Numba makes it easier to create accelerated functions. You can use it with the decorator `numba.jit`.

```python
import numba

@numba.jit
def sum_range_numba(a):
    """Compute the sum of the numbers in the range [0, a)."""
    x = 0
    for i in range(a):
        x += i
    return x
```

Let's time three versions of the same test. First, native Python iterators:

```python
%timeit sum(range(10**7))
```

```output
190 ms ± 3.26 ms per loop (mean ± std. dev. of 7 runs, 10 loops each)
```

Now with Numpy:

```python
%timeit np.arange(10**7).sum()
```

```output
17.5 ms ± 138 µs per loop (mean ± std. dev. of 7 runs, 100 loops each)
```

And with Numba:

```python
%timeit sum_range_numba(10**7)
```

```output
162 ns ± 0.885 ns per loop (mean ± std. dev. of 7 runs, 10000000 loops each)
```

Numba is 100x faster in this case!  It gets this speedup with "just-in-time" compilation (JIT)—compiling the Python
function into machine code just before it is called (that's what the `@numba.jit` decorator stands for).
Not every Python and Numpy feature is supported, but a function may be a good candidate for Numba if it is written
with a Python for-loop over a large range of values, as with `sum_range_numba()`.

:::callout
## Just-in-time compilation speedup

The first time you call a function decorated with `@numba.jit`, you may see little or no speedup. In
subsequent calls, the function could be much faster. You may also see this warning when using `timeit`:

`The slowest run took 14.83 times longer than the fastest. This could mean that an intermediate result is being cached.`

Why does this happen?
On the first call, the JIT compiler needs to compile the function. On subsequent calls, it reuses the
already-compiled function. The compiled function can *only* be reused if it is called with the same argument types
(int, float, etc.).

See this example where `sum_range_numba` is timed again, but now with a float argument instead of int:
```python
%time sum_range_numba(10.**7)
%time sum_range_numba(10.**7)
```
```output
CPU times: user 58.3 ms, sys: 3.27 ms, total: 61.6 ms
Wall time: 60.9 ms
CPU times: user 5 µs, sys: 0 ns, total: 5 µs
Wall time: 7.87 µs
```
:::

:::challenge
## Challenge: Numbify `calc_pi`
Create a Numba version of `calc_pi`. Time it.

::::solution
## Solution
Add the `@numba.jit` decorator to the first 'naive' implementation.
```python
@numba.jit
def calc_pi_numba(N):
    M = 0
    for i in range(N):
        # Simulate impact coordinates
        x = random.uniform(-1, 1)
        y = random.uniform(-1, 1)

        # True if impact happens inside the circle
        if x**2 + y**2 < 1.0:
            M += 1
    return 4 * M / N

%timeit calc_pi_numba(10**6)
```
```output
13.5 ms ± 634 µs per loop (mean ± std. dev. of 7 runs, 1 loop each)
```
::::
:::

:::callout
## Measuring == knowing
Always profile your code to see which parallelization method works best.
:::

:::callout
## `numba.jit` is not a magical command to solve are your problems
Using numba to accelerate your code often outperforms other methods, but it is not always trivial to rewrite your code so that you can use numba with it.
:::

:::keypoints
- Always profile your code to see which parallelization method works best
- Vectorized algorithms are both a blessing and a curse.
- Numba can help you speed up code
:::
