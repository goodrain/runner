#!/bin/bash
set -xe

release_version=5.1.2
git_commit=$(git log -n 1 --pretty --format=%h)

release_desc=${release_version}-${git_commit}

build::local(){
    
    sed "s/__RELEASE_DESC__/${release_desc}/" Dockerfile > Dockerfile.release
    docker build -t goodrain.me/runner -f Dockerfile.release .
    rm -rf Dockerfile.release
    if [ "$1" == "push" ]; then
        docker push goodrain.me/runner
    fi
}

build::public(){
    docker tag goodrain.me/runner rainbond/runner:${release_version}
    if [ "$TRAVIS_PULL_REQUEST" == "false" ]; then 
        docker push rainbond/runner:${release_version}
    fi
}

case $1 in
    local)
        build::local ${@:2}
    ;;
    *)
        build::local
        build::public
    ;;
esac
