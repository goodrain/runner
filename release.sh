#!/bin/bash
set -xe

release_version=5.1.0
git_commit=$(git log -n 1 --pretty --format=%h)

release_desc=${release_version}-${git_commit}

sed "s/__RELEASE_DESC__/${release_desc}/" Dockerfile > Dockerfile.release

docker build -t rainbond/runner:${release_version} -f Dockerfile.release .
docker push rainbond/runner:${release_version}
