---
title: Investigating Oklahoma's earthquake surge with R and ggplot2
status: unfinished
description: "A technical walkthrough of how to research, analyze, and visualize Oklahoma's earthquakes using R."
---

![OK google](/files/images/posts/ok-earthquakes/multi-year-OK-google-map-borderless.jpg)


__Quick summary__: A four-part walkthrough exploring earthquake data in Oklahoma using R.
- [The repo containing the notebooks, code, and data](https://github.com/dannguyen/ok-earthquakes-RNotebook)
- [The repo in a zip file](https://github.com/dannguyen/ok-earthquakes-RNotebook/archive/master.zip).
- The [chapter summaries](#chapter-summaries) 
- The [full table of contents](#full-toc).


The concepts of this walkthrough summed up in an animated GIF composed of charts created with ggplot2:

![Animated GIF](/files/images/posts/ok-earthquakes/optimized-movie-quakes-OK.gif)


<a id="chapter-summaries"></a>
__The four chapters:__

1. [Background into Oklahoma's earthquakes](#chapter-1-mark) - An overview of the scientific and political debates after Oklahoma's earthquake activity reached a record high -- in number and in magnitude -- since 2010. And an overview of the two main datasets we'll use for our analysis.
2. [Basic R and ggplot2 concepts and examples](#chapter-2-mark) - Lorem ipsum dolor sit amet, consectetur adipisicing elit. Laudantium odio at explicabo fuga, necessitatibus autem soluta sapiente iste! Expedita officiis cumque nihil officia voluptate quo corrupti quae illum saepe doloribus!
3. [Exploring the historical earthquake data since 1995](#chapter-3-mark) - We repeat the same techniques in chapter 2, except instead of one month's worth of earthquakes, we look at 20 years of earthquake data. The volume and scope of data requires different approaches in visualization and analysis.
4. [Correlation and limitations](#chapter-4-mark) - Though the significance of the chronological earthquake trend is obvious, that's not enough to show that drilling is the _cause_ of the earthquake surge.


__Long summary:__

This extremely verbose writeup consists of a series of R notebooks and aggregation of recent journalism and research into the recent "swarm" of earthquake activity in Oklahoma. Though it is now (and by "now", I mean very recently) generally accepted by academia, industry, and the politicians, that the earthquakes are the result of drilling operations, this writeup is an attempt to provide a layperson's walkthrough of how to go about researching the issue and also, how to create reproducable data process, including how to collect, clean, analyze, and visualize the earthquake data.

These techniques and principles are general enough to apply to any investigative data process. I use the earthquake data as an example because it is about as clean and straightforward as datasets come. However, we'll find soon enough that it contains the same caveats and complexities that are inherent to all real-world datasets.

__Spoiler alert:__ Just to address, early on, the (correct) criticism that 20 years of earthquake data is not enough on its own for amateurs nor scientists to make sweeping conclusions about the source of recent earthquake activity: yes, I agree. That's not where this walkthrough is headed.

##### About the code

I explain as much of the syntax as I can in [Chapter 2](#chapter-2-mark), but it won't make sense if you don't have _some_ experience with ggplot2. The easiest way to follow along is clone the Github repo here:

[https://github.com/dannguyen/ok-earthquakes-RNotebook](https://github.com/dannguyen/ok-earthquakes-RNotebook)

Or, [download it from Github as a zip archive](https://github.com/dannguyen/ok-earthquakes-RNotebook/archive/master.zip). The [__data/__](https://github.com/dannguyen/ok-earthquakes-RNotebook/tree/master/data) directory contains mirrors of the data files used in each of the notebooks.

The code I've written is at a beginner's level of R (i.e. where I'm at), with a heavy reliance on the ggplot2 visualization library, plus some Python and Bash where I didn't have the patience to figure out the R equivalents. If you understand how to work with data frames and have some familiarity with ggplot2, you should be able to follow along. Rather than organize and modularize my code, I've written it in an explicit, repetitive way, so it's easier to see how to iteratively build and modify the visualizations. The drawback is that there's the amount of code is more intimidating.

My recommendation is to not learn ggplot2 as I started out doing, which is by copying and pasting ggplot2 snippets without understanding the theory of ggplot2's "grammar of graphics." Hadley Wickham's ggplot2 book looks intimidating and esoteric, but it is by far the best way to get up to speed on ggplot2, both because of ggplot2's nuanced underpinnings and Wickham's excellent writing style.




<a id="full-toc"></a>

__Full table of contents__

* TOC
{:toc}


