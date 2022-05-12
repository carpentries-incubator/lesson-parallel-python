---
title: "Threading and Multiprocessing"
teaching: 60
exercises: 30
questions:
- "What is the Global Interpreter Lock (GIL)?"
- "How do I use multiple threads in Python?"
objectives:
- "Understand the GIL."
- "Understand the difference between the python `threading` and `multiprocessing` library"
keypoints:
- "If we want the most efficient parallelism on a single machine, we need to circumvent the GIL."
- "If your code releases the GIL, threading will be more efficient than multiprocessing."
---

FIXME: expand text

Another possibility for parallelization is to use the `threading` module.
This module is built into Python. In this section, we'll use it to estimate pi
once again.

Using threading to speed up your code:

```python
from threading import (Thread)
```

```python
%%time
n = 10**7
t1 = Thread(target=calc_pi, args=(n,))
t2 = Thread(target=calc_pi, args=(n,))

t1.start()
t2.start()

t1.join()
t2.join()
```

> ## Discussion: where's the speed-up?
> While mileage may vary, parallelizing `calc_pi`, `calc_pi_numpy` and `calc_pi_numba` this way will
> not give the expected speed-up. `calc_pi_numba` should give *some* speed-up, but nowhere near the
> ideal scaling over the number of cores. This is because Python only allows one thread to access the
> interperter at any given time, a feature also known as the Global Interpreter Lock.
{: .discussion}

## A few words about the Global Interpreter Lock
The Global Interpreter Lock (GIL) is an infamous feature of the Python interpreter.
It both guarantees inner thread sanity, making programming in Python safer, and prevents us from using multiple cores from
a single Python instance.
When we want to perform parallel computations, this becomes an obvious problem.
There are roughly two classes of solutions to circumvent/lift the GIL:

- Run multiple Python instances: `multiprocessing`
- Have important code outside Python: OS operations, C++ extensions, cython, numba

The downside of running multiple Python instances is that we need to share program state between different processes.
To this end, you need to serialize objects. Serialization entails converting a Python object into a stream of bytes,
that can then be sent to the other process, or e.g. stored to disk. This is typically done using `pickle`, `json`, or
similar, and creates a large overhead.
The alternative is to bring parts of our code outside Python.
Numpy has many routines that are largely situated outside of the GIL.
The only way to know for sure is trying out and profiling your application.

To write your own routines that do not live under the GIL there are several options: fortunately `numba` makes this very easy.

We can force the GIL off in Numba code by setting `nogil=True` in the `numba.jit` decorator.

```python
@numba.jit(nopython=True, nogil=True)
def calc_pi_nogil(N):
    M = 0
    for i in range(N):
        x = random.uniform(-1, 1)
        y = random.uniform(-1, 1)
        if x**2 + y**2 < 1:
            M += 1
    return 4 * M / N
```

The `nopython` argument forces Numba to compile the code without referencing any Python objects,
while the `nogil` argument enables lifting the GIL during the execution of the function.

> ## Use `nopython=True` or `@numba.njit`
> It's generally a good idea to use `nopython=True` with `@numba.jit` to make sure the entire
> function is running without referencing Python objects, because that will dramatically slow
> down most Numba code.  There's even a decorator that has `nopython=True` by default: `@numba.njit`
{: .callout}

Now we can run the benchmark again, using `calc_pi_nogil` instead of `calc_pi`.

> ## Exercise: try threading on a Numpy function
> Many Numpy functions unlock the GIL. Try to sort two randomly generated arrays using `numpy.sort` in parallel.
>
> > ## Solution
> > ```python
> > rnd1 = np.random.random(high)
> > rnd2 = np.random.random(high)
> > %timeit -n 10 -r 10 np.sort(rnd1)
> > ```
> >
> > ```python
> > %%timeit -n 10 -r 10
> > t1 = Thread(target=np.sort, args=(rnd1, ))
> > t2 = Thread(target=np.sort, args=(rnd2, ))
> >
> > t1.start()
> > t2.start()
> >
> > t1.join()
> > t2.join()
> > ```
> {: .solution}
{: .challenge}
