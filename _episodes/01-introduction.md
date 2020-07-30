---
title: "Introduction"
teaching: 0
exercises: 0
questions:
- "How can I speed-up my program?"
- "How can I scale my program to larger data sets?"
- "Why do we still use Python?"
- "What is parallel programming?"
- "Why can it be hard to write a parallel program?"
objectives:
- "Recognize serial and parallel paterns"
- "Identify problems that can be parallelized"
- "Identify common pitfalls"
- "View performance on system monitor"
- "Do timing/benchmarking"
keypoints:
- "Programs are parallelizable if you can identify independent tasks."
- "To make programs scalable, you need to chunk the work."
- "Parallel programming often triggers a redesign; we use different patterns."
- "Doing work in parallel does not always give a speed-up."
---

# Common problems

> ## What problem(s) are we solving?
> Ask around what problems participants encountered, "why did you sign up?".
{: .discussion}

Most problems will fit in one of two categories:
- I wrote this code in Python and its not fast enough.
- I run this code on my Laptop, but the target problem size is bigger than the RAM.

# What is parallel computing?
Suppose we have a computation, where each step **depends** on a previous one:

~~~python
x = some_input
for i in range(n):
  x = f(x)
print(x)
~~~
{: .source}

This computation is **inherently serial**. We can show a diagram showing the dependencies for each function
call:
![Serial computation](../fig/serial.png)

If however, the computation involves **independent work**, we can do things in **parallel**:

~~~python
for i in range(n):
  x[i] = f(some_input[i])
print(collect(x))
~~~
{: .source}

Now the **dependency graph** looks different
![Parallel computation](../fig/parallel.png)

> ## Challenge: Parallelised Pea Soup
> We have the following recipe:
> 1.  (1 min) Pour water into a soup pan, ad the split peas and bay leaf and bring it to boil.
> 2. (60 min) Remove any foam using a skimmer and let it simmer under a lid for about 60 minutes.
> 3. (15 min) Clean and chop the leek, celeriac, onion, carrot and potato.
> 4. (20 min) Remove the bay leaf, add the vegetables and simmer for 20 more minutes; stir the soup
occasionally.
> 5.  (1 day) Leave the soup for one day. Reheat before serving and add a sliced (vegetarian) smoked
>     sausage, season with pepper and salt.
>
> Can you identify potentials for parallelisation in this recipe? If you're cooking alone, and what
> if you have help? Is the soup done any faster? Draw a dependency diagram.
>
> > ## Solution
> > - You can cut vegetables while simmering the split peas.
> > - If you have help, you can parallelize cutting vegetables further.
> > - There are two 'workers': the cook and the stove.
> {: .solution}
{: .challenge}

# A first example with Dask
We will get into creating parallel programs in Python later. First let's see a small example. Open
your system monitor, and run the following:

~~~python
import numpy as np
result = np.arange(10**8).sum()
~~~
{: .source}

~~~python
import dask.array as da
work = da.arange(10**8).sum()
result = work.compute()
~~~
{: .source}

![System monitor](../fig/system-monitor.jpg)

How can we test in a more rigorous way? In Jupyter we can use some line magics!

~~~python
%%time
np.arange(10**8).sum()
~~~
{: .source}

This was only a single run, how can we trust this?

~~~python
%%timeit
np.arange(10**8).sum()
~~~
{: .source}

This does not tell you anything about memory consumption or efficiency though.
We will use the [`memory_profiler` package](https://github.com/pythonprofilers/memory_profiler) to track memory usage.

~~~sh
pip install memory_profiler
~~~
{: .source}

{% include links.md %}

