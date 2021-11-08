---
title: "Exercise: Photo Mosaic"
teaching: 15
exercises: 75
questions:
- "How do I decide which technique to use where?"
- "How do I put everything together?"
- "Can you show some real life examples?"
objectives:
- "Create a strategy for parallelising existing code."
- "Apply previously discussed methods to problems."
- "Choose the correct abstraction for a problem."
keypoints:
- "You sometimes have to try different strategies to find out what works best."
---

# Create a photo mosaic

> ## Dataset
> This exercise uses a large dataset of ~10000 cat pictures from
> [Kaggle](https://www.kaggle.com/crawford/cat-dataset). You need to login to Kaggle to download
> this information. It is desirable to find a better way to distribute this data set to
> participants. The best method may depend on your own situation and access to hosting services.
> Note that this specific dataset somehow has a double copy of every image. You may want to delete
> the duplicates before doing the exercise.
{: .callout}

You may be familiar with those mosaics of photos creating a larger picture. The goal of this
exercise is to create such a mosaic. You are given a data set of nearly 10000 cat pictures.

- All these pictures need to be cut to square proportions and shrunk to managable size of ~ 100x100
pixels.
- Choose one photo that will be the larger image.
- Find a method to assign a cat picture to each pixel in the target cat picture.

To get you started, here is a code to create a small collage of cat pictures:

```
from typing import Iterator
from pathlib import Path
from PIL import Image, ImageOps

def list_images(path: Path) -> Iterator[Path]:
    return path.glob("**/*.jpg")

# assuming all the images are in ./data
img_paths = list(list_images(Path("./data")))
target_id = 5019      # just pick one

collage = Image.new("RGB", (1600, 400))
for i in range(4):
    panel = ImageOps.fit(Image.open(img_paths[target_id + i]), (400,400))
    collage.paste(panel, (i*400, 0))
collage.save("fig/collage.jpg")
```
{: .source .language-python}

![Collage of cat pictures](../fig/cats.jpg){: .output}

> ## About Pillow
> Image loading, saving and manipulation is best done using `pillow`, which is a fork of the older
> and long forgotten Python Imaging Library (`pil`).
>
> For example, shrinking an image can be done as follows:
>
> ```
> from PIL import Image, ImageOps
> im = Image.open("some_cat_picture.jpg")
> thumb = ImageOps.fit(im, (100, 100))
> thumb.save("some_cat_picture.thumb.jpg")
> ```
> {: .source .language-python}
>
> Use the `ImageStats` module to get statistics of the images. To create the actual mosaic, use
> the `Image.paste` method. For more information, see the [Pillow
> documentation](https://pillow.readthedocs.io/en/stable/).
{: .callout}

> ## A solution
> There are many ways to solve this exercise. We will use the `dask.bag` interface. And cache the
> thumbnail images in a HDF5 file. We split the solution in a configuration, preprocessing and
> assembly part. In terms of parallelisation, the largest gain is in preprocessing.
>
> ### Config
> ```
> from PIL import Image, ImageOps, ImageStat
>
> data_path = Path("./data")
> img_paths = list(list_images(data_path))
> target_id = 5019
> target_res = (100, 100)
> thumb_res = (50, 50)
> ```
> {: .source .language-python}
>
> ### Preprocessing
> ```
> from dask.diagnostics import ProgressBar
> from dask import bag as db
>
> def process(img: Image) -> Image:
>     return ImageOps.fit(img, thumb_res)
>
> def encode_to_jpg(img: Image) -> bytes:
>     f = BytesIO()
>     img.save(f, "jpeg")
>     return f.getbuffer()
>
> def save_all(path: Path, jpgs: list[bytes]) -> None:
>     with h5.File(path, "w") as out:
>         for n, jpg in enumerate(jpgs):
>             dataset = out.create_dataset(f"{n:06}", data=np.frombuffer(jpg, dtype='B'))
>
> wf = db.from_sequence(img_paths, npartitions=1000) \
>     .map(get_image) \
>     .map(process) \
>     .map(encode_to_jpg)
>
> with ProgressBar():
>     jpgs = wf.compute()
>
> save_all(data_path / "tiny_imgs.h5", jpgs)
> ```
> {: .source .language-python}
>
> ### Matching (nearest neighbour)
> ```
> thumbs_rgb = np.array([ImageStat.Stat(img).mean for img in images])
> target_img = ImageOps.fit(Image.open(image_paths[target_id]), target_res)
> r, g, b = (np.array(target_img.getdata(band)) for band in range(3))
> target_rgb = np.c_[r, g, b]
>
> dist = ((target_rgb[:,None,:] - thumbs_rgb[None,:,:])**2).sum(axis=2)
> match = np.argmin(dist, axis=0)
> print("Unique images used in nearest neighbour approach: {}" \
>       .format(np.unique(matches).shape[0]))
> np.savetxt(
>     data_path / "matches_nearest.tab",
>     matches.reshape(target_res),
>     fmt="%d")
> ```
> {: .source .language-python}
>
> ### Assembly
> ```
> with h5.File(data_path / "tiny_imgs.h5", "r") as f:
>     imgs = [Image.open(BytesIO(f[n][:]), formats=["jpeg"]) for n in f]
>
> matches_nearest = np.loadtxt(data_path / "matches_nearest.tab", dtype=int)
> ys, xs = np.indices(target_res)
> mosaic = Image.new("RGB", (target_res[0]*thumb_res[0], target_res[1]*thumb_res[1]))
>
> for (x, y, m) in zip(xs.flat, ys.flat, matches_nearest.flat):
>     mosaic.paste(imgs[m], (x*thumb_res[0], y*thumb_res[1]))
>
> mosaic.save("mosaic_unique.jpg")
> ```
> {: .source .language-python}
{: .solution}

> ## Optional: optimal transport
> One strategy to assign images to pixels is to search the image that matches the color of the pixel
> the closest. You will get a lot of the same images though. The cooler challenge is to do the
> assignment such that every cat picture is only used once!
>
> It turns out that this is one of the hardest problems in computer science and is known by many
> names. Though not all identical, all these problems are related:
> - Monge's (Ampère and Kantorovich can also be found in naming this) problem: suppose you have a
>   number of mines in several places, and refineries in other places. You want to move ore to all
>   the refineries in such a way that the total mass transport is minimized.
> - Stable Mariage problem: suppose you have $n$ men and $n$ women (all straight, this problem was
>   first stated somewhere in the 1950ies) and want to create $n$ couples, such that no man desires
>   another's wife that also desires that man over her own spouse.
> - Optimal Mariage problem: in the previous setting can you find the solution that makes everyone
>   the happiest globally?
> - Find the least "costly" mapping from one probability distribution to another.
>
> These problems generally belong to the topic of *optimal transport*. There is a nice Python
> library, Python Optimal Transport, or `pot` for short, that implements many algorithms for solving
> optimal transport problems. Check out the [POT Documentation](https://pythonot.github.io/).
>
> ![Connect the dots: how to draw a line between the red and blue sample, such that the total length
> is minimized?](../fig/optimal-transport.png)
>
> > ## Solution
> > This code is adapted from an [example on the OT
> > documentation](https://pythonot.github.io/auto_examples/plot_OT_2D_samples.html#sphx-glr-auto-examples-plot-ot-2d-samples-py). Suppose that you have two arrays of sizes `(m, 3)` and `(n, 3)`, where `n` is the amount
> > of cat pictures, and `m` the amount of pixels in the target. Each array lists the RGB values
> > that you want to match, `thumbs_rgb` and `target_rgb`.
> >
> > ```
> > import ot
> >
> > n = len(thumbs_rgb)
> > m = len(target_rgb)
> > M = ot.dist(thumbs_rgb, target_rgb)
> > M /= M.max()
> > G0 = ot.emd(np.ones((n,))/n, np.ones((m,))/m, M, numItermax=10**6)
> >
> > matches = np.argmax(G0, axis=0)
> > print("Unique images used in optimal transport approach: {}" \
> >       .format(np.unique(matches).shape[0]))
> > np.savetxt(
> >     data_path / "matches_unique.tab",
> >     matches.reshape(target_res),
> >     fmt="%d")
> > ```
> > {: .source .language-python}
> {: .solution}
{: .challenge}

{% include links.md %}
