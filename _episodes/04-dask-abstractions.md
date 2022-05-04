---
title: "Dask abstractions: delays"
teaching: 60
exercises: 30
questions:
- "What abstractions does Dask offer?"
- "What programming patterns exist in the parallel universe?"
objectives:
- "Understand the abstraction of delayed evaluation"
- "Use the `visualize` method to create dependency graphs"
keypoints:
- "Use abstractions to keep programs manageable"
---

[Dask](https://dask.org/) is one of the many tools available for parallelizing Python code in a comfortable way.
We've seen a basic example of `dask.array` in a previous episode.
Now, we will focus on the `delayed` and `bag` sub-modules.
Dask has a lot of other useful components, such as `dataframe` and `futures`, but we are not going to cover them in this lesson.

See an overview below:

| Dask module      | Abstraction          | Keywords                            | Covered |
|:-----------------|:---------------------|:------------------------------------|:--------|
| `dask.array`     | `numpy`              | Numerical analysis                  | ✔️       |
| `dask.bag`       | `itertools`          | Map-reduce, workflows               | ✔️       |
| `dask.delayed`   | functions            | Anything that doesn't fit the above | ✔️       |
| `dask.dataframe` | `pandas`             | Generic data analysis               | ❌      |
| `dask.futures`   | `concurrent.futures` | Control execution, low-level        | ❌      |

# Dask Delayed
A lot of the functionality in Dask is based on top of a framework of *delayed evaluation*. The concept of delayed evaluation is very important in understanding how Dask functions, which is why we will go a bit deeper into `dask.delayed`.

~~~python
from dask import delayed
~~~
{: .source}

The `delayed` decorator builds a dependency graph from function calls.

~~~python
@delayed
def add(a, b):
    result = a + b
    print(f"{a} + {b} = {result}")
    return a + b
~~~
{: .source}

A `delayed` function stores the requested function call inside a **promise**. The function is not actually executed yet, instead we
are *promised* a value that can be computed later.

~~~python
x_p = add(1, 2)
~~~
{: .source}

We can check that `x_p` is now a `Delayed` value.

~~~python
type(x_p)
~~~
{: .source}
~~~
[out]: dask.delayed.Delayed
~~~
{: .output}

> ## Note
> It is often a good idea to suffix variables that you know are promises with `_p`. That way you
> keep track of promises versus immediate values.
{: .callout}

Only when we evaluate the computation, do we get an output.

~~~python
x_p.compute()
~~~
{:.source}
~~~
1 + 2 = 3
[out]: 3
~~~
{:.output}

From `Delayed` values we can create larger workflows and visualize them.

~~~python
x_p = add(1, 2)
y_p = add(x_p, 3)
z_p = add(x_p, y_p)
z_p.visualize(rankdir="LR")
~~~
{: .source}

![Dask workflow graph](../fig/dask-workflow-example.svg)
{: .output}

> ## Challenge: run the workflow
> Given this workflow:
> ~~~python
> x_p = add(1, 2)
> y_p = add(x_p, 3)
> z_p = add(x_p, -3)
> ~~~
> Visualize and compute `y_p` and `z_p`, how often is `x_p` evaluated?
> Now change the workflow:
> ~~~python
> x_p = add(1, 2)
> y_p = add(x_p, 3)
> z_p = add(x_p, y_p)
> z_p.visualize(rankdir="LR")
> ~~~
> We pass the yet uncomputed promise `x_p` to both `y_p` and `z_p`. How often do you expect `x_p` to be evaluated? Run the workflow to check your answer.
> > ## Solution
> > ~~~python
> > z_p.compute()
> > ~~~
> > {: .source}
> > ~~~
> > 1 + 2 = 3
> > 3 + 3 = 6
> > 3 + 6 = 9
> > [out]: 9
> > ~~~
> > {: .output}
> > The computation of `x_p` (1 + 2) appears only once.
> {: .solution}
{: .challenge}

We can also make a promise by directly calling `delayed`

~~~python
N = 10**7
x_p = delayed(calc_pi)(N)
~~~
{: .source}

It is now possible to call `visualize` or `compute` methods on `x_p`.

> ## Variadic arguments
> In Python you can define functions that take arbitrary number of arguments:
>
> ```python
> def add(*args):
>  return sum(args)
>
> add(1, 2, 3, 4)   # => 10
> ```
>
> You can use tuple-unpacking to pass a sequence of arguments:
>
> ```python
> numbers = [1, 2, 3, 4]
> add(*numbers)   # => 10
> ```
{: .callout}

We can build new primitives from the ground up.

~~~python
@delayed
def gather(*args):
    return list(args)
~~~
{: .source}

> ## Challenge: understand `gather`
> Can you describe what the `gather` function does in terms of lists and promises?
> > ## Solution
> > It turns a list of promises into a promise of a list.
> {: .solution}
{: .challenge}

We can visualize what `gather` does by this small example.

~~~python
x_p = gather(*(add(n, n) for n in range(10))) # Shorthand for gather(add(1, 1), add(2, 2), ...)
x_p.visualize()
~~~
{: .source}

![a gather pattern](../fig/dask-gather-example.svg)
{: .output}

Computing the result,

~~~python
x_p.compute()
~~~
{: .source}
~~~
[out]: [0, 1, 4, 9, 16, 25, 36, 49, 64, 81]
~~~
{: .output}

> ## Challenge: design a `mean` function and calculate pi
> Write a `delayed` function that computes the mean of its arguments. Use it to esimates pi several times and returns the mean of the results.
>
> ```python
> >>> mean(1, 2, 3, 4).compute()
> 2.5
> ```
>
> Make sure that the entire computation is contained in a single promise.
> > ## Solution
> > ~~~python
> > from dask import delayed
> > import random
> >
> > @delayed
> > def mean(*args):
> >     return sum(args) / len(args)
> >
> > def calc_pi(N):
> >     """Computes the value of pi using N random samples."""
> >     M = 0
> >     for i in range(N):
> >         # take a sample
> >         x = random.uniform(-1, 1)
> >         y = random.uniform(-1, 1)
> >         if x*x + y*y < 1.: M+=1
> >     return 4 * M / N
> >
> >
> > N = 10**6
> > pi_p = mean(*(delayed(calc_pi)(N) for i in range(10)))
> > pi_p.compute()
> > ~~~
> > {: .source}
> {: .solution}
{: .challenge}

You may not seed a significant speedup. This is because `dask delayed` uses threads by default and our native Python implementation
of `calc_pi` does not circumvent the GIL. With for example the numba version of `calc_pi` you should see a more significant speedup.

In practice you may not need to use `@delayed` functions too often, but it does offer ultimate
flexibility. You can build complex computational workflows in this manner, sometimes replacing shell
scripting, make files and the likes.

{% include links.md %}
