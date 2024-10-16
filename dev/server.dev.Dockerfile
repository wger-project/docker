#
# Installs some additional packages needed for development
#

FROM wger/server:latest

USER root
WORKDIR /home/wger/src
RUN apt-get update && \
    apt-get install -y \
        git \
        vim \
        yarnpkg \
        sassc

RUN ln -s /usr/bin/yarnpkg /usr/bin/yarn \
    && ln -s /usr/bin/sassc /usr/bin/sass \
    && pip3 install --break-system-packages --user -r requirements.txt \
    && pip3 install --break-system-packages --user -r requirements_dev.txt

USER wger
