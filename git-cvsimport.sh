#!/bin/sh
# config
url=ftp://ftp.astron.com/pri/file-nightly.tar.gz
push_url=git@github.com:glensc/file.git

# code
set -e
dir=$(dirname "$0")
cd "$dir"

# precaution not to load run it accidentally as root
if [ $(stat -c %u .) != $(id -u) ]; then
	echo >&2 "You (`id -un`) not owner (`stat -c %U .`) of this dir (`pwd`), aborting"
	exit 1
fi

if [ "$1" = "update" ]; then
	rm -f file-nightly.tar.gz
fi

if [ ! -f file-nightly.tar.gz ]; then
	wget -q $url -O .tmp.$$.tgz
	if [ -d cvs/file ]; then
		mv cvs/file .tmp.$$.file
		rm -rf .tmp.$$.file &
	fi
   	mv -f .tmp.$$.tgz file-nightly.tar.gz
fi

if [ ! -d cvs/file ]; then
	install -d cvs/CVSROOT
	cd cvs
	tar -xzf ../file-nightly.tar.gz
	cd ..
fi

out=$(git -c i18n.commitencoding=iso8859-1 cvsimport -d $(pwd)/cvs -R -A file.users -C git file)
echo "$out"

if [ "$out" = "Already up-to-date." ]; then
	exit 0
fi

# load ssh key
if [ -f /usr/share/okas/ssh-auth-sock ]; then
	. /usr/share/okas/ssh-auth-sock
	ssh-auth-sock
fi

cd git
if [ "$(git remote | grep -c origin)" = 0 ]; then
	git remote add origin $push_url
	git push --mirror
fi

git push origin refs/heads/master refs/tags/*
cd ..
