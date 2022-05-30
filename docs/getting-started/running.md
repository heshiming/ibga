---
layout: default
title: Running
description: Running IBGA (Docker Compose flavor)
parent: Getting Started
nav_order: 2
---

# Running IBGA (Docker Compose flavor)

Once you have your [`docker-compose.yml` configuration](configuring.md) ready, running IBGA is as simple as:

    $ sudo docker-compose up -d

Or if you named your configuration otherwise:

    $ sudo docker-compose -f my-own-config.yml up -d

If the IBGA docker image is not downloaded at this point, Docker Compose will automatically pull it for you before creating the container.

The `-d` argument tells Docker Compose to launch the container in the background (as in "daemon"). If you are just testing out IBGA, you can omit this argument so that the container occupies your console. In this case, interrupting via Ctrl+C or disconnecting from the shell will kill the container. For more information regarding `docker-compose` command line arguments, please refer to the <a href="https://docs.docker.com/compose/reference/" target="_blank">official documentation</a>.

If you followed [the default configuration](configuring.md#an-example-docker-compose-configuration-file) where `restart: unless-stopped` is set, the container will always be up with the host unless you manually shut down the container or Docker.

In [the default configuration](configuring.md#an-example-docker-compose-configuration-file), two ports `15800` and `4000` are exposed:

| Port | Function | Note |
| `15800` | Browser-based VNC client to inspect container running status. | Access via http://ip:15800/ in a browser. Made possible by <a href="https://novnc.com/" target="_blank">novnc</a> |
| `4000` | IB API server port | Internal mapping (via <a href="https://linux.die.net/man/1/socat" target="_blank">socat</a>) is done to allow any IP address to connect. |


**When your container is up and running, it is a good time to pay attention to [security](../references/security.md). Understanding security is critical to keep you safe trading.**
