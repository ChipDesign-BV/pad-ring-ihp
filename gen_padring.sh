#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# Koen Van Caekenberghe (koen.vancaekenberghe@chipdesign.be), ChipDesign B.V., 07.2026
# ==========================================================================
# gen_padring.sh — generate the pad ring with LibreLane (IHP SG13G2)
#
# Runs the LibreLane `Chip` flow up to and including the OpenROAD.PadRing
# step (pad-ring-only mode). Drop the --to flag to run the full chip flow.
#
# PDK location and tool paths come from env.sh (override with PDK_ROOT/PDK).
# Extra arguments are forwarded to librelane.
# ==========================================================================
set -euo pipefail
cd "$(dirname "$0")"

# --- 1. Environment: PDK location, tool paths ------------------------------
. ./env.sh

# --- 2. Run the Chip flow up to (and including) the pad-ring step ----------
librelane config.yaml \
    --pdk "$PDK" --pdk-root "$PDK_ROOT" --manual-pdk \
    --to OpenROAD.PadRing \
    "$@"

# --- 3. Report where the result landed ------------------------------------
RUN=$(ls -dt runs/RUN_* | head -1)
echo "Pad ring written to: $RUN/16-openroad-padring/chip_top.def"
