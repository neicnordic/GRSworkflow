FROM ubuntu:16.04
MAINTAINER Oskar Vidarsson <oskar.vidarsson@uib.no>

RUN apt update && apt install -y --no-install-recommends \
python-minimal \
python-pip \
python-setuptools \
python-dev \
git \
gcc \
wget \
r-base \
unzip

# plink build dependencies
RUN apt-get update && apt-get install -y \
  build-essential \
  curl \
  libatlas-base-dev \
  liblapack-dev \
  zlib1g-dev
# plink 2.0 alpha 1 final
# https://github.com/chrchang/plink-ng/releases/tag/b0cec5e
RUN cd /tmp \
  && git clone --branch b0cec5e https://github.com/chrchang/plink-ng \
  && cd plink-ng/2.0/build_dynamic/ \
  && sed -i "s/ZSTD_O2 = 1.*/ZSTD_O2 = 0/" Makefile \
  && make -j 5 \
  && cp plink2 /usr/bin/ \
  && cd ../../1.9 \
  && bash plink_first_compile \
  && cp plink /usr/bin

RUN pip install \
numpy==1.12.1 \
pandas==0.20.1 \
scipy==1.0.0 \
bitarray==0.8.1 \
nose==1.3.7

RUN git clone https://github.com/bulik/ldsc && \
git clone https://github.com/precimed/python_convert

RUN mkdir /tsd /net /work /projects /cluster /proj /sw /scratch /meles
