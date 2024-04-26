FROM debian:latest as base
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y python3 \
    python3-pip \
    dnsutils \
    curl \
    git \
    jq \
    parallel \
    locales \
    unzip \
    wget && \
    apt-get clean autoclean && \
    apt-get autoremove
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8
ENV LANG en_US.UTF-8
RUN pip3 install --break-system-packages --upgrade pip && \
    pip3 install --break-system-packages black jsonschema publicsuffixlist
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install

# For VScode development purposes
FROM base AS vscode_dev
RUN addgroup --gid 1000 vscode
RUN adduser --disabled-password --gecos "" --uid 1000 --gid 1000 vscode
ENV HOME /home/vscode
USER vscode

# For crawler
FROM base as crawler
WORKDIR /crawler
COPY ./ /crawler
ENTRYPOINT ["./crawl_crux.sh"]