---
title: 'Delayed evaluation'
teaching: 10
exercises: 2
---

:::questions
- What abstractions does Dask offer?
- What programming patterns exist in the parallel universe?
:::

:::objectives
- Understand the abstraction of delayed evaluation
- Use the `visualize` method to create dependency graphs
:::


[Dask](https://dask.org/) is one of the many tools available for parallelizing Python code in a comfortable way. We've seen a basic example of `dask.array` in a previous episode. Now, we will focus on the `delayed` and `bag` sub-modules. Dask has a lot of other useful components, such as `dataframe` and `futures`, but we are not going to cover them in this lesson.

See an overview below:

| Dask module      | Abstraction          | Keywords                            | Covered |
|:-----------------|:---------------------|:------------------------------------|:--------|
| `dask.array`     | `numpy`              | Numerical analysis                  | ✔️       |
| `dask.bag`       | `itertools`          | Map-reduce, workflows               | ✔️       |
| `dask.delayed`   | functions            | Anything that doesn't fit the above | ✔️       |
| `dask.dataframe` | `pandas`             | Generic data analysis               | ❌      |
| `dask.futures`   | `concurrent.futures` | Control execution, low-level        | ❌      |

# Dask Delayed
A lot of the functionality in Dask is based on top of a concept known as *delayed evaluation*. Because this concept is so very important in understanding how Dask functions, we will go a bit deeper into `dask.delayed`.

By using `dask.delayed` we change the strategy by which our computation is evaluated. Normally in a computer, you expect commands to be run when you ask for them, and then when the job is complete, you can give the next command. When we use delayed evaluation, we don't wait around to formulate the next command. Instead we create the dependency graph of our complete computation without actually doing any work. When we know the full dependency graph, we can see which jobs can be done in parallel and give those to different workers.

To express a computation in this world, we need to handle future objects *as if they're already there*. These objects may be refered to as *futures* or *promises*. 

:::callout
Python has support for working with futures in several libraries, each time slightly different. The main difference between Python futures and Dask delayed objects is that futures are added to a queue from the first moment you define them, while delayed objects are silent until you ask to compute. We will refer to these 'live' futures as futures, and 'dead' futures (like delayed) as **promises**.
:::

~~~python
from dask import delayed
~~~

The `delayed` decorator builds a dependency graph from function calls.

~~~python
@delayed
def add(a, b):
    result = a + b
    print(f"{a} + {b} = {result}")
    return a + b
~~~

A `delayed` function stores the requested function call inside a **promise**. The function is not actually executed yet, instead we
are *promised* a value that can be computed later.

~~~python
x_p = add(1, 2)
~~~

We can check that `x_p` is now a `Delayed` value.

~~~python
type(x_p)
~~~
~~~output
[out]: dask.delayed.Delayed
~~~

> ## Note
> It is often a good idea to suffix variables that you know are promises with `_p`. That way you
> keep track of promises versus immediate values.
{: .callout}

Only when we evaluate the computation, do we get an output.

~~~python
x_p.compute()
~~~
~~~output
1 + 2 = 3
[out]: 3
~~~

From `Delayed` values we can create larger workflows and visualize them.

~~~python
x_p = add(1, 2)
y_p = add(x_p, 3)
z_p = add(x_p, y_p)
z_p.visualize(rankdir="LR")
~~~

![Dask workflow graph](fig/dask-workflow-example.svg){.output alt="boxes and arrows"}

:::challenge
## Challenge: run the workflow
Given this workflow:

```python
x_p = add(1, 2)
y_p = add(x_p, 3)
z_p = add(x_p, -3)
```

Visualize and compute `y_p` and `z_p` separately, how often is `x_p` evaluated?

Now change the workflow:

```python
x_p = add(1, 2)
y_p = add(x_p, 3)
z_p = add(x_p, y_p)
z_p.visualize(rankdir="LR")
```

We pass the yet uncomputed promise `x_p` to both `y_p` and `z_p`. Now, only compute `z_p`, how often do you expect `x_p` to be evaluated? Run the workflow to check your answer.

::::solution
## Solution
```python
z_p.compute()
```
```output
1 + 2 = 3
3 + 3 = 6
3 + 6 = 9
[out]: 9
```
The computation of `x_p` (1 + 2) appears only once. This should teach you to procrastinate calling `compute` as long as you can.
::::
:::

We can also make a promise by directly calling `delayed`

~~~python
N = 10**7
x_p = delayed(calc_pi)(N)
~~~

It is now possible to call `visualize` or `compute` methods on `x_p`.

:::callout
## Decorators
In Python the decorator syntax is equivalent to passing a function through a function adapter (a.k.a. a higher order function or a functional). This adapter can change the behaviour of the function in many ways. The statement,

```python
@delayed
def sqr(x):
    return x*x
```

is functionally equivalent to:

```python
def sqr(x):
    return x*x

sqr = delayed(sqr)
```
:::

:::callout
## Variadic arguments
In Python you can define functions that take arbitrary number of arguments:

```python
def add(*args):
 return sum(args)

add(1, 2, 3, 4)   # => 10
```

You can use tuple-unpacking to pass a sequence of arguments:

```python
numbers = [1, 2, 3, 4]
add(*numbers)   # => 10
```
:::

We can build new primitives from the ground up. An important function that you will find in many different places where non-standard evaluation strategies are involved is `gather`. We can implement `gather` as follows:

~~~python
@delayed
def gather(*args):
    return list(args)
~~~

:::challenge
## Challenge: understand `gather`
Can you describe what the `gather` function does in terms of lists and promises?
hint: Suppose I have a list of promises, what does `gather` allow me to do?

::::solution
## Solution
It turns a list of promises into a promise of a list.
:::
::::

We can visualize what `gather` does by this small example.

~~~python
x_p = gather(*(add(n, n) for n in range(10))) # Shorthand for gather(add(1, 1), add(2, 2), ...)
x_p.visualize()
~~~

![a gather pattern](fig/dask-gather-example.svg)
{.output alt="boxes and arrows"}

Computing the result,

~~~python
x_p.compute()
~~~
~~~output
[out]: [0, 1, 4, 9, 16, 25, 36, 49, 64, 81]
~~~

:::challenge
## Challenge: design a `mean` function and calculate pi
Write a `delayed` function that computes the mean of its arguments. Use it to esimates pi several times and returns the mean of the results.

```python
>>> mean(1, 2, 3, 4).compute()
2.5
```

Make sure that the entire computation is contained in a single promise.

::::solution
## Solution
~~~python
from dask import delayed
import random

@delayed
def mean(*args):
    return sum(args) / len(args)

def calc_pi(N):
    """Computes the value of pi using N random samples."""
    M = 0
    for i in range(N):
        # take a sample
        x = random.uniform(-1, 1)
        y = random.uniform(-1, 1)
        if x*x + y*y < 1.: M+=1
    return 4 * M / N


N = 10**6
pi_p = mean(*(delayed(calc_pi)(N) for i in range(10)))
pi_p.compute()
~~~
::::
:::

You may not seed a significant speedup. This is because `dask delayed` uses threads by default and our native Python implementation of `calc_pi` does not circumvent the GIL. With for example the numba version of `calc_pi` you should see a more significant speedup.

In practice you may not need to use `@delayed` functions too often, but it does offer ultimate flexibility. You can build complex computational workflows in this manner, sometimes replacing shell scripting, make files and the likes.

:::keypoints
- We can change the strategy by which a computation is evaluated.
- Nothing is computed until we run `compute()`.
- By using delayed evaluation, Dask knows which jobs can be run in parallel.
- Call `compute` only once at the end of your program to get the best results.
:::
