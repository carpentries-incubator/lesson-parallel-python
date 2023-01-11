---
title: 'Asyncio'
teaching: 30
exercises: 10
---

:::questions
- What is Asyncio?
- When is asyncio usefull?
:::

:::objectives
- Understand the difference between a coroutine and a function.
- Know the rudimentary basics of `asyncio`.
- Perform parallel computations in `asyncio`.
:::

# Introduction to Asyncio
Asyncio stands for "asynchronous IO", and as you might have guessed it has little to do with either asynchronous work or doing IO. In fact, the system is more like a carefully tuned set of gears running a multitude of tasks *as if* you have a lot of OS threads running. In the end they are all powered by the same crank. The gears in `asyncio` are called **coroutines**, its teeth moving other coroutines wherever you find the `await` keyword.

The main application for `asyncio` is hosting back-ends for web services, where a lot of tasks may be waiting on each other, while the server still needs to be responsive to new events. In that respect, `asyncio` is a little bit outside the domain of computational science. Nevertheless, you may encounter async code in the wild, and you *can* do parallelism with `asyncio` if you want a higher level abstraction but don't want to depend on `dask` or a similar alternative.

Many modern programming languages have features that are very similar to `asyncio`.

## Run-time
The main point of `asyncio` is that it offers a different formalism for doing work than what you're used to from functions. To see what that means, we need to understand functions a bit better.

### Call stacks
FIXME: improve wording

A function call is best understood in terms of a stack based system. When you call a function, you give it its arguments and forget for the moment what you were doing. Or rather, whatever you were doing, push it on a stack and forget about it. Then, with a clean sheet, you start working on the given arguments until you arrive at a result. This result is what you remember, when you go back to the stack to see what you were doing.
In this manner, every function call pushes a context to the stack, and every return statement, we pop back.

Crucially, when we pop back, we forget about the context inside the function. This way, there is always a single concious stream of thought. Function calls can be evaluated by a single active agent.

### Coroutines
:::instructor
This section goes rather in depth on coroutines. This is meant to grow the correct mental model about what's going on with `asyncio`.
:::

When working with coroutines, things are a bit different. When a result is returned from a coroutine, the coroutine keeps existing, its context is not forgotten. Coroutines exist in Python in several forms, the simplest being a **generator**. The following generator produces all integers (if you wait long enough):

```python
def integers():
  a = 1
  while True:
    yield a
    a += 1
```

Then

```python
for i in integers():
  print(i)
  if i > 10:   # or this would take a while
    break
```

or

```python
from itertools import islice
islice(integers(), 0, 10)
```

```output
[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
```

:::challenge
## Challenge: generate all even numbers
Can you write a generator that generates all even numbers? Try to reuse `integers()`. Extra: Can you generate the Fibonacci numbers?

::::solution
```python
def even_integers():
  for i in integers():
    if i % 2 == 0:
      yield i
```

or

```python
def even_integers():
  return (i for i in integers() if i % 2 == 0)
```

For the Fibonacci numbers:

```python
def fib():
  a, b = 1, 1
  while True:
    yield a
    a, b = b, a + b
```
::::
:::

The generator gives away control, passing a value back, expecting, maybe, if faith has it, that control will be passed back to it in the future. The keyword `yield` applies in all its meanings: control is yielded, and we have a yield in terms of harvesting a crop.

A generator conceptually only has one-way traffic: we get output. We can also use `yield` the other way around: it can be used to send information to a coroutine. For instance: we can have a coroutine that prints whatever you send to it.

```python
def printer():
  while True:
    x = yield
    print(x)

p = printer()
next(p)   # we need to advance the coroutine to the first yield
p.send("Mercury")
p.send("Venus")
p.send("Earth")
```

:::challenge
## Challenge: line numbers
Change `printer` to add line numbers to the output.

::::solution
## Solution

```python
def printer():
  lineno = 1
  while True:
    x = yield
    print(f"{lineno:03} {x}")
```
::::
:::

In practice, the `send` form of coroutines is hardly ever used. Cases where you'd need it are rare, and chances are noone will understand your code. Where it was needed before, its use is now largely superceded by `asyncio`.

Now that you have seen coroutines, it is a small step towards `asyncio`. The idea is that you can use coroutines to build a collaborative multi-threading environment. In most modern operating systems, execution threads are given some time, and then when the OS needs to do something else, control is taken away pre-emptively. In **collaborative multi-tasking**, every worker knows it is part of a collaborative, and it voluntarily yields control to the scheduler. With coroutines and `yield` you should be able to see that it is possible to create such a system, but it is not so straight forward, especially when you start to consider the propagation of exceptions.

## Syntax
While `asyncio` itself is a library in standard Python, this library is actually a core component for using the associated async syntax. There are two keywords here: `async` and `await`.

`async` Is a modifier keyword that modifies the behaviour of any subsequent syntax to behave in a manner that is consistent with the asynchronous run-time.

`await` Is used inside a coroutine to wait for another coroutine to yield a result. Effectively, control is passed back to the scheduler, which may decide to give back control when a result is present.

# A first program
Jupyter understands asynchronous code, so you can `await` futures in any cell.

```python
import asyncio

async def counter(name):
  for i in range(5):
    print(f"{name:<10} {i:03}")
    await asyncio.sleep(0.2)

await counter("Venus")
```

We can have coroutines work concurrently when we `gather` two coroutines.

```python
await asyncio.gather(counter("Earth"), counter("Moon"))
```

Note that, although the Earth counter and Moon counter seem to operate at the same time, in actuality they are alternated by the scheduler and still running in a single thread!

## Timing asynchronous code
While Jupyter works very well with `asyncio`, one thing that doesn't work is line or cell-magic. We'll have to write our own timer.

``` {.python #async-timer}
from dataclasses import dataclass
from typing import Optional
from time import perf_counter
from contextlib import asynccontextmanager


@dataclass
class Elapsed:
    time: Optional[float] = None


@asynccontextmanager
async def timer():
    e = Elapsed()
    t = perf_counter()
    yield e
    e.time = perf_counter() - t
```

Now we can write:

```python
async with timer() as t:
  await asyncio.sleep(0.2)
print(f"that took {t.time} seconds")
```

These few snippets of code require advanced Python knowledge to understand. Rest assured that both classic coroutines and `asyncio` are a large topic to cover, and we're not going to cover all of it. At least, we can now time the execution of our code!

## Compute $\pi$ again
As a reminder, here is our Numba code to compute $\pi$.

``` {.python #calc-pi-numba}
import random
import numba


@numba.njit(nogil=True)
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
```

We can send work to another thread with `asyncio.to_thread`.

```python
async with timer() as t:
  await asyncio.to_thread(calc_pi, 10**7)
```

:::challenge
## Gather multiple outcomes
We've seen that we can gather multiple coroutines using `asyncio.gather`. Now gather several `calc_pi` computations, and time them.

::::solution
```python
async with timer() as t:
  result = await asyncio.gather(
    asyncio.to_thread(calc_pi, 10**7),
    asyncio.to_thread(calc_pi, 10**7))
```
::::
:::

We can put this into a new function `calc_pi_split`:

``` {.python #async-calc-pi}
async def calc_pi_split(N, M):
    lst = await asyncio.gather(*(asyncio.to_thread(calc_pi, N) for _ in range(M)))
    return sum(lst) / M
```

Now, see if we get a speed up.

``` {.python #async-calc-pi-main}
async with timer():
    pi = await asyncio.to_thread(calc_pi, 10**8)
    print(f"Value of π: {pi}")
```

``` {.python #async-calc-pi-main}
async with timer():
    pi = await calc_pi_split(10**7, 10)
    print(f"Value of π: {pi}")
```

# Working with `asyncio` outside Jupyter
Jupyter already has an asyncronous loop running for us. If you want to run scripts outside Jupyter you should write an asynchronous main function and call it using `asyncio.run`.

:::challenge
## Compute $\pi$ in a script
Collect what we have done so far to compute $\pi$ in parallel into a script and run it.

::::solution
``` {.python file="src/calc_pi/__init__.py"}

```

``` {.python file="src/calc_pi/numba.py"}
<<calc-pi-numba>>
```

``` {.python file="src/async_timer.py"}
<<async-timer>>
```

``` {.python file="src/calc_pi/async_pi.py"}
import asyncio
from async_timer import timer

from .numba import calc_pi

<<async-calc-pi>>

async def main():
    calc_pi(1)
    <<async-calc-pi-main>>

if __name__ == "__main__":
    asyncio.run(main())
```
::::
:::

:::challenge
## Efficiency
Play with different subdivisions for `calc_pi_split` such that `M*N` remains constant. How much overhead do you see?

::::solution
``` {.python file="src/calc_pi/granularity.py"}
import asyncio
import pandas as pd
from plotnine import ggplot, geom_line, geom_point, aes, scale_y_log10, scale_x_log10

from .numba import calc_pi
from .async_pi import calc_pi_split
from async_timer import timer

calc_pi(1)


async def main():
    timings = []
    for njobs in [2**i for i in range(13)]:
        jobsize = 2**25 // njobs
        print(f"{jobsize} - {njobs}")
        async with timer() as t:
            await calc_pi_split(jobsize, njobs)
        timings.append((jobsize, njobs, t.time))

    timings = pd.DataFrame(timings, columns=("jobsize", "njobs", "time"))
    plot = ggplot(timings, aes(x="njobs", y="time")) \
        + geom_line() + geom_point() + scale_y_log10() + scale_x_log10()
    plot.save("asyncio-timings.svg")

if __name__ == "__main__":
    asyncio.run(main())
```

![timings](fig/asyncio-timings.svg){alt="a dip at njobs=10 and overhead ~0.1ms per task"}

From these timings we can learn that the overhead is around 0.1ms per task.
::::
:::

:::keypoints
- Use `asyncio.gather` to collect work.
- Use `asyncio.to_thread` to perform CPU intensive tasks.
- Inside a script: always make an asynchronous `main` function, and run it with `asyncio.run`.
:::

