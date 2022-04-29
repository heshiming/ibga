---
layout: default
title: The Docker Image
description: The IBGA Docker image explained, obtaining and building.
parent: Getting Started
nav_order: 0
---

# The IBGA Docker Image

## Understanding the Concept of Images and Containers

If you are new to docker, images and containers, here is a primer on each concept. <a href="https://docs.docker.com/get-started/overview/#images" target="_blank">**An image**</a> is a read-only template acting as the base files that make up a system. <a href="https://docs.docker.com/get-started/overview/#containers" target="_blank">**A container**</a> is a runnable instance of an image.

**A container** is a lot like an instance of <a href="https://en.wikipedia.org/wiki/Virtual_machine" target="_blank">virtual machine (VM)</a>, whereas **an image** is like the disk of the VM.

<a href="https://www.docker.com/" target="_blank">Docker</a> is a set of software that implements OS-level virtualization technology to support running of containers based on images.

## Obtaining the IBGA Image From Docker Hub

The IBGA docker image is located at <a href="https://hub.docker.com/r/heshiming/ibga" target="_blank">https://hub.docker.com/r/heshiming/ibga</a>. To obtain the image, use the following command:

    $ sudo docker pull heshiming/ibga

However, if you plan to follow our [Docker Compose flavored configuration](configuring.md), you don't need this command to pull it. Docker Compose will pull it automatically when you [launch the container](running.md).

## Building the Image

Docker is required before building the IBGA image. Please refer to its <a href="https://docs.docker.com/get-docker/">official documentation</a> for the details about installing.

Use the `build.sh` script to build the IBGA docker image on your own computer:

    $ ./build.sh

You will need a bash shell, available on Linux, UNIX, and macOS to run this script. If you are using Windows, open up `build.sh` in a text editor, and paste the `docker build` command into a command prompt window.

## Behind the Scene

IBGA is designed to be a "disposable container", that is, important states and program files are not persisted inside the container. The container is loaded with just a set of bash scripts, X11 and VNC to support remote viewing, and the automation dependencies, namely <a href="https://heshiming.github.io/jauto/" target="_blank">JAuto</a> and <a href="https://github.com/jordansissel/xdotool" target="_blank">xdotool</a>. Upgrading will be a piece of cake.

IBGA makes use of <a href="https://en.wikipedia.org/wiki/Xvfb" target="_blank">Xvfb</a> ([why not `xserver-xorg-video-dummy`?](../faq.md#why-xvfb-but-not-the-modern-xserver-xorg-video-dummy-as-the-framebuffer)), and <a href="https://github.com/LibVNC/x11vnc" target="_blank">x11vnc</a> to implement a headless <a href="https://en.wikipedia.org/wiki/X_Window_System" target="_blank">X11</a> environment that is capable of both running a GUI application as well as allowing remote control. 

IBGA employs a set of bash scripts to manage everything: from installation to daily restarts; from logins to option settings. The image itself does not come with a copy of IB Gateway. Instead, it downloads and installs from the web upon first start.

<a href="https://heshiming.github.io/jauto/" target="_blank">JAuto</a> is a crucial piece in automation implementation. To click a button or fill in a text box, you need its coordinates and text. JAuto is capable of listing onscreen UI components and their attributes. Another critical piece is <a href="https://github.com/jordansissel/xdotool" target="_blank">xdotool</a>, which simulates keyboard and mouse actions with the coordinates supplied by JAuto.

