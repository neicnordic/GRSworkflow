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

RUN cd /usr/bin/ && \
wget https://www.cog-genomics.org/static/bin/plink180221/plink_linux_x86_64.zip && \
unzip plink_linux_x86_64.zip && \
rm plink_linux_x86_64.zip

RUN pip install \
numpy==1.12.1 \
pandas==0.20.1 \
scipy==1.0.0 \
bitarray==0.8.1 \
nose==1.3.7

RUN git clone https://github.com/bulik/ldsc && \
git clone https://github.com/precimed/python_convert

RUN mkdir /tsd /net /work /projects /cluster /proj /sw /scratch /meles
