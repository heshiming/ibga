---
layout: default
title: Docker Basics
description: Docker Compose basics for IBGA, with primer on environment variables, volumes and ports.
parent: References
nav_order: 0
---

# Docker Compose Basics

This section discusses the basics of a Docker Compose configuration, including mechanisms such as `volumes`, `ports`, `restart`, etc. For IBGA-specific `IB_*` arguments (in fact, environment variables), refer to [IBGA Configuration Arguments](config-args.md). 

## Configuration Staples

<a href="https://docs.docker.com/compose/compose-file/" target="_blank">Docker compose file specification</a> is a very long read. But you don't need all that to start using IBGA. Just consider a few sections of this example as staples. For instance:

* `version: '2'` on the first line, don't change that
* `services:` on the second
* `my-ibga:` is the name of the service (also used as an auto-generated container name), which is used as an identifier of the instance within the docker context. If you plan on running multiple instances, give each a clear name such as `my-roth-account`. Note there are 2 spaces before the name, indicating that the `my-ibga` node is a child node under `services`, by YAML format.
* `image: ibga` means that the container will use the `ibga` Docker image, which can be [pulled automatically from Docker Hub](docker-image.md#obtaining-the-ibga-image-from-docker-hub) or [built locally](docker-image.md#building-the-image). Note the four spaces ahead of `image` means that the `image` node is under `my-ibga`.
* `restart: unless-stopped` means unless you manually stop the container, Docker will always try to start it up. It applies to both instances being stopped due to a reboot or crash.

## Environment Variables

The `environment` section defines the environment variables. `TERM=xterm` is for colorful log output from the Docker console. And the rest of the variables are explained in the [IBGA Configuration Arguments](config-args.md) section.

Refer to the <a href="https://docs.docker.com/compose/compose-file/#environment">official documentation</a> for technical details about environment variables.

## Volumes

The `volumes` section defines file system mapping between a host and a container. Since the container is like a virtual machine, its hard drive is a "disk image" (a big file). Accessing its files is typically complex. Docker's <a href="https://docs.docker.com/storage/bind-mounts/" target="_blank">bind mounts</a> mechanism enables "mounting" a host directory for access inside the container so that the files used in the container reflect on the host. Bind mounts makes the container disposable, which means you can safely delete an IBGA container or its image without losing your IB Gateway program files or settings. To upgrade IBGA, delete the container and the image to let Docker reload. To move your setup to another machine, copy the folders in the `volumes` section over.

In the example, there are two bind mount directories:

    - ./run/program:/home/ibg
    - ./run/settings:/home/ibg_settings

It means to map `./run/program` on the host to `/home/ibg` in the container, and map `./run/settings` on the host to `/home/ibg_settings` in the container, where `./` on the host is the directory where `docker-compose.yml` is located. The syntax is `host_dir:container_dir`.

IBGA installs IB Gateway into its `/home/ibg` directory, and redirects its user settings (from the settings Dialog) to `/home/ibg_settings`. These directories can be empty upon container start. In which case, IBGA will install IB Gateway into `./run/settings`, and save user settings into `./run/settings` respectively.

Refer to the <a href="https://docs.docker.com/compose/compose-file/#volumes">official documentation</a> for technical details about volumes.

## Ports

Due to Docker's firewall-style default networking, ports inside the container are not exposed externally by default. You can only access the container from outside after port mapping. The `ports` section defines the port mapping between the host and the container. Its syntax is `host_port:container_port`.

In the example, there are two port mappings:

    - "15800:5800"
    - "4000:4000"

It means to map host port `15800` to container port `5800` and host port `4000` to container port `4000`. So if your server IP address is `192.168.1.100`, this enables access to `192.168.1.100:15800`. IBGA's port `5800` container port is an HTTP server with <a href="https://en.wikipedia.org/wiki/Virtual_Network_Computing" target="_blank">VNC</a> access from a browser. Visit `http://192.168.1.100:15800` to see the live actions of IBGA running. IBGA's port `4000` is IB Gateway's API socket port, which you can connect from an API client.

Refer to the <a href="https://docs.docker.com/compose/compose-file/#ports">official documentation</a> for technical details about ports.

