#!/usr/bin/env bash
# Local firmware build using the ZMK Docker toolchain.
# Builds against the local zmk fork in ../zmk and the local zmk-rgb-matrix
# module in ../zmk-rgb-matrix (west workspace = parent dir).
# Output: ../firmware/sofle_{left,right}.uf2
#
# Usage: ./build.sh [left|right]   (default: both)
set -euo pipefail

WORKSPACE="$(cd "$(dirname "$0")/.." && pwd)"
IMAGE="zmkfirmware/zmk-build-arm:stable"
BOARD="nice_nano@2.0.0//zmk"
SIDES="${1:-left right}"

docker run --rm -v "$WORKSPACE:/work" -w /work "$IMAGE" bash -euc "
  git config --global --add safe.directory '*'
  # Workspace root is /work (not zmk/), so zephyr + modules live next to the fork.
  if [ ! -d .west ]; then
    mkdir .west && printf '[manifest]\npath = zmk/app\nfile = west.yml\n' > .west/config
  fi
  if [ ! -d zephyr ]; then west update --narrow --fetch-opt=--depth=1; fi
  west zephyr-export >/dev/null
  for side in $SIDES; do
    snippet=''
    if [ \"\$side\" = left ]; then snippet='-S studio-rpc-usb-uart'; fi
    west build -p -s zmk/app -d build/\$side -b '$BOARD' \$snippet -- \
      -DSHIELD=sofle_\$side -DZMK_CONFIG=/work/nomad_sofle/config \
      -DZMK_EXTRA_MODULES=/work/zmk-rgb-matrix
    mkdir -p firmware
    cp build/\$side/zephyr/zmk.uf2 firmware/sofle_\$side.uf2
  done
"

ls -l "$WORKSPACE"/firmware/*.uf2
