#!/bin/bash

set -e

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
SCRIPTS_DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

CPP_DIR="${SCRIPTS_DIR}/../../cpp"
CPP_BUILD_DIR="${CPP_DIR}/cmake_build"
BUILD_TYPE="Debug"
BUILD_UNITTEST="OFF"
INSTALL_PREFIX="/var/lib/gis"
USE_GPU="OFF"
CUDA_COMPILER=/usr/local/cuda/bin/nvcc
PRIVILEGES="OFF"

while getopts "o:t:d:guph" arg
do
        case $arg in
             o)
                INSTALL_PREFIX=$OPTARG
                ;;

             t)
                BUILD_TYPE=$OPTARG # BUILD_TYPE
                ;;
             d)
                CPP_BUILD_DIR=$OPTARG # CPP_BUILD_DIR
                ;;
             g)
                USE_GPU="ON";
                ;;
             u)
                echo "Build and run unittest cases" ;
                BUILD_UNITTEST="ON";
                ;;
             p)
                PRIVILEGES="ON" # ELEVATED PRIVILEGES
                ;;
             h) # help
                echo "

parameter:
-o: install prefix(default: /var/lib/milvus)
-t: build type(default: Debug)
-d: cpp code build directory
-g: gpu version
-u: building unit test options(default: OFF)
-p: install command with elevated privileges
-h: help

usage:
./build.sh -o \${INSTALL_PREFIX} -t \${BUILD_TYPE} -d \${CPP_BUILD_DIR} [-g] [-u] [-p] [-h]
                "
                exit 0
                ;;
             ?)
                echo "ERROR! unknown argument"
        exit 1
        ;;
        esac
done

if [[ ! -d ${CPP_BUILD_DIR} ]]; then
    mkdir ${CPP_BUILD_DIR}
fi

cd ${CPP_BUILD_DIR}

CMAKE_CMD="cmake \
-DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} \
-DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
-DUSE_GPU=${USE_GPU} \
-DBUILD_UNITTEST=${BUILD_UNITTEST} \
-DCMAKE_CUDA_COMPILER=${CUDA_COMPILER} \
${CPP_DIR}
"
echo ${CMAKE_CMD}
${CMAKE_CMD}

# compile and build
make -j8 || exit 1

if [[ ${PRIVILEGES} == "ON" ]];then
    sudo make install || exit 1
else
    make install || exit 1
fi
