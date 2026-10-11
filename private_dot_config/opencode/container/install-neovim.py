#!/usr/bin/env python3
"""Install the checksum-verified Neovim 0.11.5 distribution into /opt/neovim."""

import hashlib
from pathlib import Path
import platform
import tarfile
import urllib.request


RELEASE = "v0.11.5"
ARCHIVES = {
    "x86_64": ("nvim-linux-x86_64", "b2f91117be5b5ea39edd7297156dc2a4a8df4add6c95a90809a8df19e7ab6f52"),
    "aarch64": ("nvim-linux-arm64", "ea4f9a31b11cc1477ff014aebb7b207684e7280f94ffa97abdab6cacd9b98519"),
}


def main():
    name, expected = ARCHIVES[platform.machine()]
    archive = Path("/tmp/neovim-release.tar.gz")
    url = f"https://github.com/neovim/neovim/releases/download/{RELEASE}/{name}.tar.gz"
    urllib.request.urlretrieve(url, archive)
    if hashlib.sha256(archive.read_bytes()).hexdigest() != expected:
        raise RuntimeError("Neovim archive checksum mismatch")
    target = Path("/opt/neovim")
    if target.exists():
        raise RuntimeError("Refusing to overwrite an existing Neovim distribution")
    with tarfile.open(archive) as distribution:
        distribution.extractall("/opt", filter="data")
    Path("/opt", name).rename(target)
    archive.unlink()


if __name__ == "__main__":
    main()
