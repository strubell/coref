module load cuda75/toolkit
module load openmpi/gcc
module load hdf5
module load fftw2
module load cudnn/5.0
module load cuda90/toolkit
module load cuda90/blas
module load cuda90/fft
module load cudnn/7.1-cuda_9.0
module load python3/3.6.5-1804

export CUDA_HOME=$CUDA_PATH
export DATA_DIR=/home/nnayak/spanbert_data
export data_dir=$DATA_DIR
