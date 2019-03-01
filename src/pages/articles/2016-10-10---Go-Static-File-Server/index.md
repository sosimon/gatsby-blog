---
title: Go Static File Server
date: "2016-10-10T21:02:33-07:00"
layout: post
draft: false
path: "/posts/go-static-file-server"
category: "go"
tags:
  - "go"
description: "A simple static file server with Go"
---

I started learning Go about 3 months ago, back in July. One of the things that struck me early on was how easy, accessible, and fun it was, especially when it came to doing things on the web.

At work last week, there was a situation where an emergency firewall and router replacement would have interrupted communication to a static file server that we depedended on for CI. The solution was this:

```go
package main

import "net/http"

func main() {
    http.ListenAndServe(":8080", http.FileServer(http.Dir("/app/mirror")))
}
```

plus a scrach Docker container:

```docker
FROM scratch
ADD main /

CMD ["/main"]
```

We spun up a new VM and deployed in less time than it took to SCP files over to the new mirror!
