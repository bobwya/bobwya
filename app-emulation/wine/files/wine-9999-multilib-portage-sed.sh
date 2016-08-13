#!/bin/bash

for ARCH in "m32" "m64"; do
	sed -i '/CXX="\$CXX -'"${ARCH}"'"/a \
      CFLAGS="$CFLAGS -'"${ARCH}"'"\
      LDFLAGS="$LDFLAGS -'"${ARCH}"'"\
      CXXFLAGS="$CXXFLAGS -m'"${ARCH}"'"' configure.ac || exit 1
done
unset ARCH

exit 0
