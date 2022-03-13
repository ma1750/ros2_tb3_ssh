FROM nvidia/cuda:11.0-base-ubuntu20.04
SHELL ["/bin/bash", "-c"]
ENV DEBIAN_FRONTEND=noninteractive
USER root
RUN apt-get update && \
    apt-get install -y wget libxtst6 libxv1 libglu1-mesa libegl1-mesa && \
    wget https://jaist.dl.sourceforge.net/project/virtualgl/3.0/virtualgl_3.0_amd64.deb && \
    dpkg -i virtualgl_3.0_amd64.deb && \
    rm virtualgl_3.0_amd64.deb
RUN apt-get update && apt-get install -y sudo openssh-server
RUN mkdir /run/sshd
RUN useradd -m -s /bin/bash ubuntu && \
    usermod -aG sudo ubuntu && \
    echo 'ubuntu:ubuntu' | chpasswd
RUN apt-get update && apt-get install locales && \
    locale-gen en_US en_US.UTF-8 && \
    update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 && \
    export LANG=en_US.UTF-8 && \
    apt-get update && apt-get install -y curl gnupg2 lsb-release && \
    curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key  -o /usr/share/keyrings/ros-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(source /etc/os-release && echo $UBUNTU_CODENAME) main" | tee /etc/apt/sources.list.d/ros2.list > /dev/null && \
    apt-get update && apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" keyboard-configuration ros-foxy-desktop
RUN apt-get install -y ros-foxy-gazebo-* ros-foxy-cartographer ros-foxy-cartographer-ros ros-foxy-navigation2 ros-foxy-nav2-bringup ros-foxy-dynamixel-sdk ros-foxy-turtlebot3-msgs ros-foxy-turtlebot3 python3-colcon-common-extensions git
USER ubuntu
WORKDIR /home/ubuntu
RUN mkdir -p /home/ubuntu/turtlebot3_ws/src/ && \
    cd /home/ubuntu/turtlebot3_ws/src/ && \
    git clone -b foxy-devel --depth 1 https://github.com/ROBOTIS-GIT/turtlebot3_simulations.git && \
    cd /home/ubuntu/turtlebot3_ws && \
    source /opt/ros/foxy/setup.bash && \
    colcon build --symlink-install
USER root
RUN apt-get update && \
    apt-get install -y python3-cairocffi
USER ubuntu
RUN mkdir -p /home/ubuntu/bag_tool_ws/src && \
    cd /home/ubuntu/bag_tool_ws/src && \
    git clone --depth 1 https://github.com/ros2/rcl_interfaces.git -b foxy && \
    git clone --depth 1 https://github.com/ros2/test_interface_files.git -b foxy && \
    git clone --depth 1 https://github.com/ros2/pybind11_vendor.git -b foxy && \
    git clone --depth 1 https://github.com/ros2/rosbag2.git -b foxy-future && \
    git clone --depth 1 https://github.com/ros-visualization/rqt_bag.git -b ros2 && \
    cd /home/ubuntu/bag_tool_ws && \
    source /opt/ros/foxy/setup.bash && \
    colcon build --symlink-install
RUN echo "export LANG=en_US.UTF-8" >> /home/ubuntu/.bashrc && \
    echo "export XDG_RUNTIME_DIR=/home/ubuntu" >> /home/ubuntu/.bashrc && \
    echo "source /opt/ros/foxy/setup.bash" >> /home/ubuntu/.bashrc && \
    echo "source /home/ubuntu/turtlebot3_ws/install/setup.bash" >> /home/ubuntu/.bashrc && \
    echo "source /home/ubuntu/bag_tool_ws/install/setup.bash" >> /home/ubuntu/.bashrc && \
    echo "export ROS_DOMAIN_ID=30" >> /home/ubuntu/.bashrc && \
    echo "export TURTLEBOT3_MODEL=burger" >> /home/ubuntu/.bashrc && \
    source /home/ubuntu/.bashrc
USER root
CMD ["/usr/sbin/sshd", "-D", "-p", "2222"]
