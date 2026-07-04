# mag-lab-matlab-devcontainers

Builds a devcontainer image with MATLAB, Python, and science-data-processing toolkits
(NASA NAIF SPICE/MICE, NASA CDF), prebuilt in CI and published to GitHub Container
Registry so other projects don't have to pay the MATLAB install time themselves.

## What's included

- MATLAB (release configurable, see below) with Statistics & Machine Learning,
  Signal Processing, Curve Fitting, Optimization, Control System, Mapping and
  Communications toolboxes
- [matlab-proxy](https://github.com/mathworks/matlab-proxy) — browser-based MATLAB desktop
- [NASA NAIF MICE](https://naif.jpl.nasa.gov/pub/naif/toolkit_docs/MATLAB/req/mice.html) toolkit
- [NASA CDF](https://cdf.gsfc.nasa.gov/quickstartguides/MATLAB/) MATLAB patch
- Python 3.14, [uv](https://github.com/astral-sh/uv), and `pipx`-installed `poetry`/`pre-commit`
- Node.js, GitHub CLI, Claude Code CLI

## Using the prebuilt image (recommended)

A GitHub Actions workflow rebuilds this devcontainer for the last 4 MATLAB releases
every ~2 weeks and publishes it to GHCR, tagged by release:

```
ghcr.io/imperialcollegelondon/mag-lab-matlab-devcontainers:r2026a
ghcr.io/imperialcollegelondon/mag-lab-matlab-devcontainers:r2025b
ghcr.io/imperialcollegelondon/mag-lab-matlab-devcontainers:r2025a
ghcr.io/imperialcollegelondon/mag-lab-matlab-devcontainers:r2024b
```

In another project, point your `.devcontainer/devcontainer.json` at the image
directly instead of building it, e.g.:

```jsonc
{
    "image": "ghcr.io/imperialcollegelondon/mag-lab-matlab-devcontainers:r2025b",
    "remoteUser": "vscode",
    "containerEnv": {
        "MWI_APP_PORT": "8888"
    },
    "portsAttributes": {
        "8888": { "label": "MATLAB (matlab-proxy)", "onAutoForward": "openPreview" }
    }
}
```

This skips the MATLAB install entirely (10-20+ minutes) — see [available tags](
https://github.com/orgs/ImperialCollegeLondon/packages/container/package/mag-lab-matlab-devcontainers).

## Developing this repo / building locally

The devcontainer is defined in [`mag-lab-matlab-devontainer.json`](./mag-lab-matlab-devontainer.json)
(build from [`Dockerfile`](./Dockerfile) + devcontainer features), not the conventional
`.devcontainer/devcontainer.json` path, so VS Code's Dev Containers extension won't
auto-detect it. Either:

- **Symlink it in** so "Reopen in Container" works as normal:
  ```sh
  mkdir -p .devcontainer && ln -s ../mag-lab-matlab-devontainer.json .devcontainer/devcontainer.json
  ```
- **Use the [devcontainer CLI](https://github.com/devcontainers/cli)** directly:
  ```sh
  npm install -g @devcontainers/cli

  # build the image
  devcontainer build --workspace-folder . --config ./mag-lab-matlab-devontainer.json \
      --image-name mag-lab-matlab-devcontainer:local

  # or build + start a container and shell into it
  devcontainer up --workspace-folder . --config ./mag-lab-matlab-devontainer.json
  devcontainer exec --workspace-folder . --config ./mag-lab-matlab-devontainer.json bash
  ```

### MATLAB licensing

Building the image needs no license — MathWorks' `mpm` only installs product files.
*Running* MATLAB inside the container does. Set `MLM_LICENSE_FILE` in your shell
before opening/building the devcontainer and it's passed through automatically
(`remoteEnv.MLM_LICENSE_FILE` in `mag-lab-matlab-devontainer.json`):

```sh
export MLM_LICENSE_FILE=27004@matlab.cc.ic.ac.uk   # Imperial's network license server
```

### matlab-proxy (browser-based MATLAB)

Starts automatically in the container and is forwarded on port 8888 — VS Code should
auto-open it in Simple Browser, or open `http://localhost:8888` manually.

### Changing the MATLAB release or installed products

Edit the `release` and `products` fields under
`features["ghcr.io/mathworks/devcontainer-features/matlab:0"]` in
`mag-lab-matlab-devontainer.json`. Product names come from MathWorks' [feature
README](https://github.com/mathworks/devcontainer-features/tree/main/src/matlab).
Note that CI overwrites `release` per matrix entry when building the prebuilt
images (see below) — the value in the file is just the local-dev default.

## Toolkits

- **NAIF MICE** is unpacked to `/opt/naif/mice`; its `lib`/`src/mice` folders are on
  `MATLABPATH` automatically. SPICE kernels aren't bundled — download the ones you
  need per mission from NAIF separately.
- **NASA CDF** is unpacked to `/opt/cdf/matlab_cdf_patch`, also on `MATLABPATH`.

## Prebuild CI

[`.github/workflows/prebuild-devcontainers.yml`](.github/workflows/prebuild-devcontainers.yml):

1. Discovers the last 4 MATLAB releases supported by the `mathworks/devcontainer-features`
   matlab feature (scraped from the feature's own source, so it stays current
   without manual edits).
2. Builds one image per release and pushes it to GHCR, tagged by release.

Triggers: push to `main` touching the Dockerfile/devcontainer.json/workflow, a
schedule (1st and 15th of each month, ~every 2 weeks), or manual dispatch:

```sh
gh workflow run prebuild-devcontainers.yml
# or override the auto-discovered releases:
gh workflow run prebuild-devcontainers.yml -f releases=r2025b,r2025a
```
