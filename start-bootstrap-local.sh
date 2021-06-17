#!/usr/bin/env sh

CWD=$(realpath $(dirname $0))

bash -a "${CWD}/bootstrap/docker-entrypoint.sh" "${@}"
