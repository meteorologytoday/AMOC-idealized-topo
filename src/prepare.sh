#!/bin/bash

casedir=$1
input_dir=$( realpath -s ../input )

echo "casedir $1"
echo "input dir $input_dir"

cd $casedir
cp -i $input_dir/data .
ln -s $input_dir/data.* .
ln -s $input_dir/eedata* .

ln -s $MITGCM_ROOTDIR/utils/python/MITgcmutils/scripts/gluemncbig .
