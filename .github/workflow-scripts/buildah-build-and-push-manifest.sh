#!/usr/bin/env bash

cd /bootc-images
buildah manifest create bootc-images
buildah login \
	-u "$BUILDAH_USERNAME" \
	-p "$BUILDAH_PASSWORD" \
	"$(echo $BUILDAH_URL | cut -d "/" -f 1)"

rm buildah-build-and-push-manifest.sh
for FILE in *; do
	ARCH=$(echo $FILE | cut -d "-" -f 1)
	FORMAT=$(echo $FILE | cut -d "-" -f 2)
	
	buildah manifest add bootc-images \
		--artifact $FILE \
		--artifact-type application/vnd.diskimage+$FORMAT \
		--os $FORMAT \
		--arch $ARCH
done

buildah manifest push --all bootc-images docker://$BUILDAH_URL
