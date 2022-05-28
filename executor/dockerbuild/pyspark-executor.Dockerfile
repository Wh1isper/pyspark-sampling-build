# Build in SPARK_HOME, set UID=9999
ARG java_image_tag=11.0.15-slim-buster

FROM openjdk:${java_image_tag}
ARG DEBIAN_FRONTEND=noninteractive

ARG EXECUTOR_UID=9999
ARG EXECUTOR_GID=9999
RUN addgroup --system --gid ${EXECUTOR_GID} executor && \
    adduser --system --gid ${EXECUTOR_GID} --home /home/executor --uid ${EXECUTOR_UID} --disabled-password executor

ARG spark_uid=$EXECUTOR_UID


# Before building the docker image, first build and make a Spark distribution following
# the instructions in http://spark.apache.org/docs/latest/building-spark.html.
# If this docker file is being used in the context of building your images from a Spark
# distribution, the docker build command should be invoked from the top level directory
# of the Spark distribution. E.g.:
# docker build -t spark:latest -f kubernetes/dockerfiles/spark/Dockerfile .

RUN set -ex && \
    echo "deb https://mirrors.tuna.tsinghua.edu.cn/debian/ buster main contrib non-free" > /etc/apt/sources.list && \
    echo "deb https://mirrors.tuna.tsinghua.edu.cn/debian/ buster-updates main contrib non-free" >> /etc/apt/sources.list && \
    echo "deb https://mirrors.tuna.tsinghua.edu.cn/debian/ buster-backports main contrib non-free" >> /etc/apt/sources.list && \
    echo "deb https://mirrors.tuna.tsinghua.edu.cn/debian-security buster/updates main contrib non-free" >> /etc/apt/sources.list && \
    apt-get update && \
    ln -s /lib /lib64 && \
    apt install -y bash tini libc6 libpam-modules krb5-user libnss3 procps build-essential && \
    mkdir -p /opt/spark && \
    mkdir -p /opt/spark/examples && \
    mkdir -p /opt/spark/work-dir && \
    touch /opt/spark/RELEASE && \
    rm /bin/sh && \
    ln -sv /bin/bash /bin/sh && \
    echo "auth required pam_wheel.so use_uid" >> /etc/pam.d/su && \
    chgrp root /etc/passwd && chmod ug+rw /etc/passwd && \
    rm -rf /var/cache/apt/*

COPY jars /opt/spark/jars
COPY bin /opt/spark/bin
COPY sbin /opt/spark/sbin
COPY kubernetes/dockerfiles/spark/entrypoint.sh /opt/
COPY kubernetes/dockerfiles/spark/decom.sh /opt/
COPY examples /opt/spark/examples
COPY kubernetes/tests /opt/spark/tests
COPY data /opt/spark/data

ENV SPARK_HOME /opt/spark

WORKDIR /opt/spark/work-dir
RUN chmod g+w /opt/spark/work-dir
RUN chmod a+x /opt/decom.sh


# install pyspark below
WORKDIR /

# Reset to root to run installation tasks
USER 0

RUN mkdir ${SPARK_HOME}/python
RUN apt-get update && \
    apt install -y python3 python3-pip python3-dev && \
    echo "[global]" > /etc/pip.conf && \
    echo "timeout = 600" >> /etc/pip.conf && \
    echo "index-url = https://mirrors.bfsu.edu.cn/pypi/web/simple" >> /etc/pip.conf && \
    pip3 install --upgrade pip setuptools && \
    # Removed the .cache to save space
    rm -rf /root/.cache && rm -rf /var/cache/apt/*

COPY python/pyspark ${SPARK_HOME}/python/pyspark
COPY python/lib ${SPARK_HOME}/python/lib

WORKDIR /opt/spark/work-dir
ENTRYPOINT [ "/opt/entrypoint.sh" ]

# Specify the User that the actual main process will run as
USER ${spark_uid}

# python install_s3_jars.py
# ln -s $PWD/executor/dockerbuild $SPARK_HOME/dockerbuild
# cd $SPARK_HOME
# docker build -t wh1isper/pyspark-executor:latest -f dockerbuild/pyspark-executor.Dockerfile .
