---
layout: default
title: Configuring
description: Configuring IBGA (Docker Compose flavor) with examples
parent: Getting Started
nav_order: 1
---

# Configuring IBGA (Docker Compose flavor)

IBGA docker image contains utilities and scripts for automating <a href="https://www.interactivebrokers.com/en/trading/ibgateway-latest.php" target="_blank">IB Gateway</a> in headless mode. To launch the program, you need to create a container. To automate the logins, you need to supply a username and password, among other arguments. An easy way to go about this is to use a <a href="https://docs.docker.com/compose/" target="_blank">Docker Compose</a> config file.

## Installing Docker Compose

Depending on your host OS (Linux, for instance), Docker Compose may be a standalone executable, separate from Docker itself. Please refer to the <a href="https://docs.docker.com/compose/install/#install-compose" target="_blank">official documentation</a> to see if you need to follow extra steps to install Docker Compose.

## An Example Docker Compose Configuration File

The Docker Compose configuration file is in <a href="https://yaml.org/" target="_blank">YAML</a> syntax, typically named `docker-compose.yml`. You can create and edit this file in a text editor. Don't worry if you are new to the YAML format. <a href="https://docs.ansible.com/ansible/latest/reference_appendices/YAMLSyntax.html" target="_blank">A couple of examples</a> should get you started.

    version: '2'
    services:
      my-ibga:
        image: heshiming/ibga
        restart: unless-stopped
        environment:
          - TERM=xterm
          - IB_USERNAME=username
          - IB_PASSWORD=password
          - IB_REGION=America
          - IB_TIMEZONE=America/New York
          - IB_LOGINTAB=IB API
          - IB_LOGINTYPE=Live Trading
          - IB_LOGOFF=11:55 PM
          - IB_APILOG=data
          - IB_LOGLEVEL=Error
          - IB_PREFER_IBKEY=true
        volumes:
          - ./run/program:/home/ibg
          - ./run/settings:/home/ibg_settings
        ports:
          - "15800:5800"
          - "4000:4000"

For more information about a Docker Compose configuration, including mechanisms such as `volumes`, `ports`, `restart`, refer to [Docker Basics](../references/docker-basics.md).

For more information about IBGA-specific `IB_*` arguments (in fact, environment variables), refer to [IBGA Configuration Arguments](../references/config-args.md). 
