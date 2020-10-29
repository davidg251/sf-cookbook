#!/bin/bash
set -x

sudo apt update

# install java 8
sudo apt install -y openjdk-8-jdk

# download jenkins 
cd ~ &&  wget https://get.jenkins.io/war-stable/2.249.2/jenkins.war

# install aws cli
sudo apt-get -y install python3-pip
pip3 install --user awscli

# install docker
sudo apt-get -y install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"

sudo apt-get update
sudo apt-get -y install docker-ce docker-ce-cli containerd.io

sudo groupadd docker
sudo usermod -aG docker ubuntu

# install efs utils

git clone https://github.com/aws/efs-utils
cd efs-utils
sudo apt-get -y install binutils
./build-deb.sh
sudo apt-get -y install ./build/amazon-efs-utils*deb

sudo apt install maven -y