---
title: Investigating Oklahoma's earthquake surge with R and ggplot2
status: unfinished
description: "A technical walkthrough of how to research, analyze, and visualize Oklahoma's earthquakes using R."
---

![OK google](/files/images/posts/ok-earthquakes/multi-year-OK-google-map-borderless.jpg)


__Quick summary__: A four-part walkthrough exploring earthquake data in Oklahoma using R.

__Quick nav__:

- The [chapter summaries](#chapter-summaries) 
- The [full table of contents](#full-toc).
- [The repo containing the notebooks, code, and data](https://github.com/dannguyen/ok-earthquakes-RNotebook)
- [The repo in a zip file](https://github.com/dannguyen/ok-earthquakes-RNotebook/archive/master.zip).


The concepts of this walkthrough summed up in an animated GIF composed of charts created with ggplot2:

![Animated GIF](/files/images/posts/ok-earthquakes/optimized-movie-quakes-OK.gif)


<a id="chapter-summaries"></a>
__The four chapters:__

1. [Background into Oklahoma's earthquakes](#chapter-1-mark) - An overview of the scientific and political debates after Oklahoma's earthquake activity reached a record high -- in number and in magnitude -- since 2010. And an overview of the main datasets we'll use for our analysis.
2. [Basic R and ggplot2 concepts and examples](#chapter-2-mark) - In this chapter, we'll cover most of the basic R and ggplot2 conventions needed to do the necessary data-gathering/cleaning and visualizations in subsequent chapters.
3. [Exploring the historical earthquake data since 1995](#chapter-3-mark) - We repeat the same techniques in chapter 2, except instead of one month's worth of earthquakes, we look at 20 years of earthquake data. The volume and scope of data requires different approaches in visualization and analysis.
4. [Correlation, limitations, and known unknowns](#chapter-4-mark) - Though the significance of the chronological earthquake trend is obvious, that's not enough to show that drilling is the _cause_ of the earthquake surge.


__Long summary:__

This extremely verbose writeup consists of a series of R notebooks and aggregation of [journalism and research into the recent "swarm" of earthquake activity in Oklahoma](https://stateimpact.npr.org/oklahoma/tag/earthquakes/). It is now (and by "now", I mean [very recently](http://earthquakes.ok.gov/news/)) generally accepted by academia, industry, and the politicians, that the earthquakes are the result of drilling operations. So this walkthrough won't reveal anything new to those who have been following the news. But I created the walkthrough to provide a layperson's guide of how to go about researching the issue and also, how to create reproducible data process, including how to collect, clean, analyze, and visualize the earthquake data.

These techniques and principles are general enough to apply to any investigative data process. I use the earthquake data as an example because it is about as clean and straightforward as datasets come. However, we'll find soon enough that it contains the same caveats and complexities that are inherent to all real-world datasets.

__Spoiler alert.__ Let's be clear: 20 years of earthquake data is not remotely enough for amateurs nor scientists to make sweeping conclusions about the source of recent earthquake activity. So I've devoted a good part of [Chapter 4](#chapter-4-mark) to explaining the limitations of the data (and my knowledge) and pointing to resources that you can pursue on your own.

##### About the code

I explain as much of the syntax as I can in [Chapter 2](#chapter-2-mark), but it won't make sense if you don't have _some_ experience with ggplot2. The easiest way to follow along is clone the Github repo here:

[https://github.com/dannguyen/ok-earthquakes-RNotebook](https://github.com/dannguyen/ok-earthquakes-RNotebook)

Or, [download it from Github as a zip archive](https://github.com/dannguyen/ok-earthquakes-RNotebook/archive/master.zip). The [__data/__](https://github.com/dannguyen/ok-earthquakes-RNotebook/tree/master/data) directory contains mirrors of the data files used in each of the notebooks.

The code I've written is at a beginner's level of R (i.e. where I'm at), with a heavy reliance on the [ggplot2 visualization library](http://ggplot2.org/), plus some Python and Bash where I didn't have the patience to figure out the R equivalents. If you understand how to work with data frames and have some familiarity with ggplot2, you should be able to follow along. Rather than organize and modularize my code, I've written it in an explicit, repetitive way, so it's easier to see how to iteratively build and modify the visualizations. The drawback is that there's the amount of code is more intimidating.

My recommendation is to __not__ learn ggplot2 as I initially did: by copying and pasting ggplot2 snippets without understanding the theory of ggplot2's "grammar of graphics." Instead, read ggplot2 creator Hadley Wickham's book: [ggplot2: Elegant Graphics for Data Analysis](http://www.amazon.com/ggplot2-Elegant-Graphics-Data-Analysis/dp/0387981403). While the book seems stuffy and intimidating, it is by far the best way to get up to speed on ggplot2, both because of ggplot2's nuanced underpinnings and Wickham's excellent writing style. You can buy the [slightly outdated (but still worthwhile) 2009 version](http://www.amazon.com/ggplot2-Elegant-Graphics-Data-Analysis/dp/0387981403) or attempt to build [the new edition that Wickham is currently working on](https://github.com/hadley/ggplot2-book).


End summary.


# The Walkthrough


<a id="full-toc"></a>

__Full table of contents__

* TOC
{:toc}


