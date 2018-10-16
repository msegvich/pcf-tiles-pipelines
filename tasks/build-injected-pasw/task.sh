#!/bin/bash
set -eu

echo "Entering Build Injected PASW Task"

#Unzip the WinFS Injector
cd pivnet-winfs-injector
unzip "*winfs*"
chmod 700 winfs-injector-linux

#Find the original tile
cd ../pivnet-pasw
FILE_PATH=`find . -name *.pivotal | sort | head -1`


#Run the injector with the input as the original tile and output the winfs-injected tile
cd ../pivnet-winfs-injector
./winfs-injector-linux --input-tile ../pivnet-pasw/$FILE_PATH --output-tile ../pasw-injected/$FILE_PATH
