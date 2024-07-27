#!/bin/bash

error_exit() {
	echo "ERROR: $*"
	exit 1
}

set -x

BUILD_DIR=/scratch/$USER/amr-wind-build
INSTALL_DIR=/scratch/$USER/amr-wind/2024-07/x86_64/

cuda=0
if [ "$1" = "--cuda" ]; then
	cuda=1
	BUILD_DIR=/scratch/$USER/amr-wind-build-cuda
	INSTALL_DIR=/scratch/$USER/amr-wind/2024-07/x86_64_cuda/
	module load cuda/12.3
fi

mkdir -p $BUILD_DIR >& /dev/null

cd $BUILD_DIR || error_exit "Unable to change directory to $BUILD_DIR"

if [ ! -d  amr-wind ]; then
	git clone --recurse-submodules git@github.com:hgopalan/amr-wind.git
	( cd amr-wind; git checkout hgopalan-terrain; git branch )
fi

cd amr-wind || error_exit "Unable to change directory to $BUILD_DIR/amr-wind"

mkdir build >& /dev/null

cd build || error_exit "Unable to change directory to $BUILD_DIR/amr-wind/build"

BUILD_SETTINGS="-D AMR_WIND_ENABLE_MPI=ON -D AMR_WIND_ENABLE_NETCDF=ON -D CMAKE_INSTALL_PREFIX=$INSTALL_DIR"

if [ $cuda -eq 1 ]; then
	BUILD_SETTINGS="$BUILD_SETTINGS -D AMR_WIND_ENABLE_CUDA=ON"
fi

if [ ! -f Makefile ]; then
	cmake $BUILD_SETTINGS ..
fi

make -j 24

make install

exit 0

