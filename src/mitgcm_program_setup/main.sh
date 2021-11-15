#!/bin/bash

mkdir build_mpi
cd build_mpi

$MITGCMTOOLS/genmake2 -mods ../code -mpi -of $MITGCMTOOLS/build_options/linux_amd64_gfortran


