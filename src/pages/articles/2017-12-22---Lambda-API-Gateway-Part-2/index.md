---
title: AWS Lambda and API Gateway Example (Part 2)
date: "2017-12-22T17:38:32-08:00"
layout: post
draft: false
path: "/posts/lambda-api-gateway-part-2"
category: "AWS"
tags:
  - "AWS"
  - "Lambda"
  - "API Gateway"
description: "Walkthrough creating a super simple Lambda function and setting up a API Gateway endpoint to trigger the function - Part 2"
---

In Part 2, we walkthrough the process of creating an API endpoint via API Gateway. Navigate to the API Gateway in the AWS Console and hit `Create API`. Name the API and continue.

On the Resources screen, create a `GET` method via `Create Method` under the `Actions` menu.

Choose `Use Lambda Proxy integration`, select the region that our Lambda function belongs in, enter the name of our Lambda function, and then hit Save.

![create_method](84d6-2091ebf138a0.png)

Almost there! At this point, we can test out the endpoint via the test link on the left.

![test_endpoint](90ac-519729f1df7e.png)

The last step is to deploy the endpoint. We can do this by going to `Deploy API` under `Actions`. Create and name the stage (prod) and then hit `Deploy`.

![deploy_api](8377-6b6dd1661b0d.png)

Take note of the URL - our endpoint is now live!

