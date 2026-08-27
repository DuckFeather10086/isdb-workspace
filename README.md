# isdb-workspace — retired

Development happens in **[ferrite](https://github.com/DuckFeather10086/ferrite)**.
Clone that instead — one recursive clone is the whole ISDB-T stack:

```bash
git clone --recursive https://github.com/DuckFeather10086/ferrite.git
cd ferrite && make deps && make build
```

## Why this repo is gone

It was a wrapper: one submodule, `ferrite`, and a script that checked it out
recursively and handed the build to ferrite's Makefile. It never held code of
its own.

Everything operational was already relative to the ferrite checkout — its
Makefile, the paths in `configs/isdbd.toml`, the systemd unit's
`WorkingDirectory`, the release workflow — so this level added a name and a
second pin to keep current, and nothing else. Earlier it also carried the Rust
engines as submodules of its own, beside ferrite's: two checkouts and two
`target/` directories of the same crates, pinned independently, with only
ferrite's pin ever the one that ran. Those moved into ferrite; this is the rest
of the same cleanup.

`bootstrap.sh` still works if you already have this checkout, but the `ferrite`
pin here is a snapshot from the day the repo was retired, not a release. Move
to a ferrite clone.

## Where the code lives

| Repo | Role | Lang |
|------|------|------|
| [ferrite](https://github.com/DuckFeather10086/ferrite) | orchestrator + web UI, and the four engines below | Go |
| [dvb-rs](https://github.com/DuckFeather10086/dvb-rs) | tuner frontend (tune · scan · EPG) | Rust |
| [libaribb25-rs](https://github.com/DuckFeather10086/libaribb25-rs) | B25 descrambler | Rust |
| [libaribb24-rs](https://github.com/DuckFeather10086/libaribb24-rs) | B24 text decoder | Rust |
| [libaribcaption-rs](https://github.com/DuckFeather10086/libaribcaption-rs) | B24 caption decoder + WebVTT/ASS renderers | Rust |

Each is a standalone repo; the four Rust ones are reached at
`ferrite/<name>/`, which is where to pin a change so that it ships.
