FROM hub.goodrain.com/dc-deploy/cedar14
MAINTAINER ethan <ethan@goodrain.me>

# 时区设置
RUN echo "Asia/Shanghai" > /etc/timezone;dpkg-reconfigure -f noninteractive tzdata

ENV HOME /app

RUN mkdir /app
RUN addgroup --quiet --gid 200 rain && \
    useradd rain --uid=200 --gid=200 --home-dir /app --no-create-home \
        --shell /bin/bash
RUN chown rain:rain /app
WORKDIR /app

# 创建goodrain程序目录
#RUN mkdir -pv /opt/bin

# 下载grproxy,每次升级需要重新创建runner镜像
#RUN wget http://lang.goodrain.me/public/gr-listener -O /opt/bin/gr-listener

# 添加可执行权限
#RUN chmod +x /opt/bin/*

#ADD ./profile.d /tmp/profile.d


# add default port to expose (can be overridden)
ENV PORT 5000
ENV RELEASE_DESC=__RELEASE_DESC__

EXPOSE 5000

# 配置crontab 权限
RUN chmod 1777 /run && usermod  -G crontab rain && chmod u+s /usr/bin/crontab && chmod u+s /usr/sbin/cron

RUN mkdir /data && chown rain:rain /data

ADD ./runner /runner
RUN chown rain:rain /runner/init
USER rain
ENTRYPOINT ["/runner/init"]
