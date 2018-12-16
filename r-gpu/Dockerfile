############################################################
## r-gpu-base: Ubuntu + TensorFlow + rocker/r-base
############################################################

ARG TF_VERSION=18.11
FROM nvcr.io/nvidia/tensorflow:${TF_VERSION}-py3 as r-gpu-base
# based on: ubuntu 16.04 LTS, python 3.5
# needs nvidia drivers >= 410

LABEL maintainer="Mike Badescu <mike.badescu@numeract.com>"

# specify R version; for 3.6 need to change the repo dir as well
ENV R_VERSION=${R_VERSION:-3.5.1} \
    TERM=xterm

# for R we do not really need a user (libs installed globally)
# for TF and Keras in R we need only a virtualenv and WORKON_HOME set
# for RStudio we need a user
ARG USER
ARG PASSWORD
ARG USERID
ARG GROUPID

# default user - NO OTHER USER SUPPORTED FOR NOW !!
ENV USER=${USER:-rstudio} \
    PASSWORD=${PASSWORD:-rstudio} \
    USERID=${USERID:-1000} \
    GROUPID=${GROUPID:-1000}

# Add user to 'staff' group, granting them write privileges to /usr/lib/R/site.library
RUN groupadd --gid "${GROUPID}" "${USER}" \
    && useradd \
        --uid ${USERID} \
        --gid ${GROUPID} \
        --create-home \
        --shell /bin/bash \
        ${USER} \
    && addgroup ${USER} staff \
    && echo "${USER}:${PASSWORD}" | chpasswd

# install ubuntu packages
RUN apt-get update \
    && apt-get upgrade -y -q \
    && apt-get install -y --no-install-recommends \
        # libraries
        libxml2-dev \
        libxt-dev \
        libcurl4-openssl-dev \
        libssl-dev \
        libssh2-1-dev \
        # packages
        ca-certificates \
        apt-transport-https \
        gnupg2 \
        locales \
        fonts-texgyre \
        git \
        wget \
        virtualenv \
    && rm -rf /var/lib/apt/lists/*

# Configure default locale
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen en_US.utf8 \
    && /usr/sbin/update-locale LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en

# repo for latest R 3.5
RUN echo "deb https://cloud.r-project.org/bin/linux/ubuntu xenial-cran35/" >> /etc/apt/sources.list \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9

# Now install R and littler, and create a link for littler in /usr/local/bin
# Default CRAN repo is now set by R itself, and littler knows about it too
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        littler \
        r-cran-littler \
        r-base=${R_VERSION}-* \
        r-base-dev=${R_VERSION}-* \
        r-recommended=${R_VERSION}-* \
    && ln -s /usr/lib/R/site-library/littler/examples/install.r /usr/local/bin/install.r \
    && ln -s /usr/lib/R/site-library/littler/examples/install2.r /usr/local/bin/install2.r \
    && ln -s /usr/lib/R/site-library/littler/examples/installGithub.r /usr/local/bin/installGithub.r \
    && ln -s /usr/lib/R/site-library/littler/examples/testInstalled.r /usr/local/bin/testInstalled.r \
    && install.r docopt \
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds \
    && rm -rf /var/lib/apt/lists/* 

# Notes:
# - current dir is /workspace (default from nvidia/tensorflow)
# - the user is still `root` with home dir `~` at "/root"
#   (unless changed using runtime argument --user=)

# start R in folder /workspace (no user defined)
CMD [ "R", "--no-save", "--no-restore-data" ]



############################################################
## r-gpu-keras: r-gpu-base + user + keras
############################################################

FROM r-gpu-base as r-gpu-keras

ENV WORKON_HOME=/home/${USER:-rstudio}/.virtualenvs

# install keras in Python in R
# cannot change user once virtualenv created
# TODO: setup once in /root or /workspace then copy (+ chown?) to given user
RUN virtualenv --system-site-packages /home/${USER}/.virtualenvs/r-tensorflow --python=python3.5 \
    && /bin/bash -c "cd /home/${USER}/.virtualenvs/r-tensorflow/bin/; \
        source activate; \
        pip3 --no-cache-dir install keras" \
    && install2.r keras



#######################################
## r-gpu-keras-test: r-gpu-keras + test file
#######################################

FROM r-gpu-keras as r-gpu-keras-test

# copy test file
COPY test-keras.R /home/${USER}/

# start R, run the test and exit without saving
WORKDIR /home/${USER}
CMD [ "R", "--no-save", "--no-restore-data", "-e", "source('test-keras.R')" ]



############################################################
## r-gpu-tidyverse: r-gpu-base + tidyverse
############################################################

FROM r-gpu-base as r-gpu-tidyverse

RUN install2.r tidyverse



############################################################
## r-gpu-xgboost: r-gpu-base + xgboost
############################################################

FROM r-gpu-base as r-gpu-xgboost

# make xgboost with GPU
# https://xgboost.readthedocs.io/en/latest/build.html#installing-r-package-with-gpu-support

# get cmake 
RUN wget -nv -O makebuilder.sh https://cmake.org/files/v3.12/cmake-3.12.3-Linux-x86_64.sh \
    && sh ./makebuilder.sh --skip-license --prefix=/usr/local/ \
    && git clone --recursive https://github.com/dmlc/xgboost \
    && mkdir -p xgboost/build

WORKDIR xgboost/build
RUN cmake .. -DUSE_CUDA=ON -DR_LIB=ON \
    && make install -j
WORKDIR /workspace


############################################################
## r-gpu-catboost: r-gpu-base + catboost
############################################################

FROM r-gpu-base as r-gpu-catboost

# https://tech.yandex.com/catboost/doc/dg/installation/r-installation-binary-installation-docpage/#r-installation-binary-installation
# https://rdrr.io/cran/remotes/man/install_url.html
# https://www.rdocumentation.org/packages/utils/versions/3.5.1/topics/install.packages

ENV CB_URL=https://github.com/catboost/catboost/releases/download/v0.11.2/catboost-R-Linux-0.11.2.tgz
RUN install.r remotes \
    && R -e "remotes::install_url('${CB_URL}', INSTALL_opts = c('--no-multiarch'))"



############################################################
## r-gpu-full: r-gpu-keras + tidyverse + xgboost + ...
############################################################

FROM r-gpu-keras as r-gpu-full

COPY --from=r-gpu-tidyverse /usr/local/lib/R/site-library/ /usr/local/lib/R/site-library/
COPY --from=r-gpu-xgboost /usr/local/lib/R/site-library/ /usr/local/lib/R/site-library/
COPY --from=r-gpu-catboost /usr/local/lib/R/site-library/ /usr/local/lib/R/site-library/


############################################################
## r-gpu-rstudio: r-gpu-full + rocker/rstudio
############################################################

FROM r-gpu-full as r-gpu-rstudio

# follow https://github.com/rocker-org/rocker-versioned/blob/master/rstudio/3.5.1/Dockerfile
# use /usr/lib/ instead of /usr/local/lib

ARG RSTUDIO_VERSION
ENV RSTUDIO_VERSION=${RSTUDIO_VERSION:-1.1.456}
ARG S6_VERSION
ENV S6_VERSION=${S6_VERSION:-v1.21.4.0}
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2
ENV PATH=/usr/lib/rstudio-server/bin:$PATH

## Download and install RStudio server & dependencies
## Attempts to get detect latest version, otherwise falls back to version given in $VER
## Symlink pandoc, pandoc-citeproc so they are available system-wide
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        file \
        git \
        libapparmor1 \
        libcurl4-openssl-dev \
        libedit2 \
        libssl-dev \
        lsb-release \
        psmisc \
        procps \
        sudo \
        wget \
    ## MB: ubuntu seems to have a more recent version, skip libssl
    # && wget -nv -O libssl1.0.0.deb http://ftp.debian.org/debian/pool/main/o/openssl/libssl1.0.0_1.0.1t-1+deb8u8_amd64.deb \
    # && dpkg -i libssl1.0.0.deb \
    # && rm libssl1.0.0.deb \
    && RSTUDIO_LATEST=$(wget --no-check-certificate -qO- https://s3.amazonaws.com/rstudio-server/current.ver) \
    && [ -z "$RSTUDIO_VERSION" ] && RSTUDIO_VERSION=$RSTUDIO_LATEST || true \
    && wget -nv http://download2.rstudio.org/rstudio-server-${RSTUDIO_VERSION}-amd64.deb \
    && dpkg -i rstudio-server-${RSTUDIO_VERSION}-amd64.deb \
    && rm rstudio-server-*-amd64.deb \
    ## Symlink pandoc & standard pandoc templates for use system-wide
    && ln -s /usr/lib/rstudio-server/bin/pandoc/pandoc /usr/local/bin \
    && ln -s /usr/lib/rstudio-server/bin/pandoc/pandoc-citeproc /usr/local/bin \
    && git clone https://github.com/jgm/pandoc-templates \
    && mkdir -p /opt/pandoc/templates \
    && cp -r pandoc-templates*/* /opt/pandoc/templates && rm -rf pandoc-templates* \
    && mkdir /root/.pandoc && ln -s /opt/pandoc/templates /root/.pandoc/templates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/ \
    ## RStudio wants an /etc/R, will populate from $R_HOME/etc
    && mkdir -p /etc/R \
    ## Write config files in $R_HOME/etc
    && echo '\n\
        \n# Configure httr to perform out-of-band authentication if HTTR_LOCALHOST \
        \n# is not set since a redirect to localhost may not work depending upon \
        \n# where this Docker container is running. \
        \nif(is.na(Sys.getenv("HTTR_LOCALHOST", unset=NA))) { \
        \n  options(httr_oob_default = TRUE) \
        \n}' >> /usr/lib/R/etc/Rprofile.site \
    && echo "PATH=${PATH}" >> /usr/lib/R/etc/Renviron \
    ## Need to configure non-root user for RStudio
    ## MB: already did it
    # && useradd rstudio \
    # && echo "rstudio:rstudio" | chpasswd \
    # && mkdir /home/rstudio \
    # && chown rstudio:rstudio /home/rstudio \
    # && addgroup rstudio staff \
    ## Prevent rstudio from deciding to use /usr/bin/R if a user apt-get installs a package
    &&  echo 'rsession-which-r=/usr/bin/R' >> /etc/rstudio/rserver.conf \
    ## use more robust file locking to avoid errors when using shared volumes:
    && echo 'lock-type=advisory' >> /etc/rstudio/file-locks \
    ## configure git not to request password each time
    && git config --system credential.helper 'cache --timeout=3600' \
    && git config --system push.default simple \
    ## Set up S6 init system
    && wget -nv -P /tmp/ https://github.com/just-containers/s6-overlay/releases/download/${S6_VERSION}/s6-overlay-amd64.tar.gz \
    && tar xzf /tmp/s6-overlay-amd64.tar.gz -C / \
    && mkdir -p /etc/services.d/rstudio \
    && echo '#!/usr/bin/with-contenv bash \
        \n## load /etc/environment vars first: \
        \n for line in $( cat /etc/environment ) ; do export $line ; done \
        \n exec /usr/lib/rstudio-server/bin/rserver --server-daemonize 0' \
        > /etc/services.d/rstudio/run \
    && echo '#!/bin/bash \
        \n rstudio-server stop' \
        > /etc/services.d/rstudio/finish \
    ## MB: default user config from rocker
    && mkdir -p /home/${USER}/.rstudio/monitored/user-settings \
    && echo 'alwaysSaveHistory="1" \
        \nloadRData="0" \
        \nsaveAction="0"' \
        > /home/${USER}/.rstudio/monitored/user-settings/user-settings \
    && chown -R ${USER}:${USER} /home/${USER}/.rstudio

# modified not to change the user after RStudio installed
COPY userconf.sh /etc/cont-init.d/userconf

## running with "-e ADD=shiny" adds shiny server
COPY add_shiny.sh /etc/cont-init.d/add
COPY disable_auth_rserver.conf /etc/rstudio/disable_auth_rserver.conf
COPY pam-helper.sh /usr/lib/rstudio-server/bin/pam-helper

EXPOSE 8787

CMD ["/init"]



############################################################
## r-gpu-user: r-gpu-rstudio + user settings
############################################################

FROM r-gpu-rstudio as r-gpu-user

# inspired from https://github.com/KaiLicht/DataScience_Toolbox/tree/master/dockerfiles/My_Rstudio

# copy user settings with chown
COPY user-settings /home/${USER}/.rstudio/monitored/user-settings/
COPY user-ubuntu-libs /home/${USER}/user-ubuntu-libs
COPY user-cran-packages /home/${USER}/user-cran-packages
COPY user-github-packages /home/${USER}/user-github-packages
RUN chown -R ${USER}:${USER} /home/${USER}/.rstudio \
    && chown ${USER}:${USER} /home/${USER}/user-ubuntu-libs \
    && chown ${USER}:${USER} /home/${USER}/user-cran-packages \
    && chown ${USER}:${USER} /home/${USER}/user-github-packages

RUN apt-get update \
    && apt-get upgrade -y \
    && cat /home/${USER}/user-ubuntu-libs | xargs apt-get install -y --no-install-recommends \
    && cat /home/${USER}/user-cran-packages | xargs install.r \
    && cat /home/${USER}/user-github-packages | xargs installGithub.r \
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds \
    && rm -rf /var/lib/apt/lists/* \
    && rm -f /home/${USER}/user-ubuntu-libs \
    && rm -f /home/${USER}/user-cran-packages \
    && rm -f /home/${USER}/user-github-packages
