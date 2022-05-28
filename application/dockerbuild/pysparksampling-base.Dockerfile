FROM ubuntu:20.04
LABEL maintainer="wh1isper <9573586@qq.com>"

RUN set -ex && \
    echo "deb http://mirrors.bfsu.edu.cn/ubuntu/ focal main restricted universe multiverse" > /etc/apt/sources.list && \
    echo "deb http://mirrors.bfsu.edu.cn/ubuntu/ focal-updates main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb http://mirrors.bfsu.edu.cn/ubuntu/ focal-backports main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb http://mirrors.bfsu.edu.cn/ubuntu/ focal-security main restricted universe multiverse" >> /etc/apt/sources.list

RUN apt-get -y update && apt-get -y upgrade && apt-get install -y curl
RUN apt-get install -y software-properties-common && add-apt-repository ppa:deadsnakes/ppa
RUN apt-get install -y python3-pip python3.7 make build-essential python3.7-dev openjdk-8-jdk
RUN rm -f /usr/bin/python3 && ln -s /usr/bin/python3.7 /usr/bin/python3

# 清除缓存
RUN rm -rf /var/lib/apt/lists/*# 修改系统时区
RUN rm -rf /etc/localtime && ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

RUN apt-get update && \
    apt install -y python3 python3-pip python3-dev && \
    echo "[global]" > /etc/pip.conf && \
    echo "timeout = 600" >> /etc/pip.conf && \
    echo "index-url = https://mirrors.bfsu.edu.cn/pypi/web/simple" >> /etc/pip.conf
RUN python3 -m pip install --upgrade pip
RUN pip3 install 'pyspark<3.3' grpcio protobuf numpy pandas

# install s3 jars
WORKDIR /tmp/pyspark_prepare
COPY ./s3_jars /tmp/pyspark_prepare/s3_jars
COPY ./install_s3_jars.py /tmp/pyspark_prepare/install_s3_jars.py
RUN python3 install_s3_jars.py
RUN rm -rf /tmp/pyspark_prepare/

ENV SPARK_HOME=/usr/local/lib/python3.7/dist-packages/pyspark

ARG APPLICATION_UID=9999
ARG APPLICATION_GID=9999
RUN addgroup --system --gid ${APPLICATION_GID} application && \
    adduser --system --gid ${APPLICATION_GID} --home /home/application --uid ${APPLICATION_UID} --disabled-password application


# docker build -t pysparksampling-base -f application/dockerbuild/pysparksampling-base.Dockerfile .
