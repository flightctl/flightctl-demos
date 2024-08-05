#!/usr/bin/env bash

# Args:
# $1: container url
# $2: platform
# $3: output path

if [ $# -ne 3 ]; then
	echo "$0 <container url> <platform> <output path>"
	exit 1
fi

sha=$(oras manifest fetch $1 --platform $2 | jq '.layers.[0].digest' -r)
oras blob fetch $1@$sha --output $3
