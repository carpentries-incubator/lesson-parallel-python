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
cd parallel-python-workshop
```

You may prepare the environment either in `conda` or using vanilla Python with `poetry`.

#### Conda (recommended)
For most users we recommend that you use `conda` to install the requirements for the workshop.

```bash
conda env create -f environment.yml
conda activate parallel-python
pytest
```

If the tests pass, you're all good! Otherwise, please contact us before the workshop.

#### Poetry
Only follow these instructions if you're on Linux or Mac and don't have `conda` installed. Make sure
that you have Python 3.9 installed.

If you've never used `poetry` before, [check it out!](https://python-poetry.org/)

```
curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/install-poetry.py | python -
```

Then, making sure that you're still inside the `parallel-python-workshop` directory:

```bash
poetry install
poetry shell
pytest
```

If the tests pass, you're all good! Otherwise, please contact us before the workshop.
