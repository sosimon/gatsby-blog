---
title: TIL - Ternary in Bash
date: "2016-10-08T10:10:38-07:00"
layout: post
draft: false
path: "/posts/ternary-in-bash"
category: "bash"
tags:
  - "bash"
description: "#TIL: ternary expression in Bash"
---

I have been working with shell scripts for 4-5 years now, and I only recently saw, for the first time, someone shortcut the classic if/else/then statements:

```bash
[ $condition == "true" ] && echo "true" || echo "false"
```

It took me a few minutes of staring at it to make sure it works the way I think it works.

Having seen this though, I still feel it's better to be a bit more verbose:

```bash
if [ $condition == "true" ]; then
  echo "true"
else
  echo "false"
fi
```

Better readability, easier to understand, and better for the next guy/gal who needs to read your script.
