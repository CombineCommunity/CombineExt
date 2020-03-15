#!/bin/sh

if ! which carthage > /dev/null; then
    echo 'Error: Carthage is not installed' >&2
    exit 1
fi

if ! which swift > /dev/null; then
    echo 'Swift is not installed' >&2
    exit 1
fi

carthage build --no-skip-current --platform iOS
carthage archive

echo "Upload CombineExt.framework.zip to the latest release"