---
layout: default
title: Upgrading
description: Upgrading IBGA (Docker Compose flavor)
parent: Getting Started
nav_order: 3
---

# Upgrading IBGA (Docker Compose flavor)

## Upgrading the IBGA Container

Container upgrading refers to that the IBGA image itself (with the setup and controlling scripts) has been updated, and you would like to catch up with bug fixes and new features. If you followed the [Docker Compose flavored running tutorial](running.md), container upgrading is straightforward.

First, in the directory where your `docker-compose.yml` is located:

    $ sudo docker-compose pull

This will update your local IBGA image to the latest. Then:

    $ sudo docker-compose up -d

Docker will automatically recreate your containers using the latest image and restart them. Note that IB Gateway will be restarted and there will be interruptions. Since the installed IB Gateway and its settings are persisted outside the container, all programs and settings are kept.

## Upgrading IB Gateway

To upgrade IB Gateway executable, the easiest way is to remove the directory mounted to IB Gateway installation path. If you followed the [Docker Compose flavored running tutorial](running.md), the path is `run/program` under where `docker-compose.yml` is resided. Before removal, shut down the container.

    $ sudo docker-compose down
    $ sudo rm -rf ./run/program
    $ sudo docker-compose up -d

When the container is up again, it will automatically create that `run/program` mount and run installation. And since we kept the settings file elsewhere (`./run/settings`), the settings will be kept.
