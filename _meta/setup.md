### Requirements

- A programming editor, in doubt we recommend [Microsoft VS Code](https://code.visualstudio.com/).
- Python version 3.9, we recommend [Anaconda](https://www.anaconda.com/products/individual) or
  [Miniconda](https://docs.conda.io/en/latest/miniconda.html) if you only use the command-line
interface. If you insist on using vanilla Python, see instructions below.
- Git. If you're on Windows, follow these instructions: [Git for Windows](https://carpentries.github.io/workshop-template/#shell).

To follow along with the workshop, you need to prepare an environment. Clone the workshop repository
that we prepared:

```bash
git clone https://github.com/esciencecenter-digital-skills/parallel-python-workshop.git
```

You may prepare the environment either in `conda` or using vanilla Python with `poetry`.

#### Conda (recommended)

```bash
conda env create -f environment.yml
conda activate parallel-python
pytest
```

#### Poetry

```bash
pip install --user poetry
poetry install
poetry run pytest
```

