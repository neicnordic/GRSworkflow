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

RUN pip install \
numpy==1.12.1 \
pandas==0.20.1 \
scipy==1.0.0 \
bitarray==0.8.1 \
nose==1.3.7

RUN git clone https://github.com/bulik/ldsc && \
cd ldsc && \
git checkout cf1707e
RUN git clone https://github.com/precimed/python_convert && \
cd python_convert && \
git checkout eb49d7d

# plink v1.90b5.4 64-bit (10 Apr 2018) downloaded manually
ADD singularity/plink_linux_x86_64.zip /
RUN unzip /plink_linux_x86_64.zip -d /usr/bin/ && \
rm plink_linux_x86_64.zip

RUN mkdir /tsd /net /work /projects /cluster /proj /sw /scratch /meles
