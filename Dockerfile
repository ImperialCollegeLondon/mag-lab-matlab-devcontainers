
# This was based off the default devcontainer for python and customised to support multiple python versions
# see https://github.com/devcontainers/images/blob/main/src/python/.devcontainer/Dockerfile

## we start with the version we want as the system version
FROM mcr.microsoft.com/devcontainers/python:3.14-trixie

# install uv from the UV image
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

ARG PYTHON_VERSIONS="3.11 3.12 3.13 3.14"
USER vscode

# Install multiple Python versions using `uv` as the non-root user
RUN uv python install $PYTHON_VERSIONS --install-dir /home/vscode/.local/bin

RUN sudo apt-get update && sudo apt-get install --no-install-recommends --no-install-suggests -y \
    postgresql-client wget ca-certificates
RUN python3 -m pip install --user pipx && \
    python3 -m pipx ensurepath
RUN pipx ensurepath && \
    pipx install poetry pre-commit

ENV PATH="/home/vscode/.local/bin:${PATH}"

# NASA NAIF MICE toolkit for MATLAB (precompiled glnxa64, no compiler needed).
# See https://naif.jpl.nasa.gov/pub/naif/toolkit_docs/MATLAB/req/mice.html
RUN sudo mkdir -p /opt/naif && sudo chown vscode:vscode /opt/naif && \
    cd /opt/naif && \
    wget -q https://naif.jpl.nasa.gov/pub/naif/toolkit//MATLAB/PC_Linux_GCC_MATLAB9.x_64bit/packages/mice.tar.Z && \
    zcat mice.tar.Z | tar xf - && \
    rm mice.tar.Z

# NASA CDF (Common Data Format) MATLAB patch (precompiled glnxa64, no compiler needed).
# See https://cdf.gsfc.nasa.gov/quickstartguides/MATLAB/
# "latest_matlab" tracks the current CDF release; the extracted dir is renamed to a
# stable path so MATLABPATH below doesn't need to track the embedded version number.
RUN sudo mkdir -p /opt/cdf && sudo chown vscode:vscode /opt/cdf && \
    cd /opt/cdf && \
    wget -q https://spdf.gsfc.nasa.gov/pub/software/cdf/dist/latest_matlab/matlab_cdf_lin64.tar.gz && \
    tar xzf matlab_cdf_lin64.tar.gz && \
    rm matlab_cdf_lin64.tar.gz && \
    mv matlab_cdf*_patch-64 matlab_cdf_patch

# MATLAB adds every entry on MATLABPATH to its search path at startup, regardless of
# where MATLAB itself ends up installed (the devcontainer feature installs it after
# this Dockerfile builds, so we can't addpath() against a known matlabroot here).
ENV MATLABPATH="/opt/naif/mice/lib:/opt/naif/mice/src/mice:/opt/cdf/matlab_cdf_patch"

