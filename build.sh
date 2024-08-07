#!/bin/bash

error_exit() {
	echo "ERROR: $*"
	exit 1
}

spack_cmd() {
    echo running: spack $*
    spack $*
}

usage_exit() {
    if [ $# -gt 0 ]; then
        echo $@
    fi
    echo "USAGE: $program [--pecan | --pine | --kestrel | --delete --main]"
    exit 1
}

hostname=$(hostname --short)
original_dir=$(pwd)
program=$(basename $0)
delete=0
main=0
build_type=unknown
while [ $# -ge 1 ]; do
    case "$1" in
    --pecan)   build_type="pecan";;
    --pine)    build_type="pine";;
    --kestrel) build_type="kestrel";;
    --delete)  delete=1;;
    --main)    main=1;;
    --help)    usage_exit;;
    *)         usage_exit "Unknown option - $1";;
    esac
    shift
done

export SPACK_PYTHON=python3


if [ $main -eq 1 ]; then
	BUILD_BASE=exawind-manager-main
else
	BUILD_BASE=exawind-manager
fi

case $build_type in

    pecan)
        [ "$hostname" != "pecan-1" ] && error_exit "Please build on pecan-1"
        BUILD_DIR=/apps/exawind/2024-08/x86_64/$BUILD_BASE
        ;;

    pine)
        [ "$hostname" != "pine-1" ] && error_exit "Please build on pine-1"
        BUILD_DIR=/apps/exawind/2024-08/genoa_x86_64/$BUILD_BASE
        ;;

    kestrel)
        [ "$hostname" != "kl1" ] && error_exit "Please build on kl1"
	BUILD_DIR=/scratch/$USER/2024-08/x86_64/$BUILD_BASE
        ;;

    *)
        usage_exit "You must specify the build type"
        ;;

esac

echo BUILD_DIR is $BUILD_DIR

# handle request to delete installation
if [ $delete -eq 1 ]; then
    echo "Deleting Exawind from $BUILD_DIR"
    [ -z "$BUILD_DIR" ] && error_exit "BUILD_DIR is not set"
    cd $BUILD_DIR || error_exit "Unable to change directory to $BUILD_DIR"
    set -x
    rm -rf exawind-cases exawind-manager
    exit 0
fi

# runtime environment
case $build_type in

    pecan)
        module load anaconda3/2022.10
        module load gcc/8.2.0
        ;;

    pine)
        ;;

    kestrel)
	export SPACK_PYTHON=python3.10
	module purge
        #module load PrgEnv-intel/8.5.0
        #module load libfabric/1.15.2.0
        #module load cray-libsci/23.12.5
        #module load intel/2023.2.0
        #module load craype-network-ofi
        #module load craype-x86-spr
        #module load cray-mpich/8.1.28
        #module load netcdf-c/4.9.2-cray-mpich-intel
        #export LD_LIBRARY_PATH=/projects/hpesupport/cray-mpich-stall/libs_mpich_nrel_intel:$LD_LIBRARY_PATH
        export MPICH_OFI_CQ_STALL=1
        export MPICH_OFI_CQ_STALL_USECS=16
        export HDF5_USE_FILE_LOCKING=FALSE
        ;;

    *)  ;;

esac

# create build directory
mkdir -p $BUILD_DIR >& /dev/null
cd $BUILD_DIR || error_exit "Unable to change directory to $BUILD_DIR"

# install Exawind Manager
if [ ! -d exawind-manager ]; then
	if [ $main -eq 1 ]; then
		git clone --recursive https://github.com/Exawind/exawind-manager.git exawind-manager
	else
		git clone --recursive https://github.com/svdavidson/exawind-manager-buildtest.git exawind-manager
	fi
fi

# install Exawind Test Cases
if [ ! -d exawind-cases ]; then
	#git clone https://github.com/Exawind/exawind-cases.git
        git clone https://github.com/svdavidson/exawind-cases-updates.git exawind-cases
fi

# build
#export SPACK_PYTHON=python3
cd exawind-manager
source shortcut.sh

if [ "$build_type" = "pecan" ]; then
     # Need gcc 9.3.0
    export COMPILER=gcc
    export SPACK_COMPILER=gcc@9.3.0
    if ! spack_cmd load $SPACK_COMPILER; then
        spack_cmd install $SPACK_COMPILER
        spack_cmd load $SPACK_COMPILER
        spack_cmd compiler add
        spack_cmd compilers
        echo gcc is $(which gcc)
        gcc --version
    fi
fi

nice deploy.py --ranks 40 --depfile --name exawind-$build_type --overwrite |& tee build.out

cd $original_dir || error_exit "Could not change directory to $original_dir"

cp *.sh $BUILD_DIR || error_exit "Could not copy scripts to $BUILD_DIR"

exit 0

# sphere test
cd -
cd exawind-cases/sphere
qsub ./run-kestrel.sh

# single turbine test
cd -
cd exawind-cases/single-turbine
qsub ./run-kestrel.sh


