FROM rainbond/cedar14
MAINTAINER ethan <ethan@goodrain.me>

RUN echo "Asia/Shanghai" > /etc/timezone;dpkg-reconfigure -f noninteractive tzdata

RUN set -x \
    && apt-get update \
    && apt-get -y install language-pack-zh-hans \
    && apt-get install --no-install-recommends --no-install-suggests -y ttf-dejavu apt-transport-https ca-certificates procps curl net-tools rsync \
    && rm -rf /var/lib/apt/lists/* 

ENV HOME /app

RUN mkdir /app \
    && addgroup --quiet --gid 200 rain \
    && useradd rain --uid=200 --gid=200 --home-dir /app --no-create-home \
        --shell /bin/bash \
    && chown rain:rain /app
WORKDIR /app

# download webapp-runner for java-war
RUN wget http://buildpack.oss-cn-shanghai.aliyuncs.com/java/webapp-runner/webapp-runner-8.5.38.0.jar -O /opt/webapp-runner.jar

# add default port to expose (can be overridden)
ENV PORT 5000
ENV RELEASE_DESC=__RELEASE_DESC__

EXPOSE 5000

RUN chmod 1777 /run && usermod  -G crontab rain && chmod u+s /usr/bin/crontab && chmod u+s /usr/sbin/cron \
    && mkdir /data && chown rain:rain /data

ADD ./runner /runner
RUN chown rain:rain /runner/init

## install libpng16 for ubuntu14.04 

RUN wget https://jaist.dl.sourceforge.net/project/libpng/libpng16/1.6.37/libpng-1.6.37.tar.xz \
    && tar -xf libpng-1.6.37.tar.xz \
    && cd libpng-1.6.37 && ./configure && make check && make install && ldconfig \
    && cd ../ && rm -rf libpng-1.6.37.tar.xz && rm -rf libpng-1.6.37

ENV LANG='zh_CN.utf8'
#USER rain
ENTRYPOINT ["/runner/init"]
