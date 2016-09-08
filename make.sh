#!/bin/bash
GITHUB_USERNAME="jmonkeyengine"
BRANCH="master"
ROOT_MAKESH_GITHUB_USER="riccardobl"

rm -Rf root_tmp
mkdir -p root_tmp
wget  -q https://raw.githubusercontent.com/$ROOT_MAKESH_GITHUB_USER/jme3-bullet-builder/root/make.sh -O root_tmp/root.sh
source root_tmp/root.sh

main $@
