FROM registry.cn-hangzhou.aliyuncs.com/goodrain/stack-image:22
ARG RELEASE_DESC

ENV TZ=Asia/Shanghai

RUN set -x \
    && apt-get update \
    && apt-get install --no-install-recommends --no-install-suggests -y libpng16-16 fonts-dejavu apt-transport-https ca-certificates procps net-tools gettext-base rsync language-pack-zh-hans \
    && rm -rf /var/lib/apt/lists/* 

ENV HOME /app

RUN mkdir /app \
    && addgroup --quiet --gid 200 rain \
    && useradd rain --uid=200 --gid=200 --home-dir /app --no-create-home \
        --shell /bin/bash \
    && chown rain:rain /app
WORKDIR /app

# download webapp-runner for java-war
RUN wget http://buildpack.rainbond.com/java/webapp-runner/webapp-runner-8.5.38.0.jar -O /opt/webapp-runner.jar && \
    if [ $(arch) = "arm64" ] || [ $(arch) = "aarch64" ]; then \
        wget https://pkg.goodrain.com/pkg/tini/v0.19.0/tini-arm -O /bin/tini && chmod +x /bin/tini; \
    else \
        wget https://pkg.goodrain.com/pkg/tini/v0.19.0/tini -O /bin/tini && chmod +x /bin/tini; \
    fi

# add default port to expose (can be overridden)
ENV PORT 5000
ENV RELEASE_DESC=${RELEASE_DESC}

EXPOSE 5000

ADD ./runner /runner
RUN chown rain:rain /runner/init

ENV LANG="zh_CN.UTF-8"
ENV LANGUAGE="zh_CN:zh:en_US:en"

#USER rain
ENTRYPOINT ["/runner/init"]
