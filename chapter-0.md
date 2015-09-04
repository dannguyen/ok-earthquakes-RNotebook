---
title: Investigating Oklahoma's earthquake surge with R and ggplot2
status: unfinished
description: "A technical walkthrough of how to research, analyze, and visualize Oklahoma's earthquakes using R."
---

__Quick summary__: A four-part walkthrough exploring earthquake data in Oklahoma using R. You can download the code and the data from Github: 

[repo](https://github.com/dannguyen/ok-earthquakes-RNotebook) / [zip file](https://github.com/dannguyen/ok-earthquakes-RNotebook/archive/master.zip).

Jump to the [chapter summaries](#chapter-summaries). Or the [full table of contents](#full-toc).


The concepts of this walkthrough summed up in an animated GIF composed of charts created with ggplot2:

![Animated GIF](/files/images/posts/ok-earthquakes/movie-quakes-OK.gif)


<a id="chapter-summaries"></a>
__The four chapters:__

1. Background into Oklahoma's earthquakes - Lorem ipsum dolor sit amet, consectetur adipisicing elit. Molestias, nihil eaque dolorum ad nulla consectetur, animi non dolore modi eligendi quibusdam. Tenetur maxime, veniam, voluptas saepe sunt corporis facere eligendi?
2. Basic R and ggplot2 concepts and examples - Lorem ipsum dolor sit amet, consectetur adipisicing elit. Laudantium odio at explicabo fuga, necessitatibus autem soluta sapiente iste! Expedita officiis cumque nihil officia voluptate quo corrupti quae illum saepe doloribus!
3. Exploring the historical earthquake data since 1995 - Lorem ipsum dolor sit amet, consectetur adipisicing elit. Eius illo enim neque. Similique esse accusamus consequatur aperiam, a doloribus eaque, laboriosam. Commodi necessitatibus eum, est quaerat quo nulla, totam quia!
4. Correlation and limitations - Lorem ipsum dolor sit amet, consectetur adipisicing elit. Laudantium, quis. Soluta fuga, reiciendis quae minus deserunt in! Omnis, id iure consequuntur vitae voluptatibus. Quis temporibus quia non quo officia unde.


__Long summary:__

This extremely verbose writeup consists of a series of R notebooks and aggregation of recent journalism and research into the recent "swarm" of earthquake activity in Oklahoma. Though it is now (and by "now", I mean very recently) generally accepted by academia, industry, and the politicians, that the earthquakes are the result of drilling operations, this writeup is an attempt to provide a layperson's walkthrough of how to go about researching the issue and also, how to create reproducable data process, including how to collect, clean, analyze, and visualize the earthquake data.

These techniques and principles are general enough to apply to any investigative data process. I use the earthquake data as an example because it is about as clean and straightforward as datasets come. However, we'll find soon enough that it contains the same caveats and complexities that are inherent to all real-world datasets.

The code I've written is at a beginner's level of R (i.e. where I'm at), with a heavy reliance on the ggplot2 visualization library, plus some Python and Bash where I didn't have the patience to figure out the R equivalents. If you understand how to work with data frames and have some familiarity with ggplot2, you should be able to follow along.



The easiest way to follow along is clone the Github repo here:

[https://github.com/dannguyen/ok-earthquakes-RNotebook](https://github.com/dannguyen/ok-earthquakes-RNotebook)

Or, [download it from Github as a zip archive](https://github.com/dannguyen/ok-earthquakes-RNotebook/archive/master.zip). The [__data/__](https://github.com/dannguyen/ok-earthquakes-RNotebook/tree/master/data) directory contains mirrors of the data files used in each of the notebooks.


<a id="full-toc"></a>

__Full table of contents__

* TOC
{:toc}


