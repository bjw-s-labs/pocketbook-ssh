#!/usr/bin/env bash
set -e

TOOLCHAIN_IMAGE="pocketbook-ssh-toolchain:latest"

docker buildx build --tag "${TOOLCHAIN_IMAGE}" . --load
docker run --rm -it -v "${PWD}/dist:/dist" "${TOOLCHAIN_IMAGE}" bash -c "cp /output/* /dist/"
