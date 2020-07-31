---
title: "Computing Pi"
teaching: 60
exercises: 30
questions:
- "FIXME"
objectives:
- "Understand the GIL"
- "Apply `numba.jit`"
- "Be creative with `dask.bag`"
- "Extra: use `dask.delayed`"
keypoints:
- "Vectorized algorithms are both a blessing and a curse."
- "Many problems fit a pattern of `map`, `filter` and `reduce` operations."
- "If we want the most efficient parallelism on a single machine, we need to unlock the GIL."
- "Numba helps you both speeding up and lifting code from the GIL."
---

# Monte Carlo
In order to witness the advantages of parallelization we need an algorithm that is 1. parallelizable and 2. complex enough to take a few seconds of CPU time. In order to not scare away the interested reader, we need this algorithm to be understandable and, if possible, interesting. We chose a classical algorithm for demonstrating parallel programming: estimating the value of number π.

The algorithm we are presenting is one of the classical examples of the power of Monte-Carlo methods. This is an umbrella term for several algorithms that use random numbers to approximate exact results. We chose this algorithm because of its simplicity and straightforward geometrical interpretation.

We can compute the value of π using a random number generator. We count the points falling inside
the blue circle M compared to the green square N. Then π is approximated by the ration 4M/N.

![Computing Pi](../fig/calc_pi_3_wide.svg)

> ## Challenge: Implement the algorithm
> Use only standard Python and the function `random.uniform`. The function should have the following
> interface:
> ~~~python
> import random
> def calc_pi(N):
>     """Computes the value of pi using N random samples."""
>     pass
> ~~~
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
> > ~~~
> > {: .source}
> {: .solution}
{: .challenge}

We now demonstrate a Numpy version of this algorithm.

~~~python
import numpy as np

def calc_pi_numpy(N):
    # Simulate impact coordinates
    pts = np.random.uniform(-1, 1, (2, N))
    # Count number of impacts inside the circle
    M = np.count_nonzero((pts**2).sum(axis=0) < 1)
    return 4 * M / N

calc_pi_numpy(10**8)
~~~
{: .source}

We can demonstrate that this is much faster than the 'naive' implementation. This is a
**vectorized** version of the original algorithm.

> ## Discussion: is this all better?
> What is the downside of this implementation?
> - memory use
> - less intuitive
> - monolithic approach, less composable?
{: .discussion}

> ## Challenge: Daskify
> Write `calc_pi_dask` to make the Numpy version parallel. Compare speed and memory performance with
> the Numpy version.
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
> > calc_pi_numpy(10**8).compute()
> > ~~~
> > {: .source}
> {: .solution}
{: .challenge}

# The GIL

# Go Numba
Numba makes it easier to create accellerated functions. You can use it with the decorator `numba.jit`.

~~~python
import numba

@numba.jit
def sum_range(a: int):
    """Compute the sum of the numbers in the range [0, a)."""
    x = 0
    for i in range(a):
        x += i
    return x
~~~

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
%timeit sum_range(10**7)
~~~
{: .source}

~~~
162 ns ± 0.885 ns per loop (mean ± std. dev. of 7 runs, 10000000 loops each)
~~~
{: .output}

> ## Challenge: Numbify `comp_pi`
> Create a Numba version of `comp_pi`. Measure its performance.
>
> > ## Solution
> > Add the `@numba.jit` decorator to the first 'naive' implementation.
> {: .solution}
{: .challenge}

# Parallelize using Dask bags
We can run the Numba version of `comp_pi` in parallel using Dask bags.

> ## Discussion
> Open the Dask documentation on bags: https://docs.dask.org/en/latest/bag-api.html
> Discuss the `map` and `filter` and `reduction` methods
{: .discussion}

> ## Challenge
> Look at the `mean`, `pluck`, and `topk` methods, match them up with `map`, `filter` and
> `reduction` methods.
> > ## Solution
> > `mean` is a reduction, `pluck` is a mapping, and `topk` is a filter.
> {: .solution}
{: .challenge}

> ## Challenge
> Rewrite the following program in terms of a Dask bag. Make it
> spicy by using your favourite literature classic from project Gutenberg as input.
> Example: Adventures of Sherlock Holmes, https://www.gutenberg.org/files/1661/1661-0.txt
>
> ~~~python
> text = "Lorem ipsum"
> words = set()
> for w in text.split():
>     words.insert(w)
> print("This corpus contains {n} unique words.".format(n=len(w)))
> ~~~
>
> Tip: start by just counting all the words in the corpus, then expand from there.
> Extra: use `nltk.stem` to count word stems in stead of different variants of the same word.
>
> > ## Solution
> > Use `read_text` to read the text efficiently, split the words and `flatten` to create a
> > single bag, then `map` to capitalize all the words (or find their stems).
> > To split the words, use `group_by` and finaly `count` to reduce to the number of
> > words. Other option `distinct`.
> > FIXME: add tested implementation
> {: .solution}
{: .challenge}

~~~python
import dask.bag
bag = dask.bag.from_sequence(repeat(10**7, 24))
shots = bag.map(calc_pi)
estimate = shots.mean()
estimate.visualize()
estimate.compute()
~~~
{: .source}

FIXME: profile this program

> ## Discussion: where's the speed-up?
> We still need to unlock the GIL
{: .discussion}

> ## Challenge: profile the fixed program
> FIXME: solution
{: .challenge}

# Extra: Dask Delayed
FIXME: add output

We can rewrite the same program using `dask.delayed`

~~~python
from dask import delayed
~~~
{: .source}

The `delayed` decorator builds a dependency graph from function calls.

~~~python
@delayed
def add(a, b):
    return a + b
~~~
{: .source}

~~~python
x_p = add(1, 2)
y_p = add(x, 3)
z_p = add(x_p, y_p)
z_p.visualize()
~~~
{: .source}

> ## Note
> It is often a good idea to suffix variables that you know are promises with `_p`. That way you
> keep track of promises versus immediate values.
{: .callout}

We can also make a **promise** by directly calling `delayed`

~~~python
N = 10**7
x_p = delayed(calc_pi)(N)
~~~
{: .source}

It is now possible to call `visualize` or `compute` methods on `x_p`.

We can build new primitives from the ground up.

~~~python
@delayed
def gather(*args):
    return list(args)
~~~
{: .source}

> ## Challenge
> Can you describe what the `gather` function does in terms of lists and promises?
> > ## Solution
> > It turns a list of promises into a promise of a list.
> {: .solution}
{: .challenge}

> ## Challenge
> Write a `delayed` function that computes the mean of its arguments. Complete the program to
> compute pi in parallel.
>
> > ## Solution
> > ~~~python
> > @delayed
> > def mean(*args):
> >     return sum(args) / len(args)
> >
> > pi_p = mean(*(delayed(calc_pi)(N) for i in range(10)))
> > pi_p.compute()
> > ~~~
> > {: .source}
> {: .solution}
{: .challenge}

In practice you may not need to use `@delayed` functions too often, but it does offer ultimate
flexibility. You can build complex computational workflows in this manner, replacing shell
scripting, make files and the likes.

