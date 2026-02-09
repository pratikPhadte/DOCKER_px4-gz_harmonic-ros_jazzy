# =============================================================================
# PX4 + Gazebo Harmonic + ROS 2 Jazzy — Ubuntu 24.04
# =============================================================================
FROM ubuntu:24.04 AS base

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

SHELL ["/bin/bash", "-c"]

# ── Core dependencies ────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    curl \
    git \
    gnupg2 \
    lsb-release \
    software-properties-common \
    sudo \
    wget \
    ca-certificates \
    locales \
    tzdata \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    python3-setuptools \
    ninja-build \
    gdb \
    zip \
    unzip \
    pkg-config \
    libxml2-dev \
    libxml2-utils \
    libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav \
    libopencv-dev \
    protobuf-compiler \
    libeigen3-dev \
    genromfs \
    astyle \
    xmlstarlet \
    xterm \
    terminator \
    dbus-x11 \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# ── QGroundControl ───────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    fuse \
    libfuse2 \
    libxcb-xinerama0 \
    libxkbcommon-x11-0 \
    libxcb-cursor0 \
    && rm -rf /var/lib/apt/lists/* \
    && wget -q https://d176tv9ibo4jno.cloudfront.net/latest/QGroundControl-x86_64.AppImage \
     -O /opt/QGroundControl.AppImage \
    && chmod +x /opt/QGroundControl.AppImage

# ── Gazebo Harmonic ──────────────────────────────────────────────────────────
RUN curl -fsSL https://packages.osrfoundation.org/gazebo.gpg \
        -o /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] \
        http://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" \
        > /etc/apt/sources.list.d/gazebo-stable.list \
    && apt-get update && apt-get install -y --no-install-recommends \
    gz-harmonic \
    && rm -rf /var/lib/apt/lists/*

# ── ROS 2 Jazzy ─────────────────────────────────────────────────────────────
RUN curl -fsSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc \
        | gpg --dearmor -o /usr/share/keyrings/ros-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] \
        http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" \
        > /etc/apt/sources.list.d/ros2.list \
    && apt-get update && apt-get install -y --no-install-recommends \
    ros-jazzy-desktop \
    ros-jazzy-ros-gz \
    ros-jazzy-ros-gz-bridge \
    ros-jazzy-ros-gz-image \
    ros-jazzy-ros-gz-sim \
    ros-dev-tools \
    python3-colcon-common-extensions \
    python3-rosdep \
    python3-vcstool \
    && rm -rf /var/lib/apt/lists/*

# Initialize rosdep
RUN rosdep init || true && rosdep update --rosdistro jazzy

# ── Create non-root user ────────────────────────────────────────────────────
ARG USERNAME=user
ARG USER_UID=1000
ARG USER_GID=1000

# Remove default ubuntu user/group from 24.04 base image, then create our own.
RUN set -e; \
    userdel -r ubuntu 2>/dev/null || true; \
    groupdel ubuntu 2>/dev/null || true; \
    groupadd --gid ${USER_GID} ${USERNAME}; \
    useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME} -s /bin/bash; \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER ${USERNAME}
WORKDIR /home/${USERNAME}

# ── Python dependencies (user-level) ────────────────────────────────────────
RUN python3 -m pip install --user --break-system-packages \
    pyros-genmsg \
    kconfiglib \
    jinja2 \
    jsonschema \
    future \
    pyyaml \
    empy==3.3.4

ENV PATH="/home/${USERNAME}/.local/bin:${PATH}"

# ── PX4-Autopilot ───────────────────────────────────────────────────────────
RUN git clone --recursive https://github.com/PX4/PX4-Autopilot.git \
        --branch main --depth 1 ~/PX4-Autopilot \
    && cd ~/PX4-Autopilot \
    && bash ./Tools/setup/ubuntu.sh --no-sim-tools --no-nuttx \
    && make px4_sitl_default \
    && make clean

# ── Micro XRCE-DDS Agent ────────────────────────────────────────────────────
RUN git clone --depth 1 https://github.com/eProsima/Micro-XRCE-DDS-Agent.git \
        ~/Micro-XRCE-DDS-Agent \
    && cd ~/Micro-XRCE-DDS-Agent \
    && mkdir build && cd build \
    && cmake .. \
    && make -j$(nproc) \
    && sudo make install \
    && sudo ldconfig

# ── ROS 2 workspace with px4_msgs ───────────────────────────────────────────
RUN mkdir -p ~/ros2_ws/src \
    && cd ~/ros2_ws/src \
    && git clone --depth 1 https://github.com/PX4/px4_msgs.git \
    && git clone --depth 1 https://github.com/PX4/px4_ros_com.git \
    && cd ~/ros2_ws \
    && source /opt/ros/jazzy/setup.bash \
    && colcon build --symlink-install

# ── Shell environment ───────────────────────────────────────────────────────
RUN cat >> ~/.bashrc <<'EOF'
# ROS 2
source /opt/ros/jazzy/setup.bash
# PX4 ROS 2 workspace
if [ -f ~/ros2_ws/install/setup.bash ]; then
    source ~/ros2_ws/install/setup.bash
fi
# Gazebo resource paths
export GZ_SIM_RESOURCE_PATH=~/PX4-Autopilot/Tools/simulation/gz/models:~/PX4-Autopilot/Tools/simulation/gz/worlds
EOF

# ── Entrypoint ──────────────────────────────────────────────────────────────
COPY --chown=${USERNAME}:${USERNAME} entrypoint.sh /home/${USERNAME}/entrypoint.sh
RUN chmod +x ~/entrypoint.sh

ENTRYPOINT ["/home/user/entrypoint.sh"]
CMD ["bash"]