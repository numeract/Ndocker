# Running R (TensorFlow, Keras, RStudio) on Ubuntu 18 LTS with a GPU


## Installation


### 1. Ubuntu

- Install Ubuntu Server 18.04 LTS & update

```sh
sudo apt-get update
sudo apt-get upgrade
sudo apt-get dist-upgrade
```

_Throughout: install ubuntu packages as needed_

```sh
sudo apt install ubuntu-drivers-common
```


### 2. NVIDIA drivers

- ref: https://linuxconfig.org/how-to-install-the-nvidia-drivers-on-ubuntu-18-04-bionic-beaver-linux
- ref: https://www.nvidia.com/object/unix.html

```sh
# add graphics repo
sudo add-apt-repository ppa:graphics-drivers/ppa
sudo apt update

# list available drivers
ubuntu-drivers devices

# specify a driver to install
sudo apt install nvidia-driver-410

# reboot
sudo reboot

# check installation
sudo lshw -c display
nvidia-smi
```

- useful tools

```sh
# check pci cards
lspci | grep -i nvidia

# drivers used for each video device (should show driver=nvidia)
sudo lshw -c display

# which card is being used
prime-select query

# remove all nvidia drivers
sudo apt purge nvidia-*
sudo apt autoremove

# watch GPU usage once every second; use ctrl-c to exit
watch -n 1 nvidia-smi
```


### 3. Docker

- ref: https://klichtenberg.com/?p=151

```sh
# install docker on almost all linux systems
curl -fsSL get.docker.com -o get-docker.sh
sh get-docker.sh

# add current user to the new docker group (not to ask for password every time)
sudo usermod -aG docker $USER

# logout and login

# test docker runs OK
docker run --rm hello-world

# remove installation script
rm get-docker.sh
```


### 4. Docker Compose (on Linux)

- Check for the later version number and update the code below
    + https://github.com/docker/compose/releases

```sh
sudo curl -L https://github.com/docker/compose/releases/download/1.23.2/docker-compose-`uname -s`-`uname -m` -o \
    /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# test with
docker-compose --version
```


### 5. nvidia-docker

- ref: https://github.com/NVIDIA/nvidia-docker

```sh
# Add the package repositories
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | \
  sudo apt-key add -
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt-get update

# Install nvidia-docker2 and reload the Docker daemon configuration
sudo apt-get install -y nvidia-docker2
sudo pkill -SIGHUP dockerd

# Test nvidia-smi with the latest official CUDA image
docker run --runtime=nvidia --rm nvidia/cuda:9.0-base nvidia-smi
```


### 6. NVIDIA GPU Cloud (NGC)

We needed to pull containers that contain proprietary NVDIA code (cannot use Rocker).

- ref: https://klichtenberg.com/?p=151
- register at: https://ngc.nvidia.com/
- use the website to generate API Key (store it safely)
- login with docker

```sh
docker login nvcr.io
# Username: $oauthtoken
# Password: <Your API Key>
```

- identify the latest TensorFlow version for Python 3 (using python 3 for this setup)

```sh
docker pull nvcr.io/nvidia/tensorflow:19.01-py3
```

- test tensorflow gpu inside the container
```sh
nvidia-docker run -it --rm nvcr.io/nvidia/tensorflow:19.01-py3
# there should not be any error at stat, NOTEs are OK
```


## Build

**Copy all files from `r-gpu` to the local working folder**

*Note: use YY.MM convention to denote the version (follow NVIDIA)*

#### Build final images

```sh
docker build --target r-gpu-rstudio -t numeract/r-gpu-rstudio:19.01 .
docker build --target r-gpu-user -t numeract/r-gpu-user:19.01 .
```

#### Or build each intermediary images (for easy reference)


```sh
docker build --target r-gpu-base -t numeract/r-gpu-base:19.01 .
docker build --target r-gpu-keras -t numeract/r-gpu-keras:19.01 .
docker build --target r-gpu-keras-test -t numeract/r-gpu-keras-test:19.01 .

docker build --target r-gpu-tidyverse -t numeract/r-gpu-tidyverse:19.01 .
docker build --target r-gpu-xgboost -t numeract/r-gpu-xgboost:19.01 .
docker build --target r-gpu-catboost -t numeract/r-gpu-catboost:19.01 .
docker build --target r-gpu-full -t numeract/r-gpu-full:19.01 .

docker build --target r-gpu-rstudio -t numeract/r-gpu-rstudio:19.01 .
docker build --target r-gpu-user -t numeract/r-gpu-user:19.01 .
```

#### Test with

_(containers will be removed at exit)_

```sh
nvidia-docker run -it --rm numeract/r-gpu-keras-test:19.01
```

Watch the console output and note whether there is a message from Tensorflow
indicating that it is using the GPU.


```sh
nvidia-docker run -p 8787:8787 -it --rm numeract/r-gpu-user:19.01
```

Point a browser to `http://<ip address>:8787` - this should show the RStudio 
Server IDE (default username and password are `rstudio`). Use CTRL-C in the 
terminal to stop the container.


## TODO:

- check if all files present before build (?)
- build R from source


## Acknowledgments

- [rocker organization](https://hub.docker.com/u/rocker) for maintaining the docker files for R
    + https://github.com/rocker-org/rocker
    + https://github.com/rocker-org/rocker/tree/master/r-apt/xenial
    + https://github.com/rocker-org/rocker-versioned
- KaiLicht for the [writeup](https://klichtenberg.com/?p=151) and repo
    + https://github.com/KaiLicht/DataScience_Toolbox/tree/master/dockerfiles
- Jared Lander for the multi-stage build idea
    + https://github.com/landeranalytics/r-ml
- Ian Scott for testing and helpful comments
