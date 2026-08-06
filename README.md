# isdb-workspace

Dev workspace for the **[ferrite](https://github.com/DuckFeather10086/ferrite)**
ISDB-T self-hosted TV stack.

**ferrite** is the product and the build root: a Go orchestrator with an
embedded web UI, driving four Rust engines it carries as its own submodules.
Everything operational is relative to that checkout — its Makefile, the paths
in `configs/isdbd.toml`, the systemd unit's `WorkingDirectory`, the release
workflow — so one recursive clone of ferrite is the whole stack:

```bash
git clone --recursive https://github.com/DuckFeather10086/ferrite.git
cd ferrite && make deps && make build
```

This repo is that clone with a name: one submodule, `ferrite`, and a script
that checks it out recursively and hands the build to ferrite's Makefile.

```bash
git clone --recursive https://github.com/DuckFeather10086/isdb-workspace.git
cd isdb-workspace && ./bootstrap.sh          # init + build
./bootstrap.sh status                        # every pin, at both levels
```

It used to carry the Rust engines as submodules of its own, beside ferrite's,
and a cargo workspace to build them in. That was two checkouts and two
`target/` directories of the same three crates, pinned independently — and only
ferrite's pin was ever the one that ran. The engines now live in exactly one
place.

| Repo | Role | Lang |
|------|------|------|
| [ferrite](https://github.com/DuckFeather10086/ferrite) | orchestrator + web UI, and the four engines below | Go |
| [dvb-rs](https://github.com/DuckFeather10086/dvb-rs) | tuner frontend (tune · scan · EPG) | Rust |
| [libaribb25-rs](https://github.com/DuckFeather10086/libaribb25-rs) | B25 descrambler | Rust |
| [libaribb24-rs](https://github.com/DuckFeather10086/libaribb24-rs) | B24 text decoder | Rust |
| [libaribcaption-rs](https://github.com/DuckFeather10086/libaribcaption-rs) | B24 caption decoder + WebVTT/ASS renderers | Rust |

Each is a standalone repo; the four Rust ones are reached at
`ferrite/<name>/`, which is where to pin a change so that it ships.
