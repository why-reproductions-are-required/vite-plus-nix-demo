# vite-plus-nix-demo

A minimal demo showing how to use [vite-plus](https://github.com/voidzero-dev/vite-plus)
(the `vp` toolchain CLI) from Nix.

`vite-plus` isn't in nixpkgs master yet, so the flake pins the fork branch that
packages it (`github:fengmk2/nixpkgs/vite-plus-init`, vite-plus 0.2.1). Once the
upstream PR lands you can switch the input to plain nixpkgs and nothing else
changes.

## Option A: native Nix (Linux or macOS, needs Nix with flakes)

```sh
# A dev shell with `vp` and Node.js on PATH
nix develop

# then, inside the shell:
vp --version      # -> vp v0.2.1
vp --help
```

Other entry points:

```sh
nix run            # runs `vp` (e.g. nix run . -- --help)
nix build .#vite-plus && ./result/bin/vp --version
```

If your Nix doesn't have flakes enabled, add this once to `~/.config/nix/nix.conf`:

```
experimental-features = nix-command flakes
```

## Option B: Docker (no local Nix needed)

This runs the same flake inside the official Nix image. Good for a quick check
on a machine that only has Docker.

```sh
docker run --rm -it \
  nixos/nix:latest \
  sh -c '
    nix --extra-experimental-features "nix-command flakes" \
      run github:why-reproductions-are-required/vite-plus-nix-demo -- --version
  '
```

Or drop into the dev shell:

```sh
docker run --rm -it nixos/nix:latest \
  nix --extra-experimental-features "nix-command flakes" \
    develop github:why-reproductions-are-required/vite-plus-nix-demo
# then: vp --help
```

> First run downloads nixpkgs and builds `vp`, so it takes a few minutes.
> On Apple Silicon, the `nixos/nix` image runs x86_64 under emulation, which
> only validates the **Linux** build. To validate the macOS build you need Nix
> installed natively on macOS.

## Using `vp` in a real project

The Nix package ships the Rust `vp` CLI. Commands that delegate to JavaScript
(e.g. `vp create`, and the dev/build pipeline) additionally need a project-local
`vite-plus` install:

```sh
nix develop
mkdir my-app && cd my-app
npm install vite-plus     # provides node_modules/vite-plus for vp's JS parts
vp --help
```

What works straight from the Nix package without any install: `vp --version`,
`vp --help`, and the other pure-Rust subcommands. `vp env` (Node version
management) and JS-delegating commands reach the network / a local install at
runtime.

## What's packaged

- vite-plus **0.2.1** (`vp`), built with the workarounds needed for the cargo
  workspace (rolldown is synced externally, `-Z bindeps` artifact deps, and the
  fspy preload cdylib are all handled in the nixpkgs derivation).
- Known limitation: fspy filesystem tracing (LD_PRELOAD) is disabled; all other
  `vp` commands work.
