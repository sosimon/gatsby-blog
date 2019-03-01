---
title: 7 Tips to Start Your Terraform Project the Right Way
date: "2018-12-28T01:01:01-07:00"
layout: post
draft: false
path: "/posts/7-tips-to-start-your-terraform-project"
category: "terraform"
tags:
  - "terraform"
  - "infrastructure-as-code"
  - "devops"
  - "AWS"
  - "GCP"
  - "hashicorp"
description: "Lessons learned from writing Terraform for clients large and small. This article was originally published on Medium: https://medium.com/@simon.so/7-tips-to-start-your-terraform-project-the-right-way-93d9b890721a"
---

#Introduction

Terraform, released 4 years ago in 2014, has risen to the top of a proliferation of DevOps tools, and distinguished itself in a very short amount of time. As far as pure infrastructure-as-code tools go, it competes primarily against proprietary offerings such as AWS CloudFormation, Azure Resource Manager, and GCP Deployment Manager. But Terraform also competes against (and arguably trumps) other popular configuration management tools that have been around for much longer, such as, Puppet, Chef, and Ansible, in terms of ease of use, speed, community support.

Like Chef/Puppet, Terraform encourages a declarative-style (describing what you want done, instead of how) and immutable infrastructure, a pattern where machine images, servers, other resources are not changed once they have been created. When a change is necessary, new resources are created and the old ones decommissioned.

In helping our clients move towards IAC and immutable infrastructure, I have been writing Terraform for a little over 2 years. In this time, I have picked up a few recommended patterns and practices to follow when using Terraform. The following is a collection of lessons that I have personally learned, and a few tricks, hacks, and workarounds that I have come across to get Terraform to behave the way I wanted.

A note of caution: Terraform [0.12](https://www.hashicorp.com/blog/terraform-0-1-2-preview) is coming soon. 0.12 brings a host of new features and even some breaking changes in the language (HCL) itself, so some of the workarounds I describe below will no longer be necessary post-0.12

#1. Remote State

Terraform, by default, stores the last-known (the last time you ran it) state of the infrastructure (resource IDs, names, properties, metadata, etc) in a JSON file locally. Keeping your Terraform state file local works fine if you are the only person working on and running the Terraform templates. But as soon as your team grows beyond 2 people, you will run into problems.

Imagine Alice and Bob are working on the same Terraform file, each on their own laptops. The files are stored and managed with a Git repository. All good so far. Alice writes a simple Terraform template to create an EC2 instance, checks it in to Git, and then runs it locally on her machine to create the EC2 instance. Terraform generates a local state file on her machine that describes all the properties and metadata of the instance. No problem.
Bob now wants to run the same Terraform, so he checks out the code from Git and then tries to run it. Because Bob has never run this code before, a local state file was never generated. From Bob's Terraform's point of view, there are no EC2 instances, so Terraform thinks that it needs to create one (because that's what the code says). When Terraform tries to create the instance, it will most likely fail with an error saying the instance already exists, because it does, Alice created it, but Bob's Terraform doesn't know about it.

The solution is to use a shared, remote state file. Typically, this would be an S3 or GCS bucket, and the declaration would look something like this:

```hcl
terraform {
  backend "s3" {
    bucket = "mybucket"
    key = "path/to/my/key"
    region = "us-east-1"
  }
}
```

By allowing multiple people to use the same state file, it effectively lets everyone share the same "view" of the infrastructure, and have a consistent experience when Terraform runs.

One major inconvenience about the remote state backend declaration is that none of the properties can be interpolated, so we cannot do this:

```hcl
terraform {
  backend "s3" {
    bucket = "my-${var.env}-bucket"
    key = "path/to/my/key"
    region = "us-east-1"
  }
}
```

This means if you use a separate bucket per environment (a good practice), you have to hard code it, OR leverage [partial configuration](https://www.terraform.io/docs/backends/config.html#partial-configuration) and build your own wrapper script around Terraform to inject the backend values dynamically at runtime. [Terragrunt](https://github.com/gruntwork-io/terragrunt) is a great tool in this regard. Instead of having to copy and paste essentially the same Terraform backend block everywhere, you can leave it blank:

```hcl
terraform {
  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {}
}
```

Then, declare the remote state block just once in a `.tfvars` file:

```hcl
terragrunt = {
  remote_state {
    backend = "s3"
    config {
      bucket = "my-terraform-state"
      key = "${path_relative_to_include()}/terraform.tfstate"
      region = "us-east-1"
      encrypt = true
      dynamodb_table = "my-lock-table"
    }
  }
}
```

See the [Terragrunt Github page](https://github.com/gruntwork-io/terragrunt#keep-your-remote-state-configuration-dry) for more details.

While we are on the topic of remote state: do not [edit](https://www.terraform.io/docs/state/index.html#inspection-and-modification) your state files by hand. It usually doesn't end well.

#2. Separate Your Environments

In addition to separating the remote state backend by environment, it is good practice to separate the Terraform for each environment in its own folder as well, not only for the purpose of code organization but it also allows for better and easier CI and automation integration, which can target a specific environment folder and execute `terraform plan` and `terraform apply` separately.

```
/
├── ci
├── environments
│   ├── dev
│   │   ├── frontend
│   │   │   ├── backend.tf
│   │   │   ├── main.tf
│   │   │   ├── outputs.tf
│   │   │   ├── shared.tf      -> ../../shared/shared.tf
│   │   │   └── variables.tf
│   │   ├── db
│   │   │   ├── backend.tf
│   │   │   ├── main.tf
│   │   │   ├── outputs.tf
│   │   │   ├── shared.tf      -> ../../shared/shared.tf
│   │   │   └── variables.tf
│   ├── qa
│   │   ├── frontend
│   │   └── db
│   ├── st
│   │   ├── frontend
│   │   └── db
│   ├── prod
│   │   ├── frontend
│   │   └── db
├── modules
│   ├── app
│   ├── db
│   ├── lb
└── shared
    └── shared.tf
```

Implementing this one-folder-per-environment pattern, you end up having to repeat (copy and paste) a bunch of Terraform code from one environment to another. The next two sections present few more ideas of how to re-use Terraform code and not repeat yourself too much.

#3. Use Modules

Using [modules](https://www.terraform.io/docs/modules/usage.html) is a must when writing Terraform of any level of complexity, not only does it help you organize your code by separating concerns, it will lead to more code reuse and less repetition.

One useful feature is the ability to refer to or source a module in source control directly. In this case, we are using Git, but Mercurial sources are supported as well. We can specify a ref to the commit (hash or tags) to lock down the version of the module that we want.

```hcl
module "mymodule" {
  source = "git::ssh//git@gitlab.com/acme/module.git?ref=tags/1.0.0"
  ...
}
```

This allows us to publish common modules that are used across multiple teams, which means individual teams have to write less Terraform, and the maintenance burden is lessened as there is one place to look - the common module - if something needs to be fixed.

#4. Keep it DRY

Don't Repeat Yourself (DRY) is a principle that discourages repetition, and encourages modularization, abstraction, and code reuse. Applying it to Terraform, using modules is a big step in the right direction.

However, repetitions still happen. You may end up having virtually the same code in N different environments, and when you need to make one change, you have to make the change N times.

There are a few ways to address this problem. One that I have seen and used at several clients is to create a folder for shared or common files, and then create symlinks to these files from each environment. This way, you can make a change to the common file(s) once and it appears in all your environments.

[Terragrunt](https://github.com/gruntwork-io/terragrunt#motivation) solves the same problem in a different way. It is a wrapper around the Terraform CLI commands, which allows you to write your Terraform once, and then in a [separate repository](https://github.com/gruntwork-io/terragrunt#keep-your-terraform-code-dry) define only the input variables for each environment - no need to repeat Terraform code for each environment. Terragrunt is also quite handy for orchestrating Terraform in CICD pipelines for multiple separate projects.

#5. Conditionals

Terraform supports conditionals through the syntax of a ternary operator: `CONDITION ? VAL_IF_TRUE : VAL_IF_FALSE`. The most common use case is a conditional resource based on an input variable and the meta-parameter count. In the following example, a storage bucket is created if `create_bucket` is true, otherwise, no bucket is created.

```hcl
locals {
  make_bucket = "${var.create_bucket == "true" ? true : false}"
}

resource "google_storage_bucket" "mybucket" {
  count   = "${local.make_bucket ? 1 : 0}"
  name    = "${var.bucket_name}"
  project = "${var.project_name}"
}
```

Terraform plan output for create_bucket = false
```
➜ test-bucket terraform plan -var='create_bucket=false'
Refreshing Terraform state in-memory prior to plan…
The refreshed state will be used to calculate this plan, but will not be
persisted to local or remote state storage.


 - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

No changes. Infrastructure is up-to-date.

This means that Terraform did not detect any differences between your
configuration and real physical resources that exist. As a result, no
actions need to be performed.
```

Terraform plan output for create_bucket = true
```
➜ test-bucket terraform plan -var='create_bucket=true'
Refreshing Terraform state in-memory prior to plan…
The refreshed state will be used to calculate this plan, but will not be
persisted to local or remote state storage.


 - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  + google_storage_bucket.mybucket
    id: <computed>
    force_destroy: "false"
    location: "US"
    name: "sso-test-bucket"
    project: "sso-test-project"
    self_link: <computed>
    storage_class: "STANDARD"
    url: <computed>
    
    
Plan: 1 to add, 0 to change, 0 to destroy.

 - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
```

#6. The null_resource
The [`null_resource`](https://www.terraform.io/docs/provisioners/null_resource.html) may be useful if you need to do something that is not directly associated with the lifecycle of an actual resource. Within a `null_resource`, you can configure provisioners to run scripts to do essentially whatever you want. For example, you could SSH into an instance and run a command, or connect to a database to execute a query, or simply run a script to register an instance with DNS.

It should be noted, however, that whatever is being done inside a `null_resource` is not going to be managed by Terraform. So if in your `null_resource` you decide to call a `gcloud` command to create resources, maybe a compute instance, for example, Terraform is not going to know about this and therefore cannot manage its lifecycle and state. Still it is occasionally useful to run a script whenever Terraform runs or whenever a resource changes (using [triggers](https://www.terraform.io/docs/provisioners/null_resource.html#triggers)).

In general, it is a good idea use `null_resource` sparingly and when you do, vet the scripts being called to make sure it is as idempotent as possible.

#7. Other Useful Functions

As you become more familiar with Terraform, and as the infrastructure and corresponding Terraform code become more and more complex, you start to want more functionality and flexibility. Inevitably, you will need to to use one of the many useful built-in [interpolation functions](https://www.terraform.io/docs/configuration/interpolation.html). The following are a few notable ones that I use a lot or find interesting:

* `format()` and `formatlist()` format a string or a list of strings. The following example left-pads the cluster_id with zeros to 4 digits

```hcl
locals {
    hostname = "${format("%s-%s-%s-%s-%04d-%s", var.region, var.env, var.app, var.type, var.cluster_id, var.id)}"
}
```

* `matchkeys(values, keys, searchlist)` - filters a list of values with corresponding keys and returns only values that have keys in the searchlist. The following example returns a list of instances that are in the first zone.

```hcl
instances = [
  "${matchkeys(
    google_compute_instance.compute_instance.*.self_link,
    google_compute_instance.compute_instance.*.zone,
    data.google_compute_zones.available.names[0])
  }"
]
```

* `element(list, index)` - to access elements in a list variable (the [] notation also works). A neat "feature" of this function is that it wraps around the list, for example:

```hcl
list = ["foo", "bar", "baz"]
# ${element(var.list, 0)} == foo
# ${element(var.list, 1)} == bar
# ${element(var.list, 2)} == baz
# ${element(var.list, 3)} == foo
```


#Conclusion

Within the Cloud/DevOps team at [Slalom Silicon Valley](https://www.slalom.com/locations/silicon-valley), Terraform is our team's current to-go choice for any infrastructure automation projects, due to its feature set and roadmap, ability to work with multiple clouds, ease of use, and community support. If you are starting a Terraform project, here is a handy checklist of best practices to follow:

1. Use remote state/backend
2. Separate environments
3. Use modules
4. Keep it DRY (with tools like Terragrunt)
5. Use conditionals for flexibility
6. Use `null_resource` for edge cases (use sparingly)
7. Use built-in interpolation functions

If you are working with GCP, Google has a close partnership with Hashicorp - there is a team of Googlers who maintains the GCP provider! There is also a set of Terraform modules authored and maintained by Googlers on [Github](https://github.com/terraform-google-modules) that can be used as-is or as references for how to write (and test!) Terraform modules.
