---
title: Setup
---

Setup instructions live in this document. Please specify the tools and the data
sets the Learner needs to have installed.

## Data Sets

Clone the repository at [esciencecenter-digital-skills/parallel-python-workshop](https://github.com/esciencecenter-digital-skills/parallel-python-workshop). Follow software setup instructions there to setup the environment, and run the unit tests to see if your setup is working.

## Software Setup

::::::::::::::::::::::::::::::::::::::: discussion

### Details
This is an intermediate level Python course. We expect familiarity with the command-line, and that you are comfortable working with a coding text editor (like for instance, [VS Code](https://code.visualstudio.com/)). We provide two choices for working environment: **conda** or **poetry**. If you are on **Windows** the prefered method is **conda**. On Linux or MacOS you should be fine with either.

:::::::::::::::::::::::::::::::::::::::::::::::::::

:::solution
### Conda
From within the cloned repository root directory, run the following commands to create a conda environment from the environment.yml file and activate it
```bash
$ conda env create -f environment.yml --prefix ./env
$ conda activate ./env
```

Next, run pytest and see if it completes all tests without errors.

```bash
$ pytest
```

:::

:::solution
### Poetry

:::

