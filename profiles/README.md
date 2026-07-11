# Git-backed stock profile foundation

These directories contain byte-preserved stock `thermal_info_config*.json` files
from the official Google factory bundles listed in
`profiles/manifests/source-bundles.json`.

Canonical profile path:

`profiles/<device>/17/<channel>/<family>/<build_slug>/base`

Resolver contract:

- exact device match;
- exact Android major match;
- exact build-ID match;
- no silent fallback to another build family;
- `base/system/vendor/etc` is the only patch source;
- `/vendor/etc` is runtime evidence only and must never be used as the
  rematerialization source.

Some official stock files use a trailing comma and therefore fail strict
Python JSON parsing. Those bytes are intentionally preserved. The inventory
records strict and tolerant parser results separately.
