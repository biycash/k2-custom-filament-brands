#!/usr/bin/env python3
"""K2 Custom Filament Brands - printer-side installer.

Adds your own filament brands to the Creality K2 touchscreen material list.
Runs ON THE PRINTER (python3 is part of the stock firmware). It only writes
new copies of the files into an output folder (default /tmp); it never
changes the live files. The caller swaps them in after checking.

    python3 printer_material_install.py --spec /tmp/custom_spec.json
    python3 printer_material_install.py --remove

How an entry is made: an existing Generic entry on the printer (for example
"Generic ABS") is copied, then its id, brand, name, temperatures, density,
nozzle list and the matching settings are replaced with yours.

Everything this tool adds is recorded in a marker file next to the material
list, so running it again replaces its own entries and --remove takes out
only what it added. Official Creality and Generic entries are never removed.
"""
import argparse
import copy
import json
import os
import sys

BOX = "/mnt/UDISK/creality/userdata/box"
MARKER_NAME = "k2_custom_filament_brands.json"


def load(path, default=None):
    if default is not None and not os.path.exists(path):
        return default
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def split_names(value):
    return [n for n in str(value).split("\n") if n != ""]


def remove_previous(db, opt, marker):
    """Take out entries and option names recorded in the marker."""
    ids = set(marker.get("ids", []))
    lst = db["result"]["list"]
    kept = [x for x in lst if not (x["base"]["id"] in ids and "userMaterial" not in x)]
    removed = len(lst) - len(kept)
    db["result"]["list"] = kept
    for brand, types in marker.get("options", {}).items():
        if brand not in opt:
            continue
        for mtype, names in types.items():
            if mtype not in opt[brand]:
                continue
            left = [n for n in split_names(opt[brand][mtype]) if n not in set(names)]
            if left:
                opt[brand][mtype] = "\n".join(left)
            else:
                del opt[brand][mtype]
        if not opt[brand]:
            del opt[brand]
    return removed


def remove_legacy(db, spec):
    """First run without a marker: take over entries an earlier manual install left
    behind, recognised by the same id AND the same name as an entry in the spec."""
    pairs = {(e["base"]["id"], e["base"]["name"]) for e in spec["entries"]}
    lst = db["result"]["list"]
    kept = [x for x in lst
            if not ((x["base"]["id"], x["base"]["name"]) in pairs and "userMaterial" not in x)]
    db["result"]["list"] = kept
    return len(lst) - len(kept)


def install(db, opt, spec):
    lst = db["result"]["list"]
    official = [x for x in lst if "userMaterial" not in x]
    used_ids = {x["base"]["id"] for x in official}
    used_names = {x["base"]["name"] for x in lst}
    new_entries, added_options, created_brands, skipped = [], {}, [], []

    for e in spec["entries"]:
        b = e["base"]
        if b["id"] in used_ids:
            skipped.append("%s: id %s is already used by another entry" % (b["name"], b["id"]))
            continue
        if b["name"] in used_names:
            skipped.append("%s: this name is already used by another entry" % b["name"])
            continue
        parents = [x for x in official if x["base"]["name"] == e["parent"]]
        if len(parents) != 1:
            skipped.append("%s: printer has no single '%s' entry to copy" % (b["name"], e["parent"]))
            continue
        n = copy.deepcopy(parents[0])
        n["base"].update(b)
        nz = e.get("nozzles") or n.get("nozzleDiameter") or ["0.4"]
        n["nozzleDiameter"] = [nz] if isinstance(nz, str) else list(nz)
        changed = 0
        for k, v in e.get("kv", {}).items():
            if k in n["kvParam"] and n["kvParam"][k] != v:
                n["kvParam"][k] = v
                changed += 1
        new_entries.append(n)
        used_ids.add(b["id"])
        used_names.add(b["name"])

        brand, mtype, name = n["base"]["brand"], n["base"]["meterialType"], n["base"]["name"]
        if brand not in opt:
            opt[brand] = {}
            created_brands.append(brand)
        names = split_names(opt[brand].get(mtype, ""))
        if name not in names:
            names.append(name)
        opt[brand][mtype] = "\n".join(names)
        added_options.setdefault(brand, {}).setdefault(mtype, []).append(name)
        print("ADD  %s | %-32s | %-14s | %-8s | copy of %-15s | nozzles %s | settings changed %d"
              % (b["id"], name, brand, mtype, e["parent"], ",".join(n["nozzleDiameter"]), changed))

    db["result"]["list"] = new_entries + lst
    marker = {
        "tool": "k2-custom-filament-brands",
        "ids": [x["base"]["id"] for x in new_entries],
        "options": added_options,
        "created_brands": created_brands,
    }
    return marker, skipped


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--spec", default="/tmp/custom_spec.json", help="list of entries built on the PC")
    ap.add_argument("--db", default=BOX + "/material_database.json")
    ap.add_argument("--opt", default=BOX + "/material_option.json")
    ap.add_argument("--marker", default=BOX + "/" + MARKER_NAME)
    ap.add_argument("--out-dir", default="/tmp", help="where the new files are written")
    ap.add_argument("--remove", action="store_true", help="only remove what this tool added earlier")
    a = ap.parse_args()

    db = load(a.db)
    opt = load(a.opt)
    old_marker = load(a.marker, default={})
    models = sorted({x.get("printerIntName", "?") for x in db["result"]["list"]})
    print("printer model codes in list: %s" % ",".join(models))

    removed = remove_previous(db, opt, old_marker)
    print("removed entries from an earlier run: %d" % removed)

    if a.remove:
        marker, skipped = {"tool": "k2-custom-filament-brands", "ids": [], "options": {}, "created_brands": []}, []
    else:
        spec = load(a.spec)
        if not old_marker:
            legacy = remove_legacy(db, spec)
            if legacy:
                print("took over entries from an earlier install without marker: %d" % legacy)
        marker, skipped = install(db, opt, spec)

    db["result"]["count"] = len(db["result"]["list"])
    out_db = os.path.join(a.out_dir, "new_material_database.json")
    out_opt = os.path.join(a.out_dir, "new_material_option.json")
    out_marker = os.path.join(a.out_dir, "new_" + MARKER_NAME)
    with open(out_db, "w", encoding="utf-8") as f:
        json.dump(db, f, ensure_ascii=False, separators=(",", ":"))
    with open(out_opt, "w", encoding="utf-8") as f:
        json.dump(opt, f, ensure_ascii=False, indent=2, separators=(",", ":"))
    with open(out_marker, "w", encoding="utf-8") as f:
        json.dump(marker, f, ensure_ascii=False, indent=2)

    db2, opt2 = load(out_db), load(out_opt)
    for s in skipped:
        print("SKIP " + s)
    print("RESULT entries=%d count=%d custom=%d skipped=%d brands=%s" % (
        len(db2["result"]["list"]), db2["result"]["count"], len(marker["ids"]), len(skipped), ",".join(opt2.keys())))


if __name__ == "__main__":
    main()
