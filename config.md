<!--
Add here global page variables to use throughout your website.
-->
+++
author = "Guillaume Dalle & Jacobus Smit"
mintoclevel = 2
prepath = "ModernJuliaWorkflows"

# Add here files or directories that should be ignored by Franklin, otherwise
# these files might be copied and, if markdown, processed by Franklin which
# you might not want. Indicate directories by ending the name with a `/`.
# Base files such as LICENSE.md and README.md are ignored by default.
ignore = ["node_modules/"]

# RSS (the website_{title, descr, url} must be defined to get RSS)
generate_rss = true
website_title = "Modern Julia Workflows"
website_descr = "Blog posts on best practices for Julia development"
website_url   = "https://gdalle.github.io/ModernJuliaWorkflows/"
+++

<!--
Add here global latex commands to use throughout your pages.
-->
\newcommand{\tldr}[1]{@@tldr @@title TLDR@@ @@content #1 @@ @@}