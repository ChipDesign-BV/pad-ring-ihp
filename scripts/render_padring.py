#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
# Koen Van Caekenberghe (koen.vancaekenberghe@chipdesign.be), ChipDesign B.V., 07.2026
"""Render the generated pad ring to PNG.

Assembles a GDS from the pad-ring DEF (placements) plus the IHP sg13g2_io
GDS (cell layouts), then rasterises it headlessly with KLayout using the
PDK layer palette.

DEF placement semantics honoured here:
  * ``PLACED ( x y ) ORIENT`` anchors the *lower-left corner of the oriented
    abutment box* (LEF ORIGIN 0 0 + SIZE w BY h) at (x, y) — NOT the cell
    origin. After rotating/mirroring, the box's lower-left moves away from
    the origin, so the instance displacement must compensate.
  * DEF orientations map to KLayout ``Trans(rot, mirrx, ...)`` (mirror at the
    x-axis first, then CCW rotation) as:
      N=R0   W=R90   S=R180  E=R270
      FS=m0  FW=m45  FN=m90  FE=m135  ->  (0,T) (1,T) (2,T) (3,T)

Usage: render_padring.py <padring.def> <out.png> [size_px]
"""
import os
import re
import sys

import klayout.db as db
import klayout.lay as lay

_PDK_DIR = os.path.join(os.environ.get("PDK_ROOT", "/foss/pdks"),
                        os.environ.get("PDK", "ihp-sg13g2"))
IO_GDS = os.path.join(_PDK_DIR, "libs.ref/sg13g2_io/gds/sg13g2_io.gds")
IO_LEF = os.path.join(_PDK_DIR, "libs.ref/sg13g2_io/lef/sg13g2_io.lef")
LYP = os.path.join(_PDK_DIR, "libs.tech/klayout/tech/sg13g2.lyp")

# DEF orientation -> (KLayout rotation count, mirror-at-x-axis-first)
ORIENT = {
    "N": (0, False), "W": (1, False), "S": (2, False), "E": (3, False),
    "FS": (0, True), "FW": (1, True), "FN": (2, True), "FE": (3, True),
}


def lef_sizes(lef_path):
    """Abutment-box size (µm) per MACRO from the LEF."""
    sizes, cur = {}, None
    for line in open(lef_path):
        m = re.match(r"\s*MACRO\s+(\S+)", line)
        if m:
            cur = m.group(1)
        m = re.match(r"\s*SIZE\s+([\d.]+)\s+BY\s+([\d.]+)", line)
        if m and cur:
            sizes[cur] = (float(m.group(1)), float(m.group(2)))
    return sizes


def assemble(def_path):
    ly = db.Layout()
    ly.read(IO_GDS)
    dbu = ly.dbu  # 0.001 um
    sizes = lef_sizes(IO_LEF)
    top = ly.create_cell("padring_top")

    txt = open(def_path).read()
    pat = (r"-\s+(\S+)\s+(\S+)\s+\+\s+(?:FIXED|PLACED)"
           r"\s+\(\s*(-?\d+)\s+(-?\d+)\s*\)\s+(\w+)")
    n = 0
    for inst, master, x, y, orient in re.findall(pat, txt):
        cell = ly.cell(master)
        if cell is None:
            continue
        rot, mirr = ORIENT[orient]
        w, h = sizes[master]
        # abutment box in dbu, oriented; anchor its lower-left at (x, y)
        box = db.Box(0, 0, round(w / dbu), round(h / dbu))
        obox = box.transformed(db.Trans(rot, mirr, 0, 0))
        disp = db.Vector(int(x) - obox.left, int(y) - obox.bottom)
        top.insert(db.CellInstArray(cell.cell_index(), db.Trans(rot, mirr, disp.x, disp.y)))
        n += 1
    bb = top.bbox()
    print(f"placed {n} instances; drawn bbox (um): "
          f"({bb.left*dbu:.2f},{bb.bottom*dbu:.2f})-({bb.right*dbu:.2f},{bb.top*dbu:.2f})")
    return ly


def render(ly, out_png, px):
    import tempfile, os
    tmp = tempfile.NamedTemporaryFile(suffix=".gds", delete=False)
    ly.write(tmp.name)
    lv = lay.LayoutView()
    lv.set_config("background-color", "#000000")
    lv.set_config("text-visible", "false")
    lv.set_config("grid-visible", "false")
    lv.load_layout(tmp.name, 0)
    lv.load_layer_props(LYP)
    lv.max_hier()
    lv.zoom_fit()
    lv.save_image(out_png, px, px)
    os.unlink(tmp.name)
    print("wrote", out_png)


if __name__ == "__main__":
    def_path, out_png = sys.argv[1], sys.argv[2]
    px = int(sys.argv[3]) if len(sys.argv) > 3 else 1700
    render(assemble(def_path), out_png, px)
