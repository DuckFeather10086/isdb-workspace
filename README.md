# isdb-workspace

Dev workspace for the **[ferrite](https://github.com/DuckFeather10086/ferrite)**
ISDB-T self-hosted TV stack.

**ferrite** is the product — a Go orchestrator with an embedded web UI,
driving three Rust engines (dvb-rs, libaribb25-rs, libaribb24-rs) as
git submodules. Clone ferrite recursively to get the full stack:

```bash
git clone --recursive https://github.com/DuckFeather10086/ferrite.git
```

This umbrella repo exists as a convenience view over the individual
component repositories. Each subdirectory is a standalone repo:

| Repo | Role | Lang |
|------|------|------|
| [ferrite](https://github.com/DuckFeather10086/ferrite) | orchestrator + web UI | Go |
| [dvb-rs](https://github.com/DuckFeather10086/dvb-rs) | tuner frontend | Rust |
| [libaribb25-rs](https://github.com/DuckFeather10086/libaribb25-rs) | B25 descrambler | Rust |
| [libaribb24-rs](https://github.com/DuckFeather10086/libaribb24-rs) | B24 text decoder | Rust |
