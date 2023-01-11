---
title: "Calling external C and C++ libraries from Python"
teaching: 60
exercises: 30
---

:::questions
- What are some of my options in calling C and C++ libraries from Python code?
- How does this work together with Numpy arrays?
- How do I use this in multiple threads while lifting the GIL?
:::

:::objectives
- Compile and link simple C programs into shared libraries.
- Call these library from Python and time its executions.
- Compare the performance with Numba decorated Python code.
- Bypass the GIL when calling these libraries from multiple threads simultaneously.
:::

# Calling C and C++ libraries
## Simple example using either pybind11 or ctypes
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

You can easily compile and link it into a shared object (.so) file. First you need pybind11. You can install it in
a number of ways, like pip, but I prefer creating virtual environments using pipenv.

~~~bash
pip install pipenv
pipenv install pybind11
pipenv shell

c++ -O3 -Wall -shared -std=c++11 -fPIC `python3 -m pybind11 --includes` test.c -o test_pybind.so
~~~

which generates a `test_pybind.so` shared object which you can call from a iPython shell, like this:

~~~python
%import test_pybind
%sum_range=test_pybind.sum_range
%high=1000000000
%brute_force_sum=sum_range(high)
~~~

Now you might want to check the output, by comparing with the well-known formula for the sum of consecutive integers.
~~~python
%sum_from_formula=high*(high-1)//2
%sum_from_formula
%difference=sum_from_formula-brute_force_sum
%difference
~~~

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

Compile and link using
~~~bash
gcc -O3 -g -fPIC -c -o test.o test.c
ld -shared -o libtest.so test.o
~~~

which generates a libtest.so file.

You will need some extra boilerplate:

~~~python
%import ctypes
%testlib = ctypes.cdll.LoadLibrary("./libtest.so")
%sum_range = testlib.sum_range
%sum_range.argtypes = [ctypes.c_longlong]
%sum_range.restype = ctypes.c_longlong
%high=1000000000
%brute_force_sum=sum_range(high)
~~~

Again, you can compare with the formula for the sum of consecutive integers.
~~~python
%sum_from_formula=high*(high-1)/2
%sum_from_formula
%difference=sum_from_formula-brute_force_sum
%difference
~~~

## Performance
Now we can time our compiled `sum_range` C library, e.g. from the iPython interface:
~~~python
%timeit sum_range(10**7)
~~~

~~~output
2.69 ms ± 6.01 µs per loop (mean ± std. dev. of 7 runs, 100 loops each)
~~~

If you compare with the Numba timing from [chapter 3](computing-pi.md), you will see that the C library for `sum_range` is faster than
the numpy computation but significantly slower than the `numba.jit` decorated function.

:::challenge
## C versus Numba
Check if the Numba version of this conditional `sum range` function outperforms its C counterpart.

Insprired by [a blog by Christopher Swenson](https://caswenson.com/2009_06_13_bypassing_the_python_gil_with_ctypes.html).

~~~c
long long conditional_sum_range(long long to)
{
  long long i;
  long long s = 0LL;

  for (i = 0LL; i < to; i++)
    if (i % 3 == 0)
      s += i;

  return s;
}
~~~

::::solution
## Solution
Insert a line `if i%3==0:` in the code for `sum_range_numba` and rename it to `conditional_sum_range_numba`.

~~~python
@numba.jit
def conditional_sum_range_numba(a: int):
    x = 0
    for i in range(a):
        if i%3==0:
            x += i
    return x
~~~

Let's check how fast it runs.

~~~
%timeit conditional_sum_range_numba(10**7)
~~~

~~~output
8.11 ms ± 15.6 µs per loop (mean ± std. dev. of 7 runs, 100 loops each)
~~~

Compare this with the run time for the C code for conditional_sum_range.
Compile and link in the usual way, assuming the file name is still `test.c`:

~~~bash
gcc -O3 -g -fPIC -c -o test.o test.c
ld -shared -o libtest.so test.o
~~~

Again, we can time our compiled `conditional_sum_range` C library, e.g. from the iPython interface:

~~~python
import ctypes
testlib = ctypes.cdll.LoadLibrary("./libtest.so")
conditional_sum_range = testlib.conditional_sum_range
conditional_sum_range.argtypes = [ctypes.c_longlong]
conditional_sum_range.restype = ctypes.c_longlong
%timeit conditional_sum_range(10**7)
~~~

~~~output
7.62 ms ± 49.7 µs per loop (mean ± std. dev. of 7 runs, 100 loops each)
~~~

This shows that for this slightly more complicated example the C code is somewhat faster than the Numba decorated Python code.
::::
:::

## Passing Numpy arrays to C libraries.
Now let us consider a more complex example. Instead of computing the sum of numbers up to a certain upper limit, let us
compute that for an array of upper limits. This will return an array of sums. How difficult is it to modify our C and Python code
to get this done? Well, you just need to replace `&sum_range` by `py::vectorize(sum_range)`:

~~~c
PYBIND11_MODULE(test_pybind, m) {
    m.doc() = "pybind11 example plugin"; // optional module docstring

    m.def("sum_range", py::vectorize(sum_range), "Adds upp consecutive integer numbers from 0 up to and including high-1");
}
~~~

Now let's see what happens if we pass `test_pybind.so` an array instead of an integer.

~~~python
%import test_pybind
%sum_range=test_pybind.sum_range
%ys=range(10)
%sum_range(ys)
~~~

gives

~~~output
array([ 0,  0,  1,  3,  6, 10, 15, 21, 28, 36])
~~~

It does not crash! Instead, it returns an array which you can check to be correct by subtracting the previous sum from each sum (except the first):

~~~python
%out=sum_range(ys)
%out[1:]-out[:-1]
~~~

which gives

~~~output
array([0, 1, 2, 3, 4, 5, 6, 7, 8])
~~~

the elements of `ys` - except the last -  as you would expect.

# Call the C library from multiple threads simultaneously.
We can quickly show you how the C library compiled using pybind11 can be run multithreaded. try the following from an iPython shell:

~~~python
%high=int(1e9)
%timeit(sum_range(high))
~~~

~~~output
274 ms ± 1.03 ms per loop (mean ± std. dev. of 7 runs, 1 loop each)
~~~

Now try a straightforward parallellisation of 20 calls of `sum_range`, over two threads, so 10 calls per thread.
This should take about ```10 * 274ms = 2.74s``` if parallellisation were running without overhead. Let's try:

~~~python
import threading as T
import time
def timer():
    start_time = time.time()
    for x in range(10):
        t1 = T.Thread(target=sum_range, args=(high,))
        t2 = T.Thread(target=sum_range, args=(high,))
        t1.start()
        t2.start()
        t1.join()
        t2.join()
    end_time = time.time()
    print(f"Time elapsed = {end_time-start_time:.2f}s")
timer()
~~~

This gives

~~~
Time elapsed = 5.59s
~~~

i.e. more than twice the time we would expect. What actually happened is that `sum_range` was run sequentially instead of parallelly.
We need to add a single declaration to test.c: `py::call_guard<py::gil_scoped_release>()`:

~~~c
PYBIND11_MODULE(test_pybind, m) {
    m.doc() = "pybind11 example plugin"; // optional module docstring

    m.def("sum_range", py::vectorize(sum_range), "Adds upp consecutive integer numbers from 0 up to and including high-1");
}
~~~

like this:

~~~c
PYBIND11_MODULE(test_pybind, m) {
    m.doc() = "pybind11 example plugin"; // optional module docstring

    m.def("sum_range", &sum_range, "A function which adds upp numbers from 0 up to and including high-1", py::call_guard<py::gil_scoped_release>());
}
~~~

Now compile again:

~~~bash
c++ -O3 -Wall -shared -std=c++11 -fPIC `python3 -m pybind11 --includes` test.c -o test_pybind.so
~~~

Reimport the rebuilt shared object - this can only be done by quitting and relaunching the iPython interpreter - and time again.

~~~python
import test_pybind
import time
import threading as T

sum_range=test_pybind.sum_range
high=int(1e9)

def timer():
    start_time = time.time()
    for x in range(10):
        t1 = T.Thread(target=sum_range, args=(high,))
        t2 = T.Thread(target=sum_range, args=(high,))
        t1.start()
        t2.start()
        t1.join()
        t2.join()
    end_time = time.time()
    print(f"Time elapsed = {end_time-start_time:.2f}s")
timer()
~~~

This gives:

~~~output
Time elapsed = 2.81s
~~~

as you would expect for two `sum_range` modules running in parallel.

:::keypoints
- Multiple options are available in calling external C and C++ libraries and that the best choice can depend on the complexity of your problem.
- Obviously, there is an extra compile and link step, but you will get a much faster execution compared to pure Python.
- Also, the GIL will be circumvented in calling these libaries.
- Numba might also offer you the speedup you want with even less effort.
:::

