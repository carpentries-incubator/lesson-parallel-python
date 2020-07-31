---
title: "Benchmarking your code"
teaching: 0
exercises: 0
questions:
- "How do we know our program ran faster?"
- "How do we learn about efficiency?"
objectives:
- "View performance on system monitor"
- "Use `%time` and `%timeit` line-magic"
- "Use a memory profiler"
- "Plot performance against number of work units"
keypoints:
- "First key point. Brief Answer to questions. (FIXME)"
---

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

# Memory profiling
We will use the [`memory_profiler` package](https://github.com/pythonprofilers/memory_profiler) to track memory usage.

~~~sh
pip install memory_profiler
~~~
{: .source}

FIXME: workout example in Jupyter, see gh:nlesc/noodles notebook

{% include links.md %}

#Alternate Profiling

Dash has a couple of rofiling options as well

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
