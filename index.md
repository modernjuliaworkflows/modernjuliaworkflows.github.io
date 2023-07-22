@def title = "Modern Julia Workflows"

# Modern Julia Workflows

A series of blog posts on best practices for Julia development.
Consider this a draft: once the posts are ready, we will submit them to the [Julia language blog](https://julialang.org/blog/) to make them easily discoverable.

\toc

## Goals

Our purpose is to gather the hidden tips and tricks of Julia development, and make them easily accessible to beginners.
We do not cover the basics of syntax, and assume that the reader is familiar enough with Julia to read and write elementary scripts.
Instead, we focus on all the tools that can make the coding experience more pleasant and efficient.
For each of them, we provide a brief introduction, give a small actionable demo, and then refer to the appropriate online resources.
In the [divio](https://documentation.divio.com/) documentation system, this would land halfway between a tutorial and a how-to guide.

## Structure

There are three blog posts of increasing technical difficulty:

1. [Writing your code](/pages/writing/): from zero to a basic script
2. [Sharing your code](/pages/sharing/): from a basic script to a reliable package
3. [Optimizing your code](/pages/optimizing/): from a basic script to a light-speed algorithm

All three are fairly long and not meant to be read in one sitting, so take your time.
Keep in mind that while each of these resources _can_ be useful to you, not every one of them _will_ be.
But at least you will know where to look in case you have a specific question.

The page [Going further](/pages/further/) is a collection of other websites to help you dive deeper into the rabbit hole.

## Before you start

Many of the links you will see point to [GitHub](https://github.com/) repositories for Julia packages.
When you click them, they will take you to a page called `README.md`, which gives a brief description of what the package does.
Usually, this description is not enough to actually use the package.
You can often find a more thorough documentation by looking for a blue badge called `docs|stable` (or `docs|dev`) at the top of the page.