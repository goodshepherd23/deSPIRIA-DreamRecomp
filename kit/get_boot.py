"""Reads the boot program out of a deSPIRIA disc image without extracting the whole disc.

Usage: python get_boot.py DCDISC_DIR IMAGE OUT
  DCDISC_DIR  dream-recomp's tools/dcdisc (the disc reader this uses)
  IMAGE       your .gdi or .chd
  OUT         where to write 1ST_READ.BIN

Prints one line, `product=<id> boot=<name> size=<bytes> sha256=<hex>`, and exits 0; or prints the
reason and exits 1.
"""
import hashlib
import sys

sys.path.insert(0, sys.argv[1])
from dcdisc.image import open_image  # noqa: E402
from dcdisc.ipbin import parse_ipbin, read_ipbin  # noqa: E402
from dcdisc.iso9660 import Iso9660  # noqa: E402
from dcdisc.scramble import ensure_plain  # noqa: E402

image, out = sys.argv[2], sys.argv[3]
try:
    with open_image(image) as img:
        ip = parse_ipbin(read_ipbin(img))
        boot = None
        fs = Iso9660(img)
        for e in fs.walk():
            if not e.is_dir and e.name.upper() == ip.boot_filename.upper():
                boot = fs.read(e)
                break
except Exception as exc:  # a missing track file, an unreadable CHD, not a Dreamcast disc
    print(f"could not read the disc: {exc}")
    sys.exit(1)
if boot is None:
    print(f"the disc has no {ip.boot_filename}")
    sys.exit(1)
plain, _ = ensure_plain(boot)
with open(out, "wb") as f:
    f.write(plain)
print(f"product={ip.product_number} boot={ip.boot_filename} size={len(plain)} "
      f"sha256={hashlib.sha256(plain).hexdigest()}")
