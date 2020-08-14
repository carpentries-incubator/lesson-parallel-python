---
title: "Introduction"
teaching: 20
exercises: 15
questions:
- "What problems are we solving, and what are we **not** discussing?"
- "Why do we still use Python?"
- "What is parallel programming?"
- "Why can it be hard to write a parallel program?"
objectives:
- "Recognize serial and parallel paterns"
- "Identify problems that can be parallelized"
- "Identify common pitfalls"
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

In this course we will show several possible ways of speeding up your program and making it ready
to function in parallel. We will be introducing the following modules

1. `threading` speeding up a program on a single computer (shared memory)
3. `dask` making things a lot easier
4. `numba` speed up your procedures
5. `memory_profile` monitor memory performance
6. `asyncio` python native asynchronous programming

More importantly, we will show how to change the design of a program to fit parallel paradigms. This
often involves techniques from **functional programming**.

What we won't talk about: **distributed programming**, this is a huge can of worms. It is easy to
show simple examples, but depending on the problem, solutions will be wildly different. Dask has a
lot of functionality to help you in setting up for running on a network. The important bit is that,
once you have made your code suitable for parallel computing, you'll have the right mind-set to get
it to work in a distributed environment.

# FIXME: Overview and rationale
This is an advanced course. Why is it advanced? We (hopefully) saw in the discussion that although
many of your problems share similar characteristics, it is the details that will determine different
solutions. We all need our algorithms, models, analysis to run in a way that many hands make light
work. When such a situation arises with a group of people, we start with a meeting discussing who
does what, when do we meet again to sync up, etc. After a while you can get the feeling that all you
do is be in meetings. We will see that there are several abstractions that can make our life easier.
In large parts this course will use Dask to illustrate these abstractions.

- Vectorized instructions: tell many workers to do the same work on a different piece of data. This
  is where `dask.array` and `dask.dataframe` come in. We will illustrate this model of working by
computing the number Pi later on.
- Map/filter/reduce: This is a method where we combine different functionals to create a larger
  program. We will use `dask.bag` to count the number of unique words in a novel using this
formalism.
- Task-based parallism: this may be the most generic abstraction as all the others can be expressed
  in terms of tasks or workflows. This is `dask.delayed`.

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
> > ![dependency diagram](../fig/soup.png)
> {: .solution}
{: .challenge}

{% include links.md %}

