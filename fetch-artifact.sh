#!/usr/bin/env bash

# Args:
# $1: container registry url
# $2: platform
# $3: output path

sha=$(oras manifest fetch $1 --platform $2 | jq '.layers.[0].digest' -r)
oras blob fetch $1@$sha --output $3
