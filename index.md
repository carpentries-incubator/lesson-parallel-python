---
layout: lesson
root: .  # Is the only page that doesn't follow the pattern /:path/index.html
permalink: index.html  # Is the only page that doesn't follow the pattern /:path/index.html
---
FIXME: home page introduction

<!-- this is an html comment -->

{% comment %} This is a comment in Liquid {% endcomment %}
{% include_relative _meta/description.md %}

> ## Prerequisites
> {% include_relative _meta/prerequisites.md %}
{: .prereq}

{% include links.md %}
