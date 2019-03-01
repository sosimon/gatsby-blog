---
title: Serverless and AWS Lambda
date: "2017-04-21T20:57:22-07:00"
layout: post
draft: false
path: "/posts/serverless-and-aws-lambda"
category: "AWS"
tags:
  - "serverless"
  - "AWS"
  - "Lambda"
description: "Quick thoughts on serverless and AWS Lambda"
---

Serverless compute and architecture has been all gaining a lot attention lately,
and AWS, once again, is leading the charge with the introduction of AWS Lambda a
few years ago. The basic idea is that instead of the traditional model where you
run an application on a compute and pay for 100% of the time that the compute is
running, regardless of whether your application is actually serving traffic, you
refactor your application into Lambda functions which respond to requests
on-demand. You only get charged for the time that the Lambda function is
running, and thus saving you money over a traditional compute. Obviously, your
mileage may vary, but if we are purely looking at cost, I would presume spiky
work loads would benefit the most from switching to serverless, compared to slow
and steady work loads.

There are other benefits such as modularity and loose coupling, which lends
itself nicely to agile SDLCs and continuous delivery. Changes can be isolated to
a sub-set of Lambda functions, so there is no need to rebuild and redeploy the
entire application. In fact, when you think about it, serverless is really a
more extreme version of micro or nanoservices. Advantages, and disadvantages, of
microservices apply here to some extent. One of the main disadvantages, from a
developers perspective, is the difficulty debugging a serverless application.
And of course, AWS has already come up with something - Step Functions - to help
aleviate some of this pain.

In the spirit of getting my hands dirty, in the next post, I plan to set up a
Lambda function, configure API Gateway, and create a simple web frontend that
triggers said function.
