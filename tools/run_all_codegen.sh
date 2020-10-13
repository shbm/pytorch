#!/bin/sh

# This script be used to test whether your diff changes any codegen output.
#
# Run it before and after your change:
#   tools/run_all_codegen.sh <baseline_output_dir>
#   tools/run_all_codegen.sh <test_output_dir>
#
# Then run diff to compare the generated files:
#   diff -Naur <baseline_output_dir> <test_output_dir>

set -eux -o pipefail

OUT=$1

rm -rf "$OUT"

# aten codegen
python -m tools.codegen.gen \
  -d "$OUT"/torch/share/ATen

# torch codegen
python -m tools.setup_helpers.generate_code \
  --declarations-path "$OUT"/torch/share/ATen/Declarations.yaml \
  --install_dir "$OUT"

# pyi codegen
mkdir -p "$OUT"/pyi/torch/_C
mkdir -p "$OUT"/pyi/torch/nn
python -m tools.pyi.gen_pyi \
  --declarations-path "$OUT"/torch/share/ATen/Declarations.yaml \
  --out "$OUT"/pyi

# autograd codegen (called by torch codegen but can run independently)
python -m tools.autograd.gen_autograd \
  "$OUT"/torch/share/ATen/Declarations.yaml \
  "$OUT"/autograd \
  tools/autograd

# unboxing_wrappers codegen (called by torch codegen but can run independently)
mkdir -p "$OUT"/unboxing_wrappers
python -m tools.jit.gen_unboxing_wrappers \
  "$OUT"/torch/share/ATen/Declarations.yaml \
  "$OUT"/unboxing_wrappers \
  tools/jit/templates

# annotated_fn_args codegen (called by torch codegen but can run independently)
mkdir -p "$OUT"/annotated_fn_args
python -m tools.autograd.gen_annotated_fn_args \
  "$OUT"/torch/share/ATen/Declarations.yaml \
  "$OUT"/annotated_fn_args \
  tools/autograd