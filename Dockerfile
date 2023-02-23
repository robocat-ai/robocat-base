FROM ubuntu:22.04

RUN apt-get update && apt-get clean

# Install window manager and basic utilities
RUN apt-get install -y \
    x11vnc \
    xvfb \
    fluxbox \
    wmctrl \
    gnupg \
    wget

# Install Google Chrome
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
    echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >>/etc/apt/sources.list.d/google-chrome.list && \
    apt-get update && apt-get -y install google-chrome-stable

ARG USER=robocat
RUN useradd $USER && mkdir -p /home/$USER && chown -R $USER:$USER /home/$USER

RUN mkdir -p /home/$USER/.config && chown -R $USER:$USER /home/$USER/.config

ARG CORRETTO_VERSION=1.8.0

# Install OpenJDK
RUN wget -q -O - https://apt.corretto.aws/corretto.key | apt-key add - && \
    echo "deb https://apt.corretto.aws stable main" >>/etc/apt/sources.list.d/corretto.list && \
    apt-get update && apt-get -y install java-$CORRETTO_VERSION-amazon-corretto-jdk

RUN apt-get install -y \
    zip \
    php=2:8.1+92ubuntu1 \
    curl \
    xdotool \
    tinyproxy \
    tesseract-ocr=4.1.1-2.1build1 && \
    ldconfig

RUN chown -R $USER:$USER /home/$USER

USER $USER
WORKDIR /home/$USER

ARG TAGUI_VERSION=v6.110.0

# Install tagui
RUN wget https://github.com/aisingapore/TagUI/releases/download/$TAGUI_VERSION/TagUI_Linux.zip && \
    unzip TagUI_Linux.zip && rm TagUI_Linux.zip

# Update SikuliX to version 2.0.5
RUN rm /home/$USER/tagui/src/sikulix/sikulix.jar && \
    wget https://launchpad.net/sikuli/sikulix/2.0.5/+download/sikulixide-2.0.5-lux.jar -O /home/$USER/tagui/src/sikulix/sikulix.jar

USER root

# RUN touch /home/$USER/tagui/src/tagui_no_sandbox
RUN sed -i -e 's/chrome_switches="--remote-debugging-port=9222/chrome_switches="--remote-debugging-port=9222 --no-first-run --disable-dev-shm-usage --no-sandbox --disable-setuid-sandbox --proxy-server=http:\/\/localhost:8000/' /home/$USER/tagui/src/tagui

RUN ln -sf /home/$USER/tagui/src/tagui /usr/local/bin/tagui && \
    ln -sf /home/$USER/tagui/src/end_processes /usr/local/bin/kill_tagui && \
    ln -sf /run.sh /usr/local/bin/run && \
    ln -sf $(which python3) /usr/local/bin/python

ENV DISPLAY=:1
# Fixes "DSO support routines" error
ENV OPENSSL_CONF=/dev/null

USER $USER

COPY config/tinyproxy.conf.tmpl /home/robocat/.config/tinyproxy.conf.tmpl

COPY /scripts/run.sh /scripts/bootstrap.sh /

CMD /bootstrap.sh
