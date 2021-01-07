---
title: "Understanding parallelization in Python"
teaching: 60
exercises: 30
questions:
- "What is the Global Interpreter Lock (GIL)?"
- "How do I parallelize a Python application?"
- "What is data parallelism?"
- "What is task parallelism?"
- "How do I use multiple threads in Python?"
objectives:
- "Rewrite a program in a vectorized form."
- "Understand the difference between data and task-based parallel programming."
- "Understand the GIL."
- "Apply `numba.jit` to accelerate Python."
- "Recognize the primitive components of the queue/worker model of execution."
keypoints:
- "Always profile your code to see which parellelization method works best"
- "Vectorized algorithms are both a blessing and a curse."
- "If we want the most efficient parallelism on a single machine, we need to circumvent the GIL."
- "Numba helps you both speeding up code and circumventing the GIL."
---

# Parallelizing a Python application
In order to recognize the advantages of parallelization we need an algorithm that is easy to parallelize, but still complex enough to take a few seconds of CPU time.
To not scare away the interested reader, we need this algorithm to be understandable and, if possible, also interesting.
We chose a classical algorithm for demonstrating parallel programming: estimating the value of number π.

The algorithm we present is one of the classical examples of the power of Monte-Carlo methods.
This is an umbrella term for several algorithms that use random numbers to approximate exact results.
We chose this algorithm because of its simplicity and straightforward geometrical interpretation.

We can compute the value of π using a random number generator. We count the points falling inside the blue circle M compared to the green square N.
Then π is approximated by the ratio 4M/N.

![Computing Pi](../fig/calc_pi_3_wide.svg)

> ## Challenge: Implement the algorithm
> Use only standard Python and the function `random.uniform`. The function should have the following
> interface:
> ~~~python
> import random
> def calc_pi(N):
>     """Computes the value of pi using N random samples."""
>     ...
>     for i in range(N):
>         # take a sample
>         ...
>     return ...
> ~~~
>
> Also make sure to time your function!
>
> {: .source}
>
> > ## Solution
> > ~~~python
> > import random
> >
> > def calc_pi(N):
> >     M = 0
> >     for i in range(N):
> >         # Simulate impact coordinates
> >         x = random.uniform(-1, 1)
> >         y = random.uniform(-1, 1)
> >
> >         # True if impact happens inside the circle
> >         if x**2 + y**2 < 1.0:
> >             M += 1
> >     return 4 * M / N
> >
> > %timeit calc_pi(10**6)
> > ~~~
> > {: .source}
> >
> > ~~~
> > 676 ms ± 6.39 ms per loop (mean ± std. dev. of 7 runs, 1 loop each)
> > ~~~
> >{: .output}
> >
> {: .solution}
{: .challenge}

Before we start to parallelize this program, we need to do our best to make the inner function as
efficient as we can. We show two techniques for doing this: *vectorization* using `numpy` and
*native code generation* using `numba`.

We first demonstrate a Numpy version of this algorithm.

~~~python
import numpy as np

def calc_pi_numpy(N):
    # Simulate impact coordinates
    pts = np.random.uniform(-1, 1, (2, N))
    # Count number of impacts inside the circle
    M = np.count_nonzero((pts**2).sum(axis=0) < 1)
    return 4 * M / N
~~~
{: .source}

This is a **vectorized** version of the original algorithm. It nicely demonstrates **data parallelization**,
where a **single operation** is replicated over collections of data.
It contrasts to **task parallelization**, where **different independent** procedures are performed in
parallel (think for example about cutting the vegetables while simmering the split peas).

If we compare with the 'naive' implementation above, we see that our new one is much faster:

~~~python
%timeit calc_pi_numpy(10**6)
~~~
{: .source}

~~~
25.2 ms ± 1.54 ms per loop (mean ± std. dev. of 7 runs, 10 loops each)
~~~
{: .output}

> ## Discussion: is this all better?
> What is the downside of the vectorized implementation?
> - It uses more memory
> - It is less intuitive
> - It is a more monolithic approach, i.e. you cannot break it up in several parts
{: .discussion}

> ## Challenge: Daskify
> Write `calc_pi_dask` to make the Numpy version parallel. Compare speed and memory performance with
> the Numpy version. NB: Remember that dask.array mimics the numpy API.
>
> > ## Solution
> >
> > ~~~python
> > import dask.array as da
> >
> > def calc_pi_dask(N):
> >     # Simulate impact coordinates
> >     pts = da.random.uniform(-1, 1, (2, N))
> >     # Count number of impacts inside the circle
> >     M = da.count_nonzero((pts**2).sum(axis=0) < 1)
> >     return 4 * M / N
> >
> > %timeit calc_pi_dask(10**6).compute()
> > ~~~
> > {: .source}
> >~~~
> >4.68 ms ± 135 µs per loop (mean ± std. dev. of 7 runs, 100 loops each)
> >~~~
> >{: .output}
> {: .solution}
{: .challenge}


# Using Numba to accelerate Python code
Numba makes it easier to create accelerated functions. You can use it with the decorator `numba.jit`.

~~~python
import numba

@numba.jit
def sum_range_numba(a: int):
    """Compute the sum of the numbers in the range [0, a)."""
    x = 0
    for i in range(a):
        x += i
    return x
~~~
{: .source}

Let's time three versions of the same test. First, native Python iterators:

~~~python
%timeit sum(range(10**7))
~~~
{: .source}

~~~
190 ms ± 3.26 ms per loop (mean ± std. dev. of 7 runs, 10 loops each)
~~~
{: .output}

Now with Numpy:

~~~python
%timeit np.arange(10**7).sum()
~~~
{: .source}

~~~
17.5 ms ± 138 µs per loop (mean ± std. dev. of 7 runs, 100 loops each)
~~~
{: .output}

And with Numba:

~~~python
%timeit sum_range_numba(10**7)
~~~
{: .source}
~~~
162 ns ± 0.885 ns per loop (mean ± std. dev. of 7 runs, 10000000 loops each)
~~~
{: .output}

> ## Challenge: Numbify `comp_pi`
> Create a Numba version of `comp_pi`. Time it.
>
> > ## Solution
> > Add the `@numba.jit` decorator to the first 'naive' implementation.
> > ~~~python
> > @numba.jit
> > def calc_pi_numba(N):
> >     M = 0
> >     for i in range(N):
> >         # Simulate impact coordinates
> >         x = random.uniform(-1, 1)
> >         y = random.uniform(-1, 1)
> >
> >         # True if impact happens inside the circle
> >         if x**2 + y**2 < 1.0:
> >             M += 1
> >     return 4 * M / N
> >
> > %timeit calc_pi_numba(10**6)
> > ~~~
> > ~~~
> > 13.5 ms ± 634 µs per loop (mean ± std. dev. of 7 runs, 1 loop each)
> > ~~~
> > {: .output}
> {: .solution}
{: .challenge}

> ## Measuring == knowing
> Always profile your code to see which parallelization method works best.
{: .callout}

> ## `numba.jit` is not a magical command to solve are your problems
> Using numba to accelerate your code often outperforms other methods, but
>  it is not always trivial to rewrite your code so that you can use numba with it.
{: .callout}


# The `threading` module
Another possibility for parallelization is to use the `threading` module.
This module is built into Python. In this section, we'll use it to estimate pi
once again.

We now build a queue/worker model. This is the basis of multi-threading applications in Python. At
this point creating a parallel program is quite involved. After we've done this, we'll see ways to
do the same in Dask without mucking about with threads directly.

On the one hand we have a `Queue` to which we push work units. On the other hand we have any number
of *workers* that pull jobs from the queue. More workers should get the job done in less time!

~~~python
import queue
import threading

# Input values
input_range = [10**9] * 10
# Number of threads to launch
ncpus = 4

### We need to define a worker function that fetches jobs from the queue.
def worker(q):
    while True:
        try:
            x = q.get(block=False)
            print(calc_pi_numba(x), end=' ', flush=True)
        except queue.Empty:
            break

### Create the queue, and fill it with input values
work_queue = queue.Queue()
for i in input_range:
    work_queue.put(i)

### Start a number of threads
threads = [
    threading.Thread(target=worker, args=(work_queue,))
    for i in range(ncpus)]

for t in threads:
    t.start()

### Wait until all of them are done
for t in threads:
    t.join()

print()
~~~

> ## Discussion: where's the speed-up?
> While mileage may vary, parallelizing `calc_pi`, `calc_pi_numpy` and `calc_pi_numba` this way will
> not give the expected speed-up. `calc_pi_numba` should give *some* speed-up, but nowhere near the
> ideal scaling over the number of cores. This is because Python only allows one thread to access the
> interperter at any given time, a feature also known as the Global Interpreter Lock.
{: .discussion}


# A few words about the Global Interpreter Lock
The Global Interpreter Lock (GIL) is an infamous feature of the Python interpreter.
It both guarantees inner thread sanity, making programming in Python safer, and prevents us from using multiple cores from
a single Python instance.
When we want to perform parallel computations, this becomes an obvious problem.
There are roughly two classes of solutions to circumvent/lift the GIL:

- Run multiple Python instances: `multiprocessing`
- Have important code outside Python: OS operations, C++ extensions, cython, numba

The downside of running multiple Python instances is that we need to share program state between different processes.
To this end, you need to serialize objects using `pickle`, `json` or similar, creating a large overhead.
The alternative is to bring parts of our code outside Python.
Numpy has many routines that are largely situated outside of the GIL.
The only way to know for sure is trying out and profiling your application.

To write your own routines that do not live under the GIL there are several options: fortunately `numba` makes this very easy.

~~~python
@numba.jit(nopython=True, nogil=True)
def calc_pi_numba(N):
    M = 0
    for i in range(N):
        x = random.uniform(-1, 1)
        y = random.uniform(-1, 1)

        if x**2 + y**2 < 1.0:
            M += 1
    return 4 * M / N
~~~
{: .source}

The `nopython` argument forces Numba to compile the code without referencing any Python objects,
while the `nogil` argument enables lifting the GIL during the execution of the function.

> ## Challenge: profile the fixed program
> The nogil version of `calc_pi_numba` should scale nicely with the number of cores used.
{: .challenge}
