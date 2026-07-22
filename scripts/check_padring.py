#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
# Koen Van Caekenberghe (koen.vancaekenberghe@chipdesign.be), ChipDesign B.V., 07.2026
"""Verify the generated pad ring: uniform pad pitch and ring closure.

Reads the pad-ring DEF (placements) and the sg13g2_io LEF (abutment-box
sizes) and checks, per die side:
  1. every adjacent pad pair sits at exactly the target centre-to-centre
     pitch, and
  2. the ring band is tiled gap-free from corner to corner (pads + corner
     cells + fillers), i.e. the ring is closed.

Exit code 0 on PASS, 1 on FAIL.

Usage: check_padring.py <padring.def> [--pitch 150] [--edge 140]
"""
import argparse
import os
import re
import sys

IO_LEF = os.path.join(os.environ.get("PDK_ROOT", "/foss/pdks"),
                      os.environ.get("PDK", "ihp-sg13g2"),
                      "libs.ref/sg13g2_io/lef/sg13g2_io.lef")
EPS = 1e-6


def lef_sizes(lef_path):
    sizes, cur = {}, None
    for line in open(lef_path):
        m = re.match(r"\s*MACRO\s+(\S+)", line)
        if m:
            cur = m.group(1)
        m = re.match(r"\s*SIZE\s+([\d.]+)\s+BY\s+([\d.]+)", line)
        if m and cur:
            sizes[cur] = (float(m.group(1)), float(m.group(2)))
    return sizes


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("def_file")
    ap.add_argument("--pitch", type=float, default=150.0, help="target pad pitch (µm)")
    ap.add_argument("--edge", type=float, default=140.0, help="PAD_EDGE_SPACING (µm)")
    args = ap.parse_args()

    sizes = lef_sizes(IO_LEF)
    txt = open(args.def_file).read()
    dbu = 1000.0

    m = re.search(r"DIEAREA\s+\(\s*(\d+)\s+(\d+)\s*\)\s+\(\s*(\d+)\s+(\d+)\s*\)", txt)
    die = int(m.group(3)) / dbu  # assume square die at origin
    lo, hi = args.edge, die - args.edge

    pat = (r"-\s+(\S+)\s+(\S+)\s+\+\s+(?:FIXED|PLACED)"
           r"\s+\(\s*(-?\d+)\s+(-?\d+)\s*\)\s+(\w+)")
    comps = [(i, mstr, int(x) / dbu, int(y) / dbu, o)
             for i, mstr, x, y, o in re.findall(pat, txt)]

    def wh(mstr, o):
        w, h = sizes.get(mstr, (80.0, 180.0))
        return (h, w) if o in ("E", "W", "FE", "FW") else (w, h)

    # collect, per side, the pad centres and the full band intervals
    centres = {s: [] for s in ("south", "north", "west", "east")}
    bands = {s: [] for s in ("south", "north", "west", "east")}
    for _, mstr, x, y, o in comps:
        w, h = wh(mstr, o)
        is_pad = "IOPad" in mstr and "Filler" not in mstr
        if abs(y - lo) < 0.01:
            bands["south"].append((x, x + w))
            if is_pad:
                centres["south"].append(x + w / 2)
        if abs(y + h - hi) < 0.01:
            bands["north"].append((x, x + w))
            if is_pad:
                centres["north"].append(x + w / 2)
        if abs(x - lo) < 0.01:
            bands["west"].append((y, y + h))
            if is_pad:
                centres["west"].append(y + h / 2)
        if abs(x + w - hi) < 0.01:
            bands["east"].append((y, y + h))
            if is_pad:
                centres["east"].append(y + h / 2)

    ok = True
    for side in ("south", "north", "west", "east"):
        cs = sorted(centres[side])
        pitches = sorted({round(b - a, 3) for a, b in zip(cs, cs[1:])})
        pitch_ok = pitches == [round(args.pitch, 3)]
        # closure: union of intervals must cover [lo, hi] without gaps
        gaps, pos = [], lo
        for a, b in sorted(bands[side]):
            if a > pos + EPS:
                gaps.append((round(pos, 3), round(a, 3)))
            pos = max(pos, b)
        if pos < hi - EPS:
            gaps.append((round(pos, 3), round(hi, 3)))
        print(f"{side}: {len(cs)} pads, pitch(es) {pitches} "
              f"[{'ok' if pitch_ok else 'FAIL'}], "
              f"closure gaps: {gaps if gaps else 'none'} "
              f"[{'ok' if not gaps else 'FAIL'}]")
        ok &= pitch_ok and not gaps

    print("RESULT:", "PASS" if ok else "FAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
