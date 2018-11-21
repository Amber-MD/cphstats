#!/bin/bash

# Script to build cphstats in Travis builds

set -xev

if [ "$USE_CMAKE" = 1 ]; then

  # build with cmake
  mkdir -p build
  cd build
  cmake .. -DCOMPILER=manual

  make
  cp cphstats cestats ..
else

  # build with the configure script, which detects Travis's CXX environment variable
  ./configure
  make
fi
