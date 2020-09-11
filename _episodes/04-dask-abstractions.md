---
title: "Dask abstractions: bags and delays"
teaching: 60
exercises: 30
questions:
- "What abstractions does Dask offer?"
- "What programming patterns exist in the parallel universe?"
objectives:
- "Recognize `map`, `filter` and `reduce` patterns."
- "Create programs using these building blocks."
- "Use the `visualize` method to create dependency graphs."
- "Understand the abstraction of delayed evaluation."
keypoints:
- "Using abstractions keep programs manageable."
---

We've seen some use of Dask `array`, now we will also dive into `bag` and `delayed` sub-modules.
(Dask also has Pandas-like `dataframe` and an advanced `futures` framework; `dataframe` is similar
in character to `array`, while `futures` fall outside the scope of this tutorial.)

# Parallelize using Dask bags
We can run the Numba version of `comp_pi` in parallel using Dask bags.

> ## Discussion
> Open the Dask documentation on bags: https://docs.dask.org/en/latest/bag-api.html
> Discuss the `map` and `filter` and `reduction` methods
{: .discussion}

Operations on this level can be distinguished in several categories

- **map** (N to N) applies a function *one-to-one* on a list of arguments. This operation is **embarrassingly
  parallel**.
- **filter** (N to <N) selects a subset from the data.
- **reduce** (N to 1) computes an aggregate from a sequence of data; if the operation permits it
  (summing, maximizing, etc) this can be done in parallel by reducing chunks of data and then
  further processing the results of those chunks.

~~~python
import dask.bag

def f(x):
    return x**2

bag = dask.bag.from_sequence(range(6))
bag.map(f).visualize()
~~~
{: .source}

~~~python
def pred(x):
    return x % 2 == 0

bag.filter(pred).visualize()
~~~
{: .source}

~~~python
bag.reduction(sum, sum).visualize()
~~~
{: .source}

> ## Challenge
> Look at the `mean`, `pluck`, and `topk` methods, match them up with `map`, `filter` and
> `reduction` methods.
> > ## Solution
> > `mean` is a reduction, `pluck` is a mapping, and `topk` is a filter.
> {: .solution}
{: .challenge}

> ## Challenge
> Rewrite the following program in terms of a Dask bag. Make it
> spicy by using your favourite literature classic from project Gutenberg as input.
> Example: Adventures of Sherlock Holmes, https://www.gutenberg.org/files/1661/1661-0.txt
>
> ~~~python
> from nltk.stem.snowball import PorterStemmer
> stemmer = PorterStemmer()
>
> def good_word(w):
>     return len(w) > 0 and not any(i.isdigit() for i in w)
>
> def clean_word(w):
>     return w.strip("*!?.:;'\",“’‘”()_").lower()
> ~~~
> {: .source}
>
> ~~~python
> text = "Lorem ipsum"
> words = set()
> for w in text.split():
>     cw = clean_word(w)
>     if good_word(cw):
>         words.insert(stemmer.stem(w))
> print("This corpus contains {n} unique words.".format(n=len(words)))
> ~~~
> {: .source}
>
> Tip: start by just counting all the words in the corpus, then expand from there.
> Tip: a better version of this program would be
>
> ~~~python
> words = set(map(stemmer.stem, filter(good_word, map(clean_word, text.split()))))
> len(words)
> ~~~
> {: .source}
>
> > ## Solution
> > Use `read_text` to read the text efficiently, split the words and `flatten` to create a
> > single bag, then `map` to capitalize all the words (or find their stems).
> > To split the words, use `group_by` and finaly `count` to reduce to the number of
> > words. Other option `distinct`.
> >
> > ~~~python
> > bag = db.read_text("./1661-0.txt", blocksize="32k")
> > raw_words = bag.str.split().flatten()
> > clean_words = raw_words.map(clean_word).filter(good_word)
> > stems = clean_words.map(stemmer.stem)
> > unique_words = stems.distinct().count()
> > unique_words.compute(scheduler="processes", num_workers=4)
> > ~~~
> >
> > FIXME: I have yet to find a corpus large enough that this becomes more efficient than the native python
> > version.
> > {: .source}
> {: .solution}
{: .challenge}

> ## Challenge: Dask version of Pi estimation
> > ## Solution
> > ~~~python
> > import dask.bag
> > bag = dask.bag.from_sequence(repeat(10**7, 24))
> > shots = bag.map(calc_pi)
> > estimate = shots.mean()
> > estimate.visualize()
> > estimate.compute()
> > ~~~
> > {: .source}
> {: .solution}
{: .challenge}

FIXME: profile this program

# Dask Delayed
FIXME: add output

We can rewrite the same program using `dask.delayed`

~~~python
from dask import delayed
~~~
{: .source}

The `delayed` decorator builds a dependency graph from function calls.

~~~python
@delayed
def add(a, b):
    return a + b
~~~
{: .source}

~~~python
x_p = add(1, 2)
y_p = add(x, 3)
z_p = add(x_p, y_p)
z_p.visualize()
~~~
{: .source}

> ## Note
> It is often a good idea to suffix variables that you know are promises with `_p`. That way you
> keep track of promises versus immediate values.
{: .callout}

We can also make a **promise** by directly calling `delayed`

~~~python
N = 10**7
x_p = delayed(calc_pi)(N)
~~~
{: .source}

It is now possible to call `visualize` or `compute` methods on `x_p`.

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

> ## Challenge: design a `mean` function
> Write a `delayed` function that computes the mean of its arguments. Complete the program to
> compute pi in parallel.
>
> > ## Solution
> > ~~~python
> > @delayed
> > def mean(*args):
> >     return sum(args) / len(args)
> >
> > pi_p = mean(*(delayed(calc_pi)(N) for i in range(10)))
> > pi_p.compute()
> > ~~~
> > {: .source}
> {: .solution}
{: .challenge}

In practice you may not need to use `@delayed` functions too often, but it does offer ultimate
flexibility. You can build complex computational workflows in this manner, replacing shell
scripting, make files and the likes.

{% include links.md %}

