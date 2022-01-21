---
title: "Dask abstractions: delays and bags"
teaching: 60
exercises: 30
questions:
- "What abstractions does Dask offer?"
- "What programming patterns exist in the parallel universe?"
objectives:
- "Recognize `map`, `filter` and `reduce` patterns"
- "Create programs using these building blocks"
- "Use the `visualize` method to create dependency graphs"
- "Understand the abstraction of delayed evaluation"
keypoints:
- "Use abstractions to keep programs manageable"
---

[Dask](https://dask.org/) is one of the many tools available for parallelizing Python code in a comfortable way.
We've seen a basic example of `dask.array` in a previous episode.
Now, we will focus on the `delayed` and `bag` sub-modules.
Dask has a lot of other useful components, such as `dataframe` and `futures`, but we are not going to cover them in this lesson.

See an overview below:

| Dask module      | Abstraction          | Keywords                            | Covered |
|:-----------------|:---------------------|:------------------------------------|:--------|
| `dask.array`     | `numpy`              | Numerical analysis                  | ✔️       |
| `dask.bag`       | `itertools`          | Map-reduce, workflows               | ✔️       |
| `dask.delayed`   | functions            | Anything that doesn't fit the above | ✔️       |
| `dask.dataframe` | `pandas`             | Generic data analysis               | ❌      |
| `dask.futures`   | `concurrent.futures` | Control execution, low-level        | ❌      |

# Dask Delayed
A lot of the functionality in Dask is based on top of a framework of *delayed evaluation*. The concept of delayed evaluation is very important in understanding how Dask functions, which is why we will go a bit deeper into `dask.delayed`.

~~~python
from dask import delayed
~~~
{: .source}

The `delayed` decorator builds a dependency graph from function calls.

~~~python
@delayed
def add(a, b):
    result = a + b
    print(f"{a} + {b} = {result}")
    return a + b
~~~
{: .source}

A `delayed` function stores the requested function call inside a **promise**. The function is not actually executed yet, instead we
are *promised* a value that can be computed later.

~~~python
x_p = add(1, 2)
~~~
{: .source}

We can check that `x_p` is now a `Delayed` value.

~~~python
type(x_p)
~~~
{: .source}
~~~
[out]: dask.delayed.Delayed
~~~
{: .output}

> ## Note
> It is often a good idea to suffix variables that you know are promises with `_p`. That way you
> keep track of promises versus immediate values.
{: .callout}

Only when we evaluate the computation, do we get an output.

~~~python
x_p.compute()
~~~
{:.source}
~~~
1 + 2 = 3
[out]: 3
~~~
{:.output}

From `Delayed` values we can create larger workflows and visualize them.

~~~python
x_p = add(1, 2)
y_p = add(x_p, 3)
z_p = add(x_p, y_p)
z_p.visualize(rankdir="LR")
~~~
{: .source}

![Dask workflow graph](../fig/dask-workflow-example.svg)
{: .output}

> ## Challenge: run the workflow
> Given this workflow:
> ~~~python
> x_p = add(1, 2)
> y_p = add(x_p, 3)
> z_p = add(x_p, -3)
> ~~~
> Visualize and compute `y_p` and `z_p`, how often is `x_p` evaluated?
> Now change the workflow:
> ~~~python
> x_p = add(1, 2)
> y_p = add(x_p, 3)
> z_p = add(x_p, y_p)
> z_p.visualize(rankdir="LR")
> ~~~
> We pass the yet uncomputed promise `x_p` to both `y_p` and `z_p`. How often do you expect `x_p` to be evaluated? Run the workflow to check your answer.
> > ## Solution
> > ~~~python
> > z_p.compute()
> > ~~~
> > {: .source}
> > ~~~
> > 1 + 2 = 3
> > 3 + 3 = 6
> > 3 + 6 = 9
> > [out]: 9
> > ~~~
> > {: .output}
> > The computation of `x_p` (1 + 2) appears only once.
> {: .solution}
{: .challenge}

We can also make a promise by directly calling `delayed`

~~~python
N = 10**7
x_p = delayed(calc_pi)(N)
~~~
{: .source}

It is now possible to call `visualize` or `compute` methods on `x_p`.

> ## Variadic arguments
> In Python you can define functions that take arbitrary number of arguments:
>
> ```python
> def add(*args):
>  return sum(args)
>
> add(1, 2, 3, 4)   # => 10
> ```
>
> You can use tuple-unpacking to pass a sequence of arguments:
>
> ```python
> numbers = [1, 2, 3, 4]
> add(*numbers)   # => 10
> ```
{: .callout}

We can build new primitives from the ground up.

~~~python
@delayed
def gather(*args):
    return list(args)
~~~
{: .source}

> ## Challenge: understand `gather`
> Can you describe what the `gather` function does in terms of lists and promises?
> > ## Solution
> > It turns a list of promises into a promise of a list.
> {: .solution}
{: .challenge}

We can visualize what `gather` does by this small example.

~~~python
x_p = gather(*(add(n, n) for n in range(10))) # Shorthand for gather(add(1, 1), add(2, 2), ...)
x_p.visualize()
~~~
{: .source}

![a gather pattern](../fig/dask-gather-example.svg)
{: .output}

Computing the result,

~~~python
x_p.compute()
~~~
{: .source}
~~~
[out]: [0, 1, 4, 9, 16, 25, 36, 49, 64, 81]
~~~
{: .output}

> ## Challenge: design a `mean` function and calculate pi
> Write a `delayed` function that computes the mean of its arguments. Use it to esimates pi several times and returns the mean of the results.
>
> ```python
> >>> mean(1, 2, 3, 4).compute()
> 2.5
> ```
>
> Make sure that the entire computation is contained in a single promise.
> > ## Solution
> > ~~~python
> > from dask import delayed
> > import random
> >
> > @delayed
> > def mean(*args):
> >     return sum(args) / len(args)
> >
> > def calc_pi(N):
> >     """Computes the value of pi using N random samples."""
> >     M = 0
> >     for i in range(N):
> >         # take a sample
> >         x = random.uniform(-1, 1)
> >         y = random.uniform(-1, 1)
> >         if x*x + y*y < 1.: M+=1
> >     return 4 * M / N
> >
> >
> > N = 10**6
> > pi_p = mean(*(delayed(calc_pi)(N) for i in range(10)))
> > pi_p.compute()
> > ~~~
> > {: .source}
> {: .solution}
{: .challenge}

You may not seed a significant speedup. This is because `dask delayed` uses threads by default and our native Python implementation
of `calc_pi` does not circumvent the GIL. With for example the numba version of `calc_pi` you should see a more significant speedup.

In practice you may not need to use `@delayed` functions too often, but it does offer ultimate
flexibility. You can build complex computational workflows in this manner, sometimes replacing shell
scripting, make files and the likes.

# Parallelize using Dask bags
Dask bags let you compose functionality using several primitive patterns: the most important of these are `map`, `filter`, `groupby` and `reduce`.

> ## Discussion
> Open the [Dask documentation on bags](https://docs.dask.org/en/latest/bag-api.html).
> Discuss the `map` and `filter` and `reduction` methods
{: .discussion}

Operations on this level can be distinguished in several categories:

- **map** (N to N) applies a function *one-to-one* on a list of arguments. This operation is **embarrassingly
  parallel**.
- **filter** (N to &lt;N) selects a subset from the data.
- **groupby** (N to &lt;N) groups data in subcategories.
- **reduce** (N to 1) computes an aggregate from a sequence of data; if the operation permits it
  (summing, maximizing, etc) this can be done in parallel by reducing chunks of data and then
  further processing the results of those chunks.

Let's see an example of it in action:

First, let's create the `bag` containing the elements we want to work with (in this case, the numbers from 0 to 5).

~~~python
import dask.bag as db

bag = db.from_sequence(['mary', 'had', 'a', 'little', 'lamb'])
~~~
{: .source}

### Map

To illustrate the concept of `map`, we'll need a mapping function.
In the example below we'll just use a function that capitalizes its argument:

~~~python
# Create a function for mapping
def f(x):
    return x.upper()

# Create the map and compute it
bag.map(f).compute()
~~~
{: .source}
~~~
out: ['MARY', 'HAD', 'A', 'LITTLE', 'LAMB']
~~~
{:.output}

We can also visualize the mapping:

~~~python
# Visualize the map
bag.map(f).visualize()
~~~
{: .source}
![A map operation.](../fig/dask-bag-map.svg)
{: .output}

### Filter

To illustrate the concept of `filter`, it is useful to have a function that returns a boolean.
In this case, we'll use a function that returns `True` if the argument contains the letter 'a',
and `False` if it doesn't.

~~~python
# Return True if the character 'a' is in x, False if not
def pred(x):
    return 'a' in x

bag.filter(pred).compute()
~~~
{: .source}
~~~
[out]: ['mary', 'had', 'a', 'lamb']
~~~
{: .output}

> ## Difference between `filter` and `map`
> Without executing it, try to forecast what would be the output of `bag.map(pred).compute()`.
> > ## Solution
> > The output will be `[True, True, True, False, True]`.
> {: .solution}
{: .challenge}

### Reduction

~~~python
def count_chars(x):
    per_word = [len(w) for w in x]

    return sum(per_word)

bag.reduction(count_chars, sum).visualize()
~~~
{: .source}
![A reduction.](../fig/dask-bag-reduction.svg)
{: .output}

> ## Challenge
> Look at the `mean`, `pluck`, `distinct` methods. These functions could be implemented by using more generic functions that also are in the `dask.bags` library: `map`, `filter`, and `reduce` methods. Can you recognize the design pattern from the descriptions in the documentation?
> > ## Solution
> > `mean` is a reduction, `pluck` is a mapping. 
> {: .solution}
{: .challenge}

> ## Challenge
> Rewrite the following program in terms of a Dask bag. 
> 
> The program processes a text, and counts the number of unique words.
> A text is tokenized by splitting the text on spaces.
> Punctuation is removed, and tokens containing numbers are ignored.
> Finally, we use a stemmer from the NLTK library to map tokens to a standard form.
> This way the tokens 'Books' and 'Book', and the tokens 'Reading' and 'Read' are counted as a single word ('Book' and 'Read', respectively).
> 
> Make it spicy by using your favourite literature classic from project Gutenberg as input.
> Reccomendations:
> - Mapes Dodge - https://www.gutenberg.org/files/764/764-0.txt
> - Melville - https://www.gutenberg.org/files/15/15-0.txt
> - Conan Doyle - https://www.gutenberg.org/files/1661/1661-0.txt
> - Shelley - https://www.gutenberg.org/files/84/84-0.txt
> - Stoker - https://www.gutenberg.org/files/345/345-0.txt
> - E. Bronte - https://www.gutenberg.org/files/768/768-0.txt
> - Austen - https://www.gutenberg.org/files/1342/1342-0.txt
> - Carroll - https://www.gutenberg.org/files/11/11-0.txt
> - Christie - https://www.gutenberg.org/files/61262/61262-0.txt
>
>
>
> ~~~python
> from nltk.stem.snowball import PorterStemmer
> import requests
> stemmer = PorterStemmer()
>
> def isWord(token):
>     """Is the token a valid word?"""
>     return len(token) > 0 and not any(i.isdigit() for i in token)
>
> def preprocess(token):
>     """Strip punctuation characters and lowercase the token."""
>     return token.strip("*!?.:;'\",“’‘”()_").lower()
>
> def load_url(url):
>    response = requests.get(url)
>    return response.text
> ~~~
> {: .source}
>
> ~~~python
> text = "Lorem ipsum"
> words = set()
> for w in text.split():
>     cw = preprocess(w)
>     if isWord(cw):
>         words.add(stemmer.stem(cw))
> print(f"This corpus contains {len(words)} unique words.")
> ~~~
> {: .source}
>
> Tip: start by just counting all the words in the corpus, then expand from there.
> Tip: a "better"/different version of this program would be
>
> ~~~python
> words = set(map(stemmer.stem,
>                 filter(isWord,
>                        map(preprocess, text.split()))))
> len(words)
> ~~~
> {: .source}
>
> All urls in a python list for convenience:
> ```python=
> [
> 'https://www.gutenberg.org/files/764/764-0.txt',
> 'https://www.gutenberg.org/files/15/15-0.txt',
> 'https://www.gutenberg.org/files/1661/1661-0.txt',
> 'https://www.gutenberg.org/files/84/84-0.txt',
> 'https://www.gutenberg.org/files/345/345-0.txt',
> 'https://www.gutenberg.org/files/768/768-0.txt',
> 'https://www.gutenberg.org/files/1342/1342-0.txt',
> 'https://www.gutenberg.org/files/11/11-0.txt',
> 'https://www.gutenberg.org/files/61262/61262-0.txt'
> ]
>```
> > ## Solution
> > Load the list of books as a bag with `db.from_sequence`, load the books by using `map` in
> > combination with the `load_url` function. Split the text and `flatten` to create a
> > single bag of tokens, then `map` to preprocess. Filter to get only the words, and map again 
> > to get the stems. To split the words, use `group_by` and finaly `count` to reduce to the number of
> > words. Other option `distinct`.
> >
> > ~~~python
> >
> > words = db.from_sequence(books)\
> >          .map(load_url)\
> >          .str.split(' ')\
> >          .flatten()\
> >          .map(preprocess)\
> >          .filter(isWord)\
> >          .map(stemmer.stem)\
> >          .distinct()\
> >          .count()\
> >          .compute()
> >
> > print(f'This collection of books contains {words} unique words')
> > ```
> >
> > ~~~
> > {: .source}
> {: .solution}
{: .challenge}

> ## Challenge: Dask version of Pi estimation
> > ## Solution
> > ~~~python
> > import dask.bag
> > from numpy import repeat
> > import random
> >
> > def calc_pi(N):
> >     """Computes the value of pi using N random samples."""
> >     M = 0
> >     for i in range(N):
> >         # take a sample
> >         x = random.uniform(-1, 1)
> >         y = random.uniform(-1, 1)
> >         if x*x + y*y < 1.: M+=1
> >     return 4 * M / N
> >
> > bag = dask.bag.from_sequence(repeat(10**7, 24))
> > shots = bag.map(calc_pi)
> > estimate = shots.mean()
> > estimate.compute()
> > ~~~
> > {: .source}
> {: .solution}
{: .challenge}

> ## Note
> By default Dask runs a bag using multi-processing. This alleviates problems with the GIL, but also means a larger overhead.
{: .callout}



{% include links.md %}
