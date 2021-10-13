---
title: "Asyncio fundamentals"
teaching: 40
exercises: 20
questions:
- "What is AsyncIO?"
- "How do I structure an async program?"
objectives:
- "Understand the different mental model of asynchronous program execution flow."
- "Understand the difference between a function and a coroutine."
- "Create classic generators, use the `yield` keyword."
- "Setup an async program with an event loop using `asyncio.run()`."
- "Create an asynchronous generator, use `async` and `await` keywords."
keypoints:
- "Programs are parallelizable if you can identify independent tasks."
---

# Asyncio
This is not for everyone. You may encounter `asyncio` in the wild though.

## Different runtime
With functions (FIXME: make a graphic):

```
  call f
  |      ---> new context: f
  |           | do work
  |      <--- | return result (context destroyed)
  | use result
```

With generators (FIXME: make a graphic):

```
  call f
  |               ---> new context: f
  |               <--- | yield
  | do some work
  | ask f         ---> | continue in old context
  |                    | do some work
  |               <--- | yield result
  | work with result
  | ask f again   ---> | do some more work
  |               <--- | yield another result
  | yay!
```

A coroutine returns to its previous state on the next call.
Let's see an example. We compute the Fibonacci numbers:

~~~python
def fib():
  a, b = 1, 1
  while True:
    yield a
    a, b = b, a + b
~~~
{: .source}

To see if this is working

~~~python
from itertools import islice
list(islice(fib(), 20))
~~~
{: .source}

We can run the generator step by step:

~~~python
x = fib()
for i in range(20):
  n = next(x)
  print(f"{i:8} {n:8}")
~~~
{: .source}

It is possible to model *light weight threading* using generators. On the background there is a
**event loop** that manages a set of **coroutines**. Each coroutine is entered similar to a normal
generator and gives back control to the event loop through `await`, similar to `yield` (actually
`await` is synonymous to `yield from`).

~~~python
import asyncio

async def fun_a():
    print("Running coroutine *a*.")
    await asyncio.sleep(0)
    print("Back in *a*.")
    return "result from *a*"

async def fun_b():
    print("Running coroutine *b*.")
    await asyncio.sleep(0)
    print("Back in *b*.")
    return "result from *b*"

await asyncio.gather(fun_a(), fun_b())
~~~
{: .source}

## Event loop
It is important to have an event-loop running before you do anything else:

~~~python
import asyncio

async def main()
    # Initialize any Task, Lock or Semaphore inside main()
    await work

asyncio.run(main())
~~~
{: .source}

However, Jupyter already runs in an async loop, so we should just:

~~~python
await main()
~~~
{: .source}

##

