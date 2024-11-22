# parallel-python-workbench

    This is the lesson repository for parallel-python-workbench

## Teaching this lesson?

Do you want to teach parallel programming? This material is open-source and freely available.
Are you planning on using our material in your teaching?
We would love to help you prepare to teach the lesson and receive feedback on how it could be further improved, based on your experience in the workshop.

You can notify us that you plan to teach this lesson by creating an issue in this repository. Also, it would great if you can update [this overview of all workshops taught with this lesson material](workshops.md). This helps us show the impact of developing open-source lessons to our funders.

## Rendering

The Carpentries Workbench use the `sandpaper` engine on top of Pandoc to render the website. Sandpaper is written in R and has some further requirements. It is best to use the enclosed `Dockerfile` to run R in and build the pages.

The `Makefile` contains the commands to build and run the container using Podman. When inside the container, the lesson is mounted on `/lesson`.

```
cd /lesson
R --no-save -e 'sandpaper::serve()'
```
