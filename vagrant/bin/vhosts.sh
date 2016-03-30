#!/usr/bin/env bash

set -e
vagrant ssh -- vhosts.sh "$@"
