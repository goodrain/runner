#!/bin/bash
# make stdout colorful 
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m' # No Color

function addPath() {
    # run this function for add path to $PATH
    # make binary which built in /app executable by default
    local path=""
    for bindir in $(find /app/ -type d -name "*bin" | grep -v "with_")
    do 
    path=$bindir:$path
    done
    echo "export PATH=$path$PATH" > ~/.bashrc
}

info() {
    echo -e "${GREEN}       $@${NC}"
}

warn() {
    echo -e "${YELLOW} !!    $@${NC}"
}

err() {
    echo -e >&2 "${RED} !!    $@${NC}"
}