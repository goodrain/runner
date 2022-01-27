#!/bin/bash
set -xe

release_version=${RELEASE_VERSION:-"v5.5.0-release"}
git_commit=$(git log -n 1 --pretty --format=%h)

release_desc=${release_version}-${git_commit}
DOMESTIC_BASE_NAME=${DOMESTIC_BASE_NAME:-'registry.cn-hangzhou.aliyuncs.com'}
DOMESTIC_NAMESPACE=${DOMESTIC_NAMESPACE:-'goodrain'}

build::local() {

    sed "s/__RELEASE_DESC__/${release_desc}/" Dockerfile >Dockerfile.release
    docker build -t goodrain.me/runner -f Dockerfile.release .
    rm -rf Dockerfile.release
    if [ "$1" == "push" ]; then
        docker push goodrain.me/runner
    fi
}

build::public() {
    docker tag goodrain.me/runner rainbond/runner:${release_version}
    docker tag goodrain.me/runner rainbond/runner
    if [ "$TRAVIS_PULL_REQUEST" == "false" ]; then
        docker push rainbond/runner:${release_version}
        docker push rainbond/runner
    fi
    if [ "${DOMESTIC_BASE_NAME}" ]; then
        new_tag="${DOMESTIC_BASE_NAME}/${DOMESTIC_NAMESPACE}/runner:${release_version}"
        # for amd64 and arm64
        if [ $(arch) == "x86_64" ]; then
            new_tag=${new_tag}
        elif [ $(arch) == "arm64" ] || [ $(arch) == "aarch64" ]; then
            new_tag=${new_tag}-arm64
        fi
        docker tag goodrain.me/runner "$new_tag"
        docker login -u "$DOMESTIC_DOCKER_USERNAME" -p "$DOMESTIC_DOCKER_PASSWORD" "${DOMESTIC_BASE_NAME}"
        docker push "$new_tag"
    fi
}

# create manifest for amd64 and arm64 with same name, push them to aliyun registry.
# this function should run after image pushed.
# manifest will be named like     example/runner:v5.5.0-release
# amd64 images will be named like example/runner:v5.5.0-release
# arm64 images will be named like example/runner:v5.5.0-release-arm64
# manifest list can not be recreated except the image example/runner:v5.5.0-release has been re-pushed.
build::manifest() {
    new_tag="${DOMESTIC_BASE_NAME}/${DOMESTIC_NAMESPACE}/runner:${release_version}"
    docker login -u "$DOMESTIC_DOCKER_USERNAME" -p "$DOMESTIC_DOCKER_PASSWORD" "${DOMESTIC_BASE_NAME}"
    docker manifest create $new_tag $new_tag $new_tag-arm64
    docker manifest annotate $new_tag $new_tag --os linux --arch amd64
    docker manifest annotate $new_tag $new_tag-arm64 --os linux --arch arm64 --variant v8
    docker manifest push $new_tag
    docker manifest rm $new_tag
}

case $1 in
local)
    build::local ${@:2}
    ;;
manifest)
    build::manifest
    ;;
*)
    build::local
    build::public
    ;;
esac
