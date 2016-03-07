#!/bin/bash

sed -i -e 's/  if \(__GNUC__ > 5\) \|\| \(\(__GNUC__ == 5\) \&\& \(__GNUC_MINOR__ >= 3\)\)/  if (__GNUC__ > 5)/g' \
		include/windef.h

