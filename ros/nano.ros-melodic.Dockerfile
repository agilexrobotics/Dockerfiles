# for jetpack 4.6.1, we should use  l4t 32.7.1
FROM  nvcr.io/nvidia/l4t-base:r32.4.4 as core
# setup timezone
ENV DEBIAN_FRONTEND=noninteractive
# set up sources
RUN sed -i "s/ports.ubuntu.com/mirrors.ustc.edu.cn/g" /etc/apt/sources.list

# Install language
RUN apt update && apt install -y \
    locales \
    && locale-gen en_US.UTF-8 \
    && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*
ENV LANG en_US.UTF-8

# Install timezone
RUN ln -fs /usr/share/zoneinfo/UTC /etc/localtime \
    && apt update \
    && apt install -y tzdata \
    && dpkg-reconfigure --frontend noninteractive tzdata \
    && rm -rf /var/lib/apt/lists/*


RUN apt update && apt install  -y \
    dirmngr \
    gnupg2 \
    build-essential \
    bash-completion \
    git \
    wget \
    libssl-dev \
    curl \
    openssh-server \
    lsb-release \
    sudo  \
    vim  \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt &&  cd /opt && curl -O https://ghproxy.com/https://github.com/Kitware/CMake/releases/download/v3.23.1/cmake-3.23.1.tar.gz &&\
    tar -zxvf cmake-3.23.1.tar.gz  &&\
    cd cmake-3.23.1 && ./bootstrap
RUN cd /opt/cmake-3.23.1  && make &&  make install && \
    cd .. && rm -rf cmake-3.23.1.tar.gz cmake-3.23.1


ENV DEBIAN_FRONTEND=dialog

###########################################
# Develop image 
###########################################
FROM core AS dev

ENV DEBIAN_FRONTEND=noninteractive

RUN echo "deb http://packages.ros.org/ros/ubuntu bionic main" > /etc/apt/sources.list.d/ros1-latest.list

# setup keys
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654

# install ros packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    python-vcstools \
    python-pip  \
    python-wstool \
    python-pep8 \
    python-autopep8 \
    pylint \
    python-rosinstall-generator \
    python-rosdep \
    python-rosinstall \
    ros-melodic-ros-base && \
    rm -rf /var/lib/apt/lists/*pt/lists/*

# Setup environment
ENV LD_LIBRARY_PATH=/opt/ros/melodic/lib
ENV ROS_DISTRO=melodic
ENV ROS_ROOT=/opt/ros/melodic/share/ros
ENV ROS_PACKAGE_PATH=/opt/ros/melodidirmngr
ENV ROS_VERSION=1
ENV PATH=/opt/ros/melodic/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV ROSLISP_PACKAGE_DIRECTORIES=
ENV PYTHONPATH=/opt/ros/melodic/lib/python2.7/dist-packages
ENV PKG_CONFIG_PATH=/opt/ros/melodic/lib/pkgconfig
ENV ROS_ETC_DIR=/opt/ros/melodic/etc/ros
ENV CMAKE_PREFIX_PATH=/opt/ros/melodic


RUN pip install rosdepc -i https://pypi.tuna.tsinghua.edu.cn/simple --no-cache-dir

# use rosdepc to update rosdep
RUN rosdepc init

# Set up ros env
RUN  echo "source /usr/share/bash-completion/completions/git" >> /home/root/.bashrc \
    && echo "if [ -f /opt/ros/${ROS_DISTRO}/setup.bash ]; then source /opt/ros/${ROS_DISTRO}/setup.bash; fi" >> /home/root/.bashrc
ENV DEBIAN_FRONTEND=
