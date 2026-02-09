#!/bin/bash
# =============================================================================
# run.sh — Quick-start helper for the PX4 + Gazebo Harmonic container
# =============================================================================
set -e

# Allow X11 forwarding from Docker
xhost +local:docker 2>/dev/null || true

echo "============================================"
echo " PX4 · Gazebo Harmonic · ROS 2 Jazzy"
echo "============================================"
echo ""
echo "Starting container..."
docker compose up -d --build

echo ""
echo "Container is running. Open a shell with:"
echo "  docker compose exec px4_gz bash"
echo ""
echo "──────────────────────────────────────────────"
echo " Quick start commands (run inside container):"
echo "──────────────────────────────────────────────"
echo ""
echo " 1) Launch PX4 SITL + Gazebo (x500 quadcopter):"
echo "    cd ~/PX4-Autopilot && make px4_sitl gz_x500"
echo ""
echo " 2) In a second terminal, start the DDS agent:"
echo "    MicroXRCEAgent udp4 -p 8888"
echo ""
echo " 3) In a third terminal, check ROS 2 topics:"
echo "    ros2 topic list"
echo ""
echo "──────────────────────────────────────────────"
