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
# Build image 
###########################################
FROM core AS base

ENV DEBIAN_FRONTEND=noninteractive
RUN cmake --version
# setup sources.list
RUN echo "deb http://packages.ros.org/ros2/ubuntu focal main" > /etc/apt/sources.list.d/ros2-latest.list

# setup keys
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654

# install ros packages
RUN apt update && apt install -y \
    gdb  \
    libbullet-dev \
    libpython3-dev \
    python3-colcon-common-extensions \
    python3-flake8 \
    python3-pip \
    python3-pytest-cov \
    python3-rosdep \
    python3-setuptools \
    python3-vcstool \
    python3-rosinstall-generator \
    libasio-dev \
    libtinyxml2-dev \
    libcunit1-dev \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install  -U  -i https://pypi.tuna.tsinghua.edu.cn/simple --no-cache-dir \
    rosdepc  \    
    argcomplete \
    flake8-blind-except \
    flake8-builtins \
    flake8-class-newline \
    flake8-comprehensions \
    flake8-deprecated \
    flake8-docstrings \
    flake8-import-order \
    flake8-quotes \
    pytest-repeat \
    pytest-rerunfailures \
    pytest && \
    rosdepc init

ARG ROS_PKG=ros_base
ENV ROS_DISTRO=foxy
ENV ROS_ROOT=/opt/ros/${ROS_DISTRO}

# compile yaml-cpp-0.6, which some ROS packages may use (but is not in the 18.04 apt repo)
RUN git clone --branch yaml-cpp-0.6.0 https://ghproxy.com/https://github.com/jbeder/yaml-cpp yaml-cpp-0.6 && \
    cd yaml-cpp-0.6 && \
    mkdir build && \
    cd build && \
    cmake -DBUILD_SHARED_LIBS=ON .. && \
    make -j$(nproc) && \
    cp libyaml-cpp.so.0.6.0 /usr/lib/aarch64-linux-gnu/ && \
    ln -s /usr/lib/aarch64-linux-gnu/libyaml-cpp.so.0.6.0 /usr/lib/aarch64-linux-gnu/libyaml-cpp.so.0.6 && \
    cd ../.. && rm -rf yaml-cpp-0.6

RUN mkdir -p ${ROS_ROOT}/src 
COPY ./ros2.repos /${ROS_ROOT}/ros2.repos
RUN    cd ${ROS_ROOT} && \
    vcs import src < ros2.repos

# install dependencies using rosdep
RUN apt-get update && \
    cd ${ROS_ROOT} && \
    rosdepc update && \
    # rosdep install --from-paths src --ignore-src --rosdistro ${ROS_DISTRO} -y --skip-keys "console_bridge fastcdr fastrtps rti-connext-dds-5.3.1 urdfdom_headers qt_gui" && \
    rosdep install --from-paths src --ignore-src -y --skip-keys "fastcdr rti-connext-dds-5.3.1 urdfdom_headers" && \
    rm -rf /var/lib/apt/lists/*

COPY ghproxy.py ${ROS_ROOT}
RUN cd ${ROS_ROOT} && python ghproxy.py
# build it!
RUN cd ${ROS_ROOT} && colcon build --symlink-install

# Setup environment

# ENV AMENT_PREFIX_PATH=/opt/ros/foxy/install
# ENV COLCON_PREFIX_PATH=/opt/ros/foxy
# ENV LD_LIBRARY_PATH=/opt/ros/foxy/lib
# ENV PATH=/opt/ros/foxy/bin:$PATH
# ENV PYTHONPATH=/opt/ros/foxy/lib/python3.8/site-packages
# ENV ROS_PYTHON_VERSION=3
# ENV ROS_VERSION=2

# Set up ros env
RUN  echo "source /usr/share/bash-completion/completions/git" >> /root/.bashrc \
    && echo "if [ -f /opt/ros/${ROS_DISTRO}/install/setup.bash ]; then source /opt/ros/${ROS_DISTRO}/install/setup.bash; fi" >> /root/.bashrc
ENV DEBIAN_FRONTEND=