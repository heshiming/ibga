FROM openjdk:18-slim-bullseye AS jauto_build
USER root
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl cmake gcc g++ make libc-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
ENV JAUTO_VER=1.0.0
RUN curl -Lk https://github.com/heshiming/jauto/archive/refs/tags/v$JAUTO_VER.tar.gz -o /tmp/jauto.tar.gz
WORKDIR /tmp
RUN tar xfz jauto.tar.gz && \
    mkdir jauto_build && \
    cd jauto_build && \
    cmake ../jauto-$JAUTO_VER && \
    cmake --build .

FROM debian:bullseye-slim AS util_build
USER root
RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc libx11-dev libc-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
ADD utils /tmp/utils
WORKDIR /tmp/utils
RUN gcc show_text.c -O2 -lX11 -o show_text

FROM debian:bullseye-slim
USER root
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl sudo ed xvfb x11vnc x11-utils xdotool socat python3-websockify procps xfonts-scalable tzdata && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
RUN useradd -ms /bin/bash -u 2000 ibg && \
    adduser ibg sudo && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
WORKDIR /opt
RUN curl -Lk "https://github.com/novnc/noVNC/archive/refs/tags/v1.3.0.tar.gz" -o novnc.tar.gz && \
    tar xfz novnc.tar.gz && \
    rm novnc.tar.gz
USER ibg
WORKDIR /home/ibg
COPY --from=util_build /tmp/utils/show_text /bin
COPY --from=jauto_build /tmp/jauto_build/jauto.so /opt
ADD scripts /opt/ibga/
RUN sudo chmod a+rx /bin/show_text && \
    sudo chmod a+rx /opt/jauto.so && \
    sudo chmod a+rx /opt/ibga/*
EXPOSE 4000/tcp
EXPOSE 5800/tcp
ENTRYPOINT /opt/ibga/manager.sh
