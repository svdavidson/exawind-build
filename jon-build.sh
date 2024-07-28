#!/bin/bash

error_exit() {
	echo "ERROR: $*"
	exit 1
}

BUILD_DIR=/scratch/$USER/amr-wind-build-cuda
INSTALL_DIR=/scratch/$USER/amr-wind/2024-07/x86_64_cuda/

cd $BUILD_DIR || error_exit "Unable to change directory to $BUILD_DIR"

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
cmake -B amr-wind-build -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON -DAMR_WIND_ENABLE_TINY_PROFILE:BOOL=ON -DCMAKE_CXX_COMPILER:STRING=CC -DCMAKE_C_COMPILER:STRING=cc -DAMR_WIND_ENABLE_CUDA:BOOL=ON -DCMAKE_CUDA_ARCHITECTURES=90 -DAMR_WIND_ENABLE_MPI:BOOL=ON -DCMAKE_BUILD_TYPE:STRING=Release -DAMR_WIND_ENABLE_TESTS:BOOL=ON -DAMReX_DIFFERENT_COMPILER=ON -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR amr-wind
cmake --build amr-wind-build --parallel 24

