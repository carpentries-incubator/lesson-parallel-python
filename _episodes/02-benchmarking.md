---
title: "Benchmarking your code"
teaching: 40
exercises: 20
questions:
- "How do we know our program ran faster?"
- "How do we learn about efficiency?"
objectives:
- "View performance on system monitor"
- "Find out how many cores your machine has"
- "Use `%time` and `%timeit` line-magic"
- "Use a memory profiler"
- "Plot performance against number of work units"
- "Understand the influence of hyper-threading on timings."
keypoints:
- "It is often non-trivial to understand performance."
- "Memory is just as important as speed."
- "Measuring is knowing."
---

# A first example with Dask
We will get into creating parallel programs in Python later. First let's see a small example. Open
your system monitor, and run the following:

~~~python
# Summation making use of numpy:
import numpy as np
result = np.arange(10**8).sum()
~~~
{: .source}

~~~python
# The same summation, but using dask to parallelize the code.
# NB: the API for dask arrays mimics that of numpy
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

# Memory profiling
We will use the [`memory_profiler` package](https://github.com/pythonprofilers/memory_profiler) to track memory usage.

~~~sh
pip install memory_profiler
~~~
{: .source}

FIXME: workout example in Jupyter, see gh:nlesc/noodles notebook


# Alternate Profiling

Dask has a couple of profiling options as well

~~~python
from dask.diagnostics import Profiler, ResourceProfiler
work = da.arange(10**8).sum()
with Profiler() as prof, ResourceProfiler(dt=0.001) as rprof:
    result2 = work.compute()

from bokeh.plotting import output_notebook
from dask.diagnostics import visualize
visualize([prof,rprof], output_notebook())
~~~
FIXME: somehow the visualisation turns up in a separate file and in the notebook, I cannot disable the separate file atm.


~~~python
with ResourceProfiler(dt=0.001) as rprof2:
    result = np.arange(10**8).sum()
visualize([rprof2], output_notebook())
~~~
FIXME: without the Profiler, the time axis is not nicely scaled. Profiler does not work with dask commands.

# How many cores?
You can find out how many cores you have on your machine.

On Linux:
~~~bash
lscpu
~~~
{: .source}

FIXME: add respective commands on Windows and Mac

On a machine with 8 listed cores doing this (admittedly oversimplistic) benchmark:

~~~python
import timeit
x = [timeit.timeit(
        stmt=f"da.arange(5*10**9).sum().compute(num_workers={n})",
        setup="import dask.array as da",
        number=1)
     for n in range(1, 9)]
~~~

Gives the following result:

~~~python
import pandas as pd
pd.DataFrame({"n": range(1, 9), "t": x})
data.set_index("n").plot()
~~~

![Timings against number of cores](../fig/more-cores.svg)

> # Discussion
> Why is the runtime increasing if we add more than 4 cores?
> This has to do with **hyper-threading**. On most architectures it makes not much sense to use more
> workers than the number of physical cores you have.
{: .discussion}

{% include links.md %}
