FROM balenalib/aarch64-debian-python

RUN install_packages \
    kmod \
    libiio0 \
    libiio-utils \
    python3-libiio

WORKDIR /usr/src/app

COPY run.sh ./

RUN pip3 install flask

COPY server.py ./
