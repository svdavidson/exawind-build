#!/bin/bash

#set -x
base=$(basename $(pwd))
host=$(hostname --short)
arch=$(arch)
tgzfile=${base}-${host}-${arch}-scripts.tgz
cd ..

#tar cvfz $tgzfile ${base}/*.sh ${base}/*.yaml
tar cvfz $tgzfile ${base}/*.sh
echo Created $(pwd)/$tgzfile


