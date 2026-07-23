# SPDX-License-Identifier: Apache-2.0
# Koen Van Caekenberghe (koen.vancaekenberghe@chipdesign.be), ChipDesign B.V., 07.2026
# source this file to set up the environment for this project:
#   . ./env.sh
#
# Adjust PDK_ROOT / PDK (or export them beforehand) to match your
# installation; the defaults below match a standard /foss/pdks setup.
export PDK_ROOT="${PDK_ROOT:-/foss/pdks}"
export PDK="${PDK:-ihp-sg13g2}"
export PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE:-$0}")" && pwd)"

# EDA tools (librelane, yosys, openroad, klayout) are often not on PATH in
# non-interactive shells; prepend common install locations when they exist.
# This is a no-op on systems where the tools are already on PATH.
for _d in /headless/.local/bin /foss/tools/bin /foss/tools/sak; do
    if [ -d "$_d" ]; then
        case ":$PATH:" in *":$_d:"*) ;; *) PATH="$_d:$PATH" ;; esac
    fi
done
unset _d
export PATH
