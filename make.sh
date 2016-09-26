#!/bin/bash
GITHUB_USERNAME="riccardobl"
BRANCH="frk"
ROOT_MAKESH_GITHUB_USER="riccardobl"

rm -Rf root_tmp
mkdir -p root_tmp

rm -Rf win
mkdir -p win
wget https://raw.githubusercontent.com/riccardobl/jme3-bullet-builder/root/win/jni_md.h -O win/jni_md.h
wget https://raw.githubusercontent.com/riccardobl/jme3-bullet-builder/root/win/jawt_md.h -O win/jawt_md.h

wget  -q https://raw.githubusercontent.com/$ROOT_MAKESH_GITHUB_USER/jme3-bullet-builder/root/make.sh -O root_tmp/root.sh
source root_tmp/root.sh

main $@
