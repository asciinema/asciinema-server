#!/usr/bin/env bash

set -e

apt-get update
apt-get install -y libpng16-dev wget build-essential

tmp_dir=$(mktemp -d 2>/dev/null || mktemp -d -t 'pngquant')
trap 'rm -rf $tmp_dir' EXIT
cd $tmp_dir

wget https://github.com/pornel/pngquant/archive/2.9.1.tar.gz -O pngquant.tar.gz
wget https://github.com/ImageOptim/libimagequant/archive/2.9.1.tar.gz -O libimagequant.tar.gz

tar xzf pngquant.tar.gz
tar xzf libimagequant.tar.gz
mv libimagequant-*/* pngquant-*/lib/

cd pngquant-*
./configure && make && make install
