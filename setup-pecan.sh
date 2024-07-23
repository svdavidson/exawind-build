
BUILD_DIR=/apps/exawind/2024-06/x86_64/amr-wind-exawind-manager
module load anaconda3/2022.10
module load gcc/8.2.0
export EXAWIND_MANAGER=$BUILD_DIR/exawind-manager
source ${EXAWIND_MANAGER}/start.sh && spack-start
spack env activate exawind-pecan
spack load exawind~amr_wind_gpu~nalu_wind_gpu

