
BUILD_DIR=/scratch/$USER/amr-wind-exawind-manager
export SPACK_PYTHON=python3.10
export EXAWIND_MANAGER=$BUILD_DIR/exawind-manager
source ${EXAWIND_MANAGER}/start.sh && spack-start
spack env activate exawind-kestrel
spack load amr-wind nalu-wind

