#!/bin/sh
# config
url=ftp://ftp.astron.com/pri/file-nightly.tar.gz

# code
set -e
dir=$(dirname "$0")
cd "$dir"

if [ ! -f file-nightly.tar.gz ]; then
	wget -nv $url -O file-nightly.tar.gz
fi

if [ ! -d cvs/file ]; then
	install -d cvs/CVSROOT
	cd cvs
	tar -xzf ../file-nightly.tar.gz
	cd ..
fi

if [ ! -f file.blob ]; then
	cvs2git --use-rcs --blobfile=file.blob --dumpfile=file.dump --username=$USER --encoding=iso8859-1 cvs
fi

if [ ! -d git ]; then
	install -d git
	cd git
	git init
	cd ..
fi

cd git
git fast-import --export-marks=../file.marks < ../file.blob
git fast-import --import-marks=../file.marks < ../file.dump
git checkout master
cd ..
