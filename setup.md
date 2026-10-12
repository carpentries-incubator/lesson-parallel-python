---
title: Setup
---

This is an intermediate level Python course.
We expect familiarity with the command-line, and that you are comfortable
working with a coding text editor (like for instance,
[VS Code](https://code.visualstudio.com/)).

### Data Sets

The course uses the following data sets:

- New York taxi data ([description](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page)).

The instructions below include downloading the data.


## Software and Data Setup

Clone the repository at [esciencecenter-digital-skills/parallel-python-workshop](https://github.com/esciencecenter-digital-skills/parallel-python-workshop).

Follow software setup instructions there to set up the environment, download the data,
and run the unit tests to see if your setup is working.

::::::::::::::::::::::::::::::::::::::: discussion

### Details
We provide two choices for working environment: **uv** or **conda**.
If you are on **Windows** the preferred method is **conda**. On Linux or
MacOS you should be fine with either.

:::::::::::::::::::::::::::::::::::::::::::::::::::

:::solution
### UV

UV is our recommended tool to manage the Python environment.
Please follow the [UV install instructions](https://docs.astral.sh/uv/#installation)
if you haven't already. Then, running from the directory where you cloned this
repository, run the following command:

```bash
uv sync
```

Then, download the New York taxi dataset:
```
uv run ny-taxi/download.py
```

Finally, run `pytest` and see if it completes all tests without errors.
```
uv run pytest
```

:::

:::solution
### Conda
From within the cloned repository root directory, run the following commands to create a `conda` environment from the environment.yml file and activate it
```bash
$ conda env create -f environment.yml
$ conda activate parallel-python
```

Now, download the New York taxi data set:
```bash
$ python ny-taxi/download.py
```

Finally, run `pytest` and see if it completes all tests without errors.

```bash
$ pytest
```

:::

