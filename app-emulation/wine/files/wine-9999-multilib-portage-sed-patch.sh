#!/bin/bash

for ARCH in "m32" "m64"; do
	sed -i '/CXX="\$CXX -'"${ARCH}"'"/a \
      CFLAGS="$CFLAGS -'"${ARCH}"'"\
      LDFLAGS="$LDFLAGS -'"${ARCH}"'"\
      CXXFLAGS="$CXXFLAGS -m'"${ARCH}"'"' configure.ac \
		|| die "sed failed to add Portage multilib support"
done
unset ARCH

