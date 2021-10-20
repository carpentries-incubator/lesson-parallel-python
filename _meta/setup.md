### Using Conda (recommended)
Install git for windows following: [Git for Windows](https://carpentries.github.io/workshop-template/#shell).
Install Anaconda following: [Python](https://carpentries.github.io/workshop-template/#shell).

Use anaconda to install the following modules:

```bash
conda create -n parallel-python
conda activate parallel-python
conda install -y dask memory_profiler matplotlib numba \
                 graphviz nltk jupyterlab numpy pandas \
                 snakemake
jupyter lab
```

### On Linux or Mac, using native Python and Poetry
Install Git, Python 3.9, and Graphviz using your package manager.

```bash
# make sure you have poetry installed
pip install --user poetry
# create a workspace
mkdir -p parallel-python
cd parallel-python
# initialize a new environment
poetry init -n --python 3.9
poetry add dask memory_profiler matplotlib numba \
           graphviz nltk jupyterlab numpy^1.20 pandas \
           snakemake
# run jupyter
poetry shell
jupyter lab
```

### Exercises
The larger exercises may have additional requirements.

