#!/bin/sh
# config

# source for import:
# "url": a tarball snapshot
#url=ftp://ftp.astron.com/pri/file-nightly.tar.gz

# "rsync" use rsync
# for rsync, you need to setup ~/.ssh/config:
#Host file
#	Hostname address.from.where.to.sync
#	ForwardAgent no
#	User		glen
rsync=file:file

# git url where to push
push_url=git@github.com:file/file.git

# code
set -e
dir=$(dirname "$0")
cd "$dir"

# precaution not to run it accidentally as root
if [ $(stat -c %u .) != $(id -u) ]; then
	echo >&2 "You (`id -un`) not owner (`stat -c %U .`) of this dir (`pwd`), aborting"
	exit 1
fi

# load ssh key
if [ -f /usr/share/okas/ssh-auth-sock ]; then
	. /usr/share/okas/ssh-auth-sock
	ssh-auth-sock
fi

if [ -n "$rsync" ]; then
	rsync -axSH -e ssh "$rsync/" cvs/file/
else
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
fi

out=$(git -c i18n.commitencoding=iso8859-1 cvsimport -d $(pwd)/cvs -R -A file.users -C git file 2>&1)

# filter out common noise. must be separate subshell to catch errors from git command
out=$(echo "$out" | sed -e '/Skipping #CVSPS_NO_BRANCH/d')

if [ "$out" = "Already up-to-date." ]; then
	exit 0
fi

echo "$out"

cd git
if ! git config remote.origin.url >/dev/null; then
	git remote add origin $push_url
	git push --mirror
fi

git push origin refs/heads/master refs/tags/*
cd ..
