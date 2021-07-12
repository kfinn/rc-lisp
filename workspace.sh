#!/bin/sh

docker run \
  -ti \
  -v "$(pwd):/workspace" \
  -v "$JAI_HOME:/jai" \
  -w /workspace \
  jai-workspace \
  bash
