#!/usr/bin/env bash
set -e

TOOLCHAIN_IMAGE="pocketbook-ssh-toolchain:latest"

docker buildx build --progress plain --tag "${TOOLCHAIN_IMAGE}" . --load
docker run --rm -it -v "${PWD}/dist:/dist" "${TOOLCHAIN_IMAGE}" bash -c "cp /output/bin/* /dist/"
