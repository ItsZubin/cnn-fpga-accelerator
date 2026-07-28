#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Run the self-checking testbenches.
#
#   ./scripts/run_sim.sh            # run every testbench
#   ./scripts/run_sim.sh tb_pe      # run one
#
# Uses Vivado's xsim if it is on PATH, otherwise falls back to Icarus Verilog.
# The unit testbenches (tb_pe, tb_relu, tb_acc, tb_pooling) need no IP. The
# top-level testbench uses the behavioural RAM models in
# tb/dist_mem_gen_model.sv, so it also runs from a clean clone.
#
# Exit status is non-zero if any testbench fails.
# ---------------------------------------------------------------------------
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$ROOT/sim_work"
ALL_TB=(tb_pe tb_relu tb_acc tb_pooling tb_top)

if [ $# -gt 0 ]; then
    TBS=("$@")
else
    TBS=("${ALL_TB[@]}")
fi

RTL=("$ROOT"/rtl/*.sv)
MODELS=("$ROOT/tb/dist_mem_gen_model.sv")

mkdir -p "$WORK"
cd "$WORK" || exit 1

failed=()
passed=()

run_xsim() {
    local tb="$1"
    xvlog -sv -nolog "${RTL[@]}" "${MODELS[@]}" "$ROOT/tb/$tb.sv" >/dev/null 2>&1 || return 1
    xelab -debug off -nolog "$tb" -s "${tb}_snap" >/dev/null 2>&1 || return 1
    xsim "${tb}_snap" -runall -nolog
}

run_iverilog() {
    local tb="$1"
    iverilog -g2012 -o "$tb.vvp" "${RTL[@]}" "${MODELS[@]}" "$ROOT/tb/$tb.sv" || return 1
    vvp "$tb.vvp"
}

if command -v xvlog >/dev/null 2>&1; then
    SIM="xsim"
elif command -v iverilog >/dev/null 2>&1; then
    SIM="iverilog"
else
    echo "ERROR: no simulator found. Install Vivado (xsim) or Icarus Verilog." >&2
    exit 127
fi

echo "simulator: $SIM"
echo

for tb in "${TBS[@]}"; do
    echo "=============================================="
    echo " running $tb"
    echo "=============================================="
    if [ "$SIM" = "xsim" ]; then
        out=$(run_xsim "$tb" 2>&1); rc=$?
    else
        out=$(run_iverilog "$tb" 2>&1); rc=$?
    fi
    echo "$out"
    if [ $rc -ne 0 ] || echo "$out" | grep -q "RESULT: FAIL"; then
        failed+=("$tb")
    else
        passed+=("$tb")
    fi
    echo
done

echo "=============================================="
echo " summary"
echo "=============================================="
for t in "${passed[@]:-}"; do [ -n "$t" ] && echo "  PASS  $t"; done
for t in "${failed[@]:-}"; do [ -n "$t" ] && echo "  FAIL  $t"; done

if [ ${#failed[@]} -gt 0 ]; then
    exit 1
fi
echo "  all testbenches passed"
