---
title: Setup
tools-needed:
  - editor
  - python
  - jupyterlab
---

For Windows users:
Install git for windows following: [Git for Windows](https://carpentries.github.io/workshop-template/#shell).
Install Anaconda following: [Python](https://carpentries.github.io/workshop-template/#shell).

Use anaconda to install the following modules:

~~~bash
conda install -y dask[complete]
conda install -y memory_profiler
conda install -y matplotlib
conda install -y numba
conda install -y python-graphviz
conda install -y nltk
conda install -y jupyterlab
~~~

FIXME: how to add `snakemake`?  It's in `bioconda`.  Options:
- add bioconda as a low priority channel: `conda config --append channels bioconda`
- use pip for snakemake

FIXME: should pip/poetry be mentioned as an alternative?

{% include links.md %}
