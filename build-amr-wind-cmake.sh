#!/bin/bash

error_exit() {
	echo "ERROR: $*"
	exit 1
}

BUILD_DIR=/scratch/$USER/amr-wind-build
INSTALL_DIR=/scratch/$USER/amr-wind/2024-07/x86_64/

cuda=0
if [ "$1" = "--cuda" ]; then
	cuda=1
	BUILD_DIR=/scratch/$USER/amr-wind-build-cuda
	INSTALL_DIR=/scratch/$USER/amr-wind/2024-07/x86_64_cuda/
	module restore
	source /nopt/nrel/apps/gpu_stack/env_cpe23.sh
	module load gcc
	module load PrgEnv-nvhpc
	module load cray-libsci/23.05.1.4
	module load craype-x86-genoa
	module load craype-accel-nvidia90
	module load cmake
	export MPICH_GPU_SUPPORT_ENABLED=1
	export CUDAFLAGS="-I${MPICH_DIR}/include -L${MPICH_DIR}/lib -lmpi ${PE_MPICH_GTL_DIR_nvidia90} ${PE_MPICH_GTL_LIBS_nvidia90}"
	export CXXFLAGS="-I${MPICH_DIR}/include -L${MPICH_DIR}/lib -lmpi ${PE_MPICH_GTL_DIR_nvidia90} ${PE_MPICH_GTL_LIBS_nvidia90}"
	#cmake -B amr-wind-build -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON -DAMR_WIND_ENABLE_TINY_PROFILE:BOOL=ON -DCMAKE_CXX_COMPILER:STRING=CC -DCMAKE_C_COMPILER:STRING=cc -DAMR_WIND_ENABLE_CUDA:BOOL=ON -DCMAKE_CUDA_ARCHITECTURES=90 -DAMR_WIND_ENABLE_MPI:BOOL=ON -DCMAKE_BUILD_TYPE:STRING=Release -DAMR_WIND_ENABLE_TESTS:BOOL=ON -DAMReX_DIFFERENT_COMPILER=ON amr-wind
	#cmake --build amr-wind-build --parallel 24

fi

echo BUILD_DIR is $BUILD_DIR
echo INSTALL_DIR IS $INSTALL_DIR

set -x

mkdir -p $BUILD_DIR >& /dev/null

cd $BUILD_DIR || error_exit "Unable to change directory to $BUILD_DIR"

if [ ! -d  amr-wind ]; then
	git clone --recurse-submodules git@github.com:hgopalan/amr-wind.git
	( cd amr-wind; git checkout hgopalan-terrain; git branch )
fi

cd amr-wind || error_exit "Unable to change directory to $BUILD_DIR/amr-wind"

mkdir build >& /dev/null

cd build || error_exit "Unable to change directory to $BUILD_DIR/amr-wind/build"

if [ $cuda -eq 1 ]; then
	BUILD_SETTINGS="-DCMAKE_VERBOSE_MAKEFILE:BOOL=ON -DAMR_WIND_ENABLE_TINY_PROFILE:BOOL=ON -DCMAKE_CXX_COMPILER:STRING=CC -DCMAKE_C_COMPILER:STRING=cc -DAMR_WIND_ENABLE_CUDA:BOOL=ON -DCMAKE_CUDA_ARCHITECTURES=90 -DAMR_WIND_ENABLE_MPI:BOOL=ON -DCMAKE_BUILD_TYPE:STRING=Release -DAMR_WIND_ENABLE_TESTS:BOOL=ON -DAMReX_DIFFERENT_COMPILER=ON -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR"
else
	BUILD_SETTINGS="-DAMR_WIND_ENABLE_MPI=ON -DAMR_WIND_ENABLE_NETCDF=ON -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR"
fi

if [ ! -f Makefile ]; then
	cmake $BUILD_SETTINGS ..
fi

module list

make -j 24

make install

exit 0

