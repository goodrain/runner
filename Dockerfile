FROM rainbond/cedar14
MAINTAINER ethan <ethan@goodrain.me>

RUN echo "Asia/Shanghai" > /etc/timezone;dpkg-reconfigure -f noninteractive tzdata

RUN set -x \
    && apt-get update \
    && apt-get install --no-install-recommends --no-install-suggests -y apt-transport-https ca-certificates procps curl net-tools rsync \
    && rm -rf /var/lib/apt/lists/* 

ENV HOME /app

RUN mkdir /app
RUN addgroup --quiet --gid 200 rain && \
    useradd rain --uid=200 --gid=200 --home-dir /app --no-create-home \
        --shell /bin/bash
RUN chown rain:rain /app
WORKDIR /app

# download webapp-runner for java-war
RUN wget http://buildpack.oss-cn-shanghai.aliyuncs.com/java/webapp-runner/webapp-runner-8.5.38.0.jar -O /opt/webapp-runner.jar

# add default port to expose (can be overridden)
ENV PORT 5000
ENV RELEASE_DESC=__RELEASE_DESC__

EXPOSE 5000

RUN chmod 1777 /run && usermod  -G crontab rain && chmod u+s /usr/bin/crontab && chmod u+s /usr/sbin/cron

RUN mkdir /data && chown rain:rain /data

ADD ./runner /runner
RUN chown rain:rain /runner/init
#USER rain
ENTRYPOINT ["/runner/init"]
