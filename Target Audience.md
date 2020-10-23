# Target Audience

## Personae

- Georgina Verdronkenland, PhD in watermanagement. Is specialized in numerical modelling of flooding areas. Wrote a suite of models in Python (her boss is still using Matlab). Her models work fine on a single polder, but they don't scale to the entire Netherlands. She wants to learn if parallelisation techniques in Python can help her speed things up. In her spare time Georgina likes to play saxophone in her jazz band.

- Bob Blackboard studied mathematics. Most of his training happened with pen and paper. Now he works as an applied mathematician at an earth sciences department, analyzing big amounts of satellite imagery data. The fact that the amount of data that a computer can handle is limited is a relatively new (and pretty annoying) discovery. His analysis needs a speed up, and he hopes it can be done quickly and as easy as possible.

- John Smith is a postdoc with experience in earth-observation, familiar with Python tools to work on geospatial data, can write a serial program but is interested in speeding it up by making use of multi-core CPUs (s)he has on his/her desktop. Interested whether the same framework is portable to clusters/supercomputers. 

## Premise
The participant should know the following:

- Working familiarity with Python and NumPy


We advice to install in advance the following software:

- Python core
- Jupyter Lab
- htop, or some other system-monitor


## Expectations
After following this course:

- Mental model of single computer with multiple cores
- Mental model of networked computers
- Mental model of Python as interpeter vs compiled languages
- Recognize patterns for parallelisation
    - map (embarassingly parallel)
    - reduce (summing a sequence)
- Recognize non-parallelizable problems
    - Integrating difference/differential equations
- GIL
    - Why Python sucks
    - Why we **do** use Python
- Understand the overhead that can be caused
    - communication between threads/workers
    - inefficiency in algorithms
    - Parallel = faster? Not always!
- Know about these frameworks
    - Dask
    - (native) Futures
    - mpi4py ???

## Structure
The lesson is (for one part) centered around the problem of computing π using the random number generator ([interactive example](https://www.geogebra.org/m/mueUbwgg)). The different teaching points should be intermixedly why/how or context/method based.

# Parallel Python lesson
> The first part is in explorative/discussion mode with the audience. Ask for peoples experiences, stories, problems. Why they think Python is their tool, why they want to go parallel.

# What is parallelization?
> For this section we can use part of [the blog](https://blog.esciencecenter.nl/parallel-programming-in-python-7fd62c90217d). Particularly the figures are worth reusing.

## Why is it useful? / Why should I care?

### Why still Python?
strawman: If I want my Python to run faster, why not rewrite it in C++/Fortran/Rust?
Python is very popular. It is relatively easy to write programs of some complexity in Python. Developer time vs run time. Connect to community. Use someone else's solution: availability of packages for common problems.

## TODO: Success example

> People need a positive story to begin with.

Least requirements:
- simple problem
- two versions
- timing
- hurray!

Candidate problem:
```
import numpy as np
np.arange(1000000000).sum() 
```

vs

```
import dask.array as da
sum = da.arange(1000000000).sum()
sum.compute()
```
The speedup can be easily understood by visualizing the Dask graph.

The system monitor reads:

![](https://i.imgur.com/WeWVa9S.jpg)


## Let's start! (follows the blog post)
> switch to (frontal) teacher mode

- Introduce the π problem
    - no choice overhead: *monte-carlo*, *geometry*
    - why is this *parallelisable*
    - multiple *workers* (cpus)
    - *mapping*
    - *sequential* versus *parallel* diagram

![serial](https://miro.medium.com/max/429/0*ooJOGfIS2703_zD_)

![parallel](https://miro.medium.com/max/355/0*C1jtPbLg7Ntgvrgs)

> feedback moment: show pea-soup recipe, ask people to parallelise it: what are the workers? can you draw a diagram?

- Write a very na(t)ive version
    - the code contains a *loop*
    - we use *random numbers*
- Write a `numpy` version
    - *Vectorised* instruction (*SIMD*)

> feedback moment: why is the numpy version faster?

- compiled vs interpreted
    - Underlying fast code (FORTRAN/C)
    - *compiler*, *machine code*, *interpreter*
    
- use `%timeit` (explain problems in benchmarking, what is included in the timing, what parts do we care about?)
    - *benchmarking*, *jupyter magic* (will trigger discussion)

> feedback moment: have participants run benchmarks of native vs. numpy, question: how do we know if we're running in parallel?

- show use of system-monitor or htop: gnome-system-monitor has nice graphs that will do well with the audience. On Windows there should be a 'performance' tab in the task manager. Another alternative: https://github.com/nschloe/perfplot

- write a version with `dask.array`
    - check *memory usage*

- Write a version with `threading`
- Shock and horror

# Parallel primitives in Python

## Threading

## Multiprocessing

## Async

# GIL

## OS calls

## Cython

## Numba

# Frameworks

## Futures

## Dask

