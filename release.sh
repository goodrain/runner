#!/bin/bash
set -xe

image_name="runner"
release_type=$1

if [ "$release_type" == "" ];then
  echo "please input release type (community | enterprise | all )"
  exit 1
elif [ "$release_type" == "all" ];then
  enterprise_version=$2
  community_version=$3
else
  release_version=$2
fi

trap 'clean_tmp; exit' QUIT TERM EXIT

# clear temp file
function clean_tmp() {
  echo "clean temporary file..."
  [ -f Dockerfile.release ] && rm -rf Dockerfile.release
}

function release(){
  release_name=$1      # master | enterprise | community
  release_version=${2:-latest}   # latest | 3.2 | 2017.05
  
  if [ "$release_name" == "master" ];then
    branch_name=${release_name}
    git checkout ${branch_name}
  else
    branch_name=${release_name}-${release_version}
    git checkout ${branch_name}
  fi
  
  echo "Pull newest code..." && sleep 3
  git pull

  # get commit sha
  git_commit=$(git log -n 1 --pretty --format=%h)


  # get git describe info
  release_desc=${release_name}-${release_version}-${git_commit}

  sed "s/__RELEASE_DESC__/${release_desc}/" Dockerfile > Dockerfile.release

  docker build -t hub.goodrain.com/dc-deploy/${image_name}:${release_version} -f Dockerfile.release .
  docker push hub.goodrain.com/dc-deploy/${image_name}:${release_version}
}

case $release_type in
"community")
    release $1 ${release_version}
    ;;
"enterprise")
    release $1 ${release_version}
    ;;
"master")
    release $1
    ;;
esac
