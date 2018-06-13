FROM nvidia/cuda:9.0-base-ubuntu16.04

LABEL maintainer="csingh@apache.org"

ENV LOG_TAG="[TF_Z]:"

RUN  echo "$LOG_TAG update and install basic packages" && \
     apt-get -y update && apt-get install -y --no-install-recommends \
        build-essential \
        curl \
        libfreetype6-dev \
        libpng12-dev \
        libzmq3-dev \
        pkg-config \
        rsync \
        software-properties-common \
        unzip \
        vim \
        wget \
        && \
    apt-get install -y locales && \
    locale-gen $LANG && \
    apt-get clean && \
    apt -y autoclean && \
    apt -y dist-upgrade && \
    apt-get install -y build-essential && \
    rm -rf /var/lib/apt/lists/*

# should install conda first before numpy, matploylib since pip and python will be installed by conda
RUN echo "$LOG_TAG Install miniconda2 related packages" && \
    apt-get -y update && \
    apt-get install -y bzip2 ca-certificates \
    libglib2.0-0 libxext6 libsm6 libxrender1 \
    git mercurial subversion && \
    echo 'export PATH=/opt/conda/bin:$PATH' > /etc/profile.d/conda.sh && \
    wget --quiet https://repo.continuum.io/miniconda/Miniconda2-4.3.11-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh
ENV PATH /opt/conda/bin:$PATH

RUN echo "$LOG_TAG Install python related packages" && \
    apt-get -y update && \
    apt-get install -y python-dev python-pip && \
    apt-get install -y gfortran && \
    # numerical/algebra packages
    apt-get install -y libblas-dev libatlas-dev liblapack-dev && \
    # font, image for matplotlib
    apt-get install -y libpng-dev libfreetype6-dev libxft-dev && \
    # for tkinter
    apt-get install -y python-tk libxml2-dev libxslt-dev zlib1g-dev && \
    pip install --upgrade pip && \
    pip --no-cache-dir install Pillow && \
    pip --no-cache-dir install h5py && \
    pip --no-cache-dir install numpy && \
    pip --no-cache-dir install matplotlib && \
    pip --no-cache-dir install pandas && \
    pip --no-cache-dir install ipykernel && \
    pip --no-cache-dir install scipy && \
    pip --no-cache-dir install sklearn && \
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

RUN echo "$LOG_TAG Install R related packages" && \
    echo "deb http://cran.rstudio.com/bin/linux/ubuntu xenial/" | tee -a /etc/apt/sources.list && \
    gpg --keyserver keyserver.ubuntu.com --recv-key E084DAB9 && \
    gpg -a --export E084DAB9 | apt-key add - && \
    apt-get -y update && \
    apt-get -y install r-base r-base-dev && \
    R -e "install.packages('knitr', repos='http://cran.us.r-project.org')" && \
    R -e "install.packages('ggplot2', repos='http://cran.us.r-project.org')" && \
    R -e "install.packages('googleVis', repos='http://cran.us.r-project.org')" && \
    R -e "install.packages('data.table', repos='http://cran.us.r-project.org')" && \
    # for devtools, Rcpp
    apt-get -y install libcurl4-gnutls-dev libssl-dev && \
    R -e "install.packages('devtools', repos='http://cran.us.r-project.org')" && \
    R -e "install.packages('Rcpp', repos='http://cran.us.r-project.org')" && \
    Rscript -e "library('devtools'); library('Rcpp'); install_github('ramnathv/rCharts')"

# Install Zeppelin
ENV Z_VERSION="0.7.3" \
    Z_HOME="/zeppelin"

RUN echo "$LOG_TAG Download Zeppelin binary" && \
    wget -O /tmp/zeppelin-${Z_VERSION}-bin-all.tgz http://archive.apache.org/dist/zeppelin/zeppelin-${Z_VERSION}/zeppelin-${Z_VERSION}-bin-all.tgz && \
    tar -zxvf /tmp/zeppelin-${Z_VERSION}-bin-all.tgz && \
    rm -rf /tmp/zeppelin-${Z_VERSION}-bin-all.tgz && \
    mv /zeppelin-${Z_VERSION}-bin-all ${Z_HOME}
ENV PATH="${Z_HOME}/bin:${PATH}"

RUN echo "$LOG_TAG Set locale" && \
    echo "LC_ALL=en_US.UTF-8" >> /etc/environment && \
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
    echo "LANG=en_US.UTF-8" > /etc/locale.conf && \
    locale-gen en_US.UTF-8

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

COPY zeppelin-site.xml $Z_HOME/conf/zeppelin-site.xml
COPY shiro.ini ${Z_HOME}/conf/shiro.ini
RUN chmod 777 -R ${Z_HOME}

COPY run_container.sh /usr/local/bin/run_container.sh
RUN chmod 755 /usr/local/bin/run_container.sh

# More hadoop related environments required for zeppelin shell
ENV HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop \
    HADOOP_YARN_HOME=$HADOOP_HOME/share/hadoop/yarn

# Install more python packages
RUN pip --no-cache-dir install keras && \
    pip --no-cache-dir install opencv-python && \
    pip --no-cache-dir install scikit-image

# Create /home for pip install
RUN mkdir -p /home && chmod 777 -R /home

EXPOSE 8080
CMD ["/usr/local/bin/run_container.sh"]
