#!/bin/bash

error_exit() {
	echo "ERROR: $*"
	exit 1
}

#BUILD_DIR=/scratch/$USER
BUILD_DIR=/apps/exawind/2024-06/x86_64/amr-wind-exawind-manager
cd $BUILD_DIR || error_exit "Unable to change directory to $BUILD_DIR"
echo "BUILD_DIR: $BUILD_DIR"
set -x
rm -rf exawind-cases exawind-manager

