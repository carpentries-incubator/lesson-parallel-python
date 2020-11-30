---
title: "Understanding parallelization in python"
teaching: 60
exercises: 30
questions:
- "What is the Global Interpreter Lock (GIL)?"
- "How do I parallelize a Python application?"
- "What is data parallelism?"
- "What is task parallelism?"
- "How do I use multiple threads in Python?"
objectives:
- "Rewrite a program in a vectorized form."
- "Understand the difference between data and task-based parallel programming."
- "Understand the GIL."
- "Apply `numba.jit` to accelerate Python."
- "Recognize the primitive components of the queue/worker model of execution."
keypoints:
- "Always profile your code to see which parellelization method works best"
- "Vectorized algorithms are both a blessing and a curse."
- "If we want the most efficient parallelism on a single machine, we need to circumvent the GIL."
- "Numba helps you both speeding up code and circumventing the GIL."
---

# Parallelizing a Python application
In order to recognize the advantages of parallelization we need an algorithm that is easy to parallelize, but still complex enough to take a few seconds of CPU time.
To not scare away the interested reader, we need this algorithm to be understandable and, if possible, also interesting.
We chose a classical algorithm for demonstrating parallel programming: estimating the value of number π.

The algorithm we present is one of the classical examples of the power of Monte-Carlo methods.
This is an umbrella term for several algorithms that use random numbers to approximate exact results.
We chose this algorithm because of its simplicity and straightforward geometrical interpretation.

We can compute the value of π using a random number generator. We count the points falling inside the blue circle M compared to the green square N.
Then π is approximated by the ration 4M/N.

![Computing Pi](../fig/calc_pi_3_wide.svg)

> ## Challenge: Implement the algorithm
> Use only standard Python and the function `random.uniform`. The function should have the following
> interface:
> ~~~python
> import random
> def calc_pi(N):
>     """Computes the value of pi using N random samples."""
>     ...
>     for i in range(N):
>         # take a sample
>         ...
>     return ...
> ~~~
>
> Also make sure to time your function!
>
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
> >
> > %timeit calc_pi(10**6)
> > ~~~
> > {: .source}
> >
> > ~~~
> > 676 ms ± 6.39 ms per loop (mean ± std. dev. of 7 runs, 1 loop each)
> > ~~~
> >{: .output}
> >
> {: .solution}
{: .challenge}

Before we start to parallelize this program, we need to do our best to make the inner function as
efficient as we can. We show two techniques for doing this: *vectorization* using `numpy` and
*native code generation* using `numba`.

We first demonstrate a Numpy version of this algorithm.

~~~python
import numpy as np

def calc_pi_numpy(N):
    # Simulate impact coordinates
    pts = np.random.uniform(-1, 1, (2, N))
    # Count number of impacts inside the circle
    M = np.count_nonzero((pts**2).sum(axis=0) < 1)
    return 4 * M / N
~~~
{: .source}

This is a **vectorized** version of the original algorithm. It nicely demonstrates **data parallelization**,
where a **single operation** is replicated over collections of data.
It contrasts to **task parallelization**, where **different independent** procedures are performed in
parallel (think for example about cutting the vegetables while simmering the split peas).

We can demonstrate that this is much faster than the 'naive' implementation:

~~~python
%timeit calc_pi_numpy(10**6)
~~~
{: .source}

~~~
25.2 ms ± 1.54 ms per loop (mean ± std. dev. of 7 runs, 10 loops each)
~~~
{: .output}

> ## Discussion: is this all better?
> What is the downside of the vectorized implementation?
> - It uses more memory
> - It is less intuitive
> - It is a more monolithic approach, i.e. you cannot break it up in several parts
{: .discussion}

> ## Challenge: Daskify
> Write `calc_pi_dask` to make the Numpy version parallel. Compare speed and memory performance with
> the Numpy version. NB: Remember that dask.array mimics the numpy API.
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
> > %timeit calc_pi_dask(10**6).compute()
> > ~~~
> > {: .source}
> >~~~
> >4.68 ms ± 135 µs per loop (mean ± std. dev. of 7 runs, 100 loops each)
> >~~~
> >{: .output}
> {: .solution}
{: .challenge}


# Using Numba to accelerate Python code
Numba makes it easier to create accelerated functions. You can use it with the decorator `numba.jit`.

~~~python
import numba

@numba.jit
def sum_range_numba(a: int):
    """Compute the sum of the numbers in the range [0, a)."""
    x = 0
    for i in range(a):
        x += i
    return x
~~~
{: .source}

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
%timeit sum_range_numba(10**7)
~~~
{: .source}
~~~
162 ns ± 0.885 ns per loop (mean ± std. dev. of 7 runs, 10000000 loops each)
~~~
{: .output}

> ## Challenge: Numbify `comp_pi`
> Create a Numba version of `comp_pi`. Time it.
>
> > ## Solution
> > Add the `@numba.jit` decorator to the first 'naive' implementation.
> > ~~~python
> > @numba.jit
> > def calc_pi_numba(N):
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
> >
> > %timeit calc_pi_numba(10**6)
> > ~~~
> > ~~~
> > 13.5 ms ± 634 µs per loop (mean ± std. dev. of 7 runs, 1 loop each)
> > ~~~
> > {: .output}
> {: .solution}
{: .challenge}

> ## Measuring == knowing
> Always profile your code to see which parallelization method works best.
{: .callout}

> ## `numba.jit` is not a magical command to solve are your problems
> Using numba to accelerate your code often outperforms other methods, but
>  it is not always trivial to rewrite your code so that you can use numba with it.
{: .callout}

# Calling C and C++ libraries
External C and C++ libraries can be called from Python code using a number of options, using e.g. Cython, CFFI, pybind11 and ctypes.
We will discuss the last two, because they require the least amount of boilerplate, for simple cases - 
for more complex examples that may not be the case. Consider this simple C program, test.c, which adds up consecutive numbers:

~~~c
#include <pybind11/pybind11.h>
namespace py = pybind11;

long long sum_range(long long high)
{
  long long i;
  long long s = 0LL;
 
  for (i = 0LL; i < high; i++)
      s += (long long)i;

  return s;
}

PYBIND11_MODULE(test_pybind, m) {
    m.doc() = "Export the sum_range function as sum_range"; 

    m.def("sum_range", &sum_range, "Adds upp consecutive integer numbers from 0 up to and including high-1");
}

~~~
{: .source}

You can easily compile and link it into a shared object (.so) file. First you need pybind11. You can install it in
a number of ways, like pip, but I prefer creating virtual environments using pipenv.

~~~bash
pip install pipenv
pipenv install pybind11
pipenv shell

c++ -O3 -Wall -shared -std=c++11 -fPIC `python3 -m pybind11 --includes` test.c -o test_pybind.so
~~~
{: .source}

which generates a `test_pybind.so` shared object which you can call from a Python program, like this:

~~~python
import test_pybind
sum_range=test_pybind.sum_range

high=1000000000

sum_from_formula=high*(high-1)//2
brute_force_sum=sum_range(high) 
difference=sum_from_formula-brute_force_sum

print()
print("According to a simple formula, this should be the sum of {0} consecutive numbers,".format(high))
print("starting at zero: {0}".format(sum_from_formula))
print()
print("Simply adding up the numbers should yield the same result: {0}".format(brute_force_sum))
print()
print("The two methods should yield the same answer, so this should be zero: {}".format(difference))
print()
~~~
{: .source}

Give this script a suitable name, like `call_C_libraries.py`.
The same thing can be done using ctypes instead of pybind11, but requires slightly more boilerplate
on the Python side of the code and slightly less on the C side. test.c will be just the algorithm:

~~~c
long long sum_range(long long high)
{
  long long i;
  long long s = 0LL;
 
  for (i = 0LL; i < high; i++)
      s += (long long)i;

  return s;
}
~~~
{: .source}

Compile and link using
~~~bash
gcc -O3 -g -fPIC -c -o test.o test.c
ld -shared -o libtest.so test.o
~~~
{: .source}

which generates a libtest.so file.
In the Python script some boilerplate needs to be added:

~~~python
import ctypes
testlib = ctypes.cdll.LoadLibrary("./libtest.so")  

sum_range = testlib.sum_range
sum_range.argtypes = [ctypes.c_longlong]  
sum_range.restype = ctypes.c_longlong 

high=1000000000

sum_from_formula=high*(high-1)//2
brute_force_sum=sum_range(high) 
difference=sum_from_formula-brute_force_sum

print()
print("According to a simple formula, this should be the sum of {0} consecutive numbers,".format(high))
print("starting at zero: {0}".format(sum_from_formula))
print()
print("Simply adding up the numbers should yield the same result: {0}".format(brute_force_sum))
print()
print("The two methods should yield the same answer, so this should be zero: {}".format(difference))
print()

~~~
{: .source}

Now we can time our compiled `sum_range` C library, e.g. from the iPython interface:
~~~python
import ctypes
testlib = ctypes.cdll.LoadLibrary("./libtest.so")
sum_range = testlib.sum_range
sum_range.argtypes = [ctypes.c_longlong]
sum_range.restype = ctypes.c_longlong 
%timeit sum_range(10**7)
~~~
{: .source}
~~~
2.69 ms ± 6.01 µs per loop (mean ± std. dev. of 7 runs, 100 loops each)
~~~

If you compare with the numbers above, you will see that the C library for `sum_range` is faster than 
the numpy computation but significantly slower than the `numba.jit` decorated function.


> ## Challenge: Check if the Numba version of this conditional `sum range` function outperforms its C counterpart:
>  
> Insprired by [a blog by Christopher Swenson](http://caswenson.com/2009_06_13_bypassing_the_python_gil_with_ctypes.html).
>
> ~~~C
> long long conditional_sum_range(long long to)
> {
>   long long i;
>   long long s = 0LL;
> 
>   for (i = 0LL; i < to; i++)
>     if (i % 3 == 0)
>       s += i;
> 
>   return s;
> }
> ~~~
> {: .source}
> > ## Solution
> > Just insert a line `if i%3==0:` in the code for `sum_range_numba` and rename it to `conditional_sum_range_numba`.
> > ~~~python
> > @numba.jit
> > def conditional_sum_range_numba(a: int):
> >     x = 0
> >     for i in range(a):
> >         if i%3==0:
> >             x += i
> >     return x
> > ~~~
> >
> > Let's check how fast it runs.
> > 
> > ~~~
> > %timeit conditional_sum_range_numba(10**7)
> > ~~~
> > ~~~
> > 8.11 ms ± 15.6 µs per loop (mean ± std. dev. of 7 runs, 100 loops each)
> > ~~~
> >
> > Compare this with the run time for the C code for conditional_sum_range.
> > Compile and link in the usual way, assuming the file name is still `test.c`:
> > ~~~bash
> > gcc -O3 -g -fPIC -c -o test.o test.c
> > ld -shared -o libtest.so test.o
> > ~~~
> > {: .source}
> > 
> > Again, we can time our compiled `conditional_sum_range` C library, e.g. from the iPython interface:
> > ~~~python
> > import ctypes
> > testlib = ctypes.cdll.LoadLibrary("./libtest.so")
> > conditional_sum_range = testlib.conditional_sum_range
> > conditional_sum_range.argtypes = [ctypes.c_longlong]
> > conditional_sum_range.restype = ctypes.c_longlong 
> > %timeit conditional_sum_range(10**7)
> > ~~~
> > ~~~
> > 7.62 ms ± 49.7 µs per loop (mean ± std. dev. of 7 runs, 100 loops each)
> > ~~~
> > This shows that for this slightly more complicated example the C code is somewhat faster than the Numba decorated Python code.
> >
> > {: .output}
> {: .solution}
{: .challenge}


# The `threading` module
We will now parallelise the computation of pi using the `threading` module that is built into
Python.

We now build a queue/worker model. This is the basis of multi-threading applications in Python. At
this point creating a parallel program is quite involved. After we've done this, we'll see ways to
do the same in Dask without mucking about with threads directly.

On the one hand we have a `Queue` to which we push work units. On the other hand we have any number
of *workers* that pull jobs from the queue. More workers should get the job done in less time!

~~~python
import queue
import threading

### We need to define a worker function that fetches jobs from the queue.
def worker(q):
    while True:
        try:
            x = q.get(block=False)
            print(calc_pi_numba(x), end=' ', flush=True)
        except queue.Empty:
            break

### Create the queue, and fill it with input values
work_queue = queue.Queue()
for i in input_range:
    work_queue.put(i)

### Start a number of threads
threads = [
    threading.Thread(target=worker, args=(work_queue,))
    for i in range(ncpus)]

for t in threads:
    t.start()

### Wait until all of them are done
for t in threads:
    t.join()

print()
~~~

> ## Discussion: where's the speed-up?
> While mileage may vary, parallelizing `calc_pi`, `calc_pi_numpy` and `calc_pi_numba` this way will
> not give the expected speed-up. `calc_pi_numba` should give *some* speed-up, but nowhere near the
> ideal scaling over the number of cores. This is because Python only allows one thread to access the
> interperter at any given time, a feature also known as the Global Interpreter Lock.
{: .discussion}


# A few words about the Global Interpreter Lock
The Global Interpreter Lock (GIL) is an infamous feature of the Python interpreter.
It both guarantees inner thread sanity, making programming in Python safer, and prevents us from using multiple cores from
a single Python instance.
There are roughly two classes of solutions to circumvent/lift the GIL:

- Run multiple Python instances: `multiprocessing`
- Have important code outside Python: OS operations, C++ extensions, cython, numba

The downside of running multiple Python instances is that we need to share program state between different processes.
To this end, you need to serialize objects using `pickle`, `json` or similar, creating a large overhead.
The alternative is to bring parts of our code outside Python.
Numpy has many routines that are largely situated outside of the GIL.
The only way to know for sure is trying out and profiling your application.

To write your own routines that do not live under the GIL there are several options: fortunately `numba` makes this very easy.

~~~python
@numba.jit(nopython=True, nogil=True)
def calc_pi_numba(N):
    M = 0
    for i in range(N):
        x = random.uniform(-1, 1)
        y = random.uniform(-1, 1)

        if x**2 + y**2 < 1.0:
            M += 1
    return 4 * M / N
~~~
{: .source}

The `nopython` argument forces Numba to compile the code without referencing any Python objects,
while the `nogil` argument enables lifting the GIL during the execution of the function.

> ## Challenge: profile the fixed program
> The nogil version of `calc_pi_numba` should scale nicely with the number of cores used.
{: .challenge}

