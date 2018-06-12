FROM nvidia/cuda:9.0-base-ubuntu16.04

LABEL maintainer="csingh@apache.org"

ENV LOG_TAG="[TF_Z]:"

# Pick up some TF dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        curl \
        libfreetype6-dev \
        libpng12-dev \
        libzmq3-dev \
        pkg-config \
        python \
        python-dev \
        rsync \
        software-properties-common \
        unzip \
        vim \
        wget \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN curl -O https://bootstrap.pypa.io/get-pip.py && \
    python get-pip.py && \
    rm get-pip.py

RUN pip --no-cache-dir install \
        Pillow \
        h5py \
        ipykernel \
        jupyter \
        matplotlib \
        numpy \
        pandas \
        scipy \
        sklearn \
        && \
    python -m ipykernel.kernelspec

# Install TensorFlow CPU version from central repo
ENV TF_VERSION="1.8.0"
RUN pip --no-cache-dir install \
    http://storage.googleapis.com/tensorflow/linux/cpu/tensorflow-${TF_VERSION}-cp27-none-linux_x86_64.whl

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
RUN echo "$LOG_TAG Install java8" && \
    apt-get -y update && \
    apt-get install -y openjdk-8-jdk && \
    rm -rf /var/lib/apt/lists/*

# Download Hadoop
ENV HADOOP_VERSION="3.1.0"
ENV HADOOP_HOME="/hadoop"
RUN echo "$LOG_TAG Download hadoop binary" && \
    wget -O /tmp/hadoop-${HADOOP_VERSION}.tar.gz http://apache.cs.utah.edu/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz && \
    tar -zxvf /tmp/hadoop-${HADOOP_VERSION}.tar.gz && \
    rm -rf /tmp/hadoop-${HADOOP_VERSION}.tar.gz && \
    mv /hadoop-${HADOOP_VERSION} ${HADOOP_HOME}
ENV PATH="${HADOOP_HOME}/bin:${PATH}"

# Install Zeppelin
ENV Z_VERSION="0.7.3"
ENV Z_HOME="/zeppelin"
RUN echo "$LOG_TAG Download Zeppelin binary" && \
    wget -O /tmp/zeppelin-${Z_VERSION}-bin-all.tgz http://archive.apache.org/dist/zeppelin/zeppelin-${Z_VERSION}/zeppelin-${Z_VERSION}-bin-all.tgz && \
    tar -zxvf /tmp/zeppelin-${Z_VERSION}-bin-all.tgz && \
    rm -rf /tmp/zeppelin-${Z_VERSION}-bin-all.tgz && \
    mv /zeppelin-${Z_VERSION}-bin-all ${Z_HOME}
ENV PATH="${Z_HOME}/bin:${PATH}"

COPY zeppelin-site.xml $Z_HOME/conf/zeppelin-site.xml
COPY shiro.ini ${Z_HOME}/conf/shiro.ini
RUN chmod 777 -R ${Z_HOME}

COPY run_container.sh /usr/local/bin/run_container.sh
RUN chmod 755 /usr/local/bin/run_container.sh

EXPOSE 8080
CMD ["/usr/local/bin/run_container.sh"]
