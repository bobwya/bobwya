#!/bin/bash

PATCH="${1#*-}"
PATCH="${PATCH%-beta*}"
PATCH="${PATCH//-/_}"
PATCH="${PATCH/_/-}"
echo "${PATCH}"
unset PATCH

exit 0
