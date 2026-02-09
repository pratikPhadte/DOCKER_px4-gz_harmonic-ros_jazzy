#!/bin/bash
set -e

# Source ROS 2
source /opt/ros/jazzy/setup.bash

# Source PX4 ROS 2 workspace if built
if [ -f ~/ros2_ws/install/setup.bash ]; then
    source ~/ros2_ws/install/setup.bash
fi

# Set Gazebo resource paths
export GZ_SIM_RESOURCE_PATH="${HOME}/PX4-Autopilot/Tools/simulation/gz/models:${HOME}/PX4-Autopilot/Tools/simulation/gz/worlds:${GZ_SIM_RESOURCE_PATH:-}"

exec "$@"
