"""Build a local, dependency-free Node CLI distribution; never publishes."""
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tarfile
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def main():
    version = re.search(r'^version\s*=\s*"([^"]+)"', (ROOT / "moon.mod").read_text(encoding="utf-8"), re.M)[1]
    subprocess.run(["moon", "build", "--target", "js", "--release", "--deny-warn"], cwd=ROOT, check=True)
    dest = ROOT / "release-local" / f"moonflactag-cli-{version}"
    (dest / "bin").mkdir(parents=True, exist_ok=True)
    (dest / "lib").mkdir(exist_ok=True)
    (dest / "examples").mkdir(exist_ok=True)
    shutil.copyfile(ROOT / "_build/js/release/build/cmd/main/main.js", dest / "lib/moonflactag.cjs")
    package = {"name": "moonflactag-local-cli", "version": version, "private": True,
               "description": "Local MoonFlacTag command-line distribution", "license": "MIT",
               "engines": {"node": ">=24"}, "bin": {"moonflactag": "bin/moonflactag.cjs"}}
    (dest / "package.json").write_text(json.dumps(package, indent=2) + "\n", encoding="utf-8")
    launcher = '''#!/usr/bin/env node
'use strict';
if (Number(process.versions.node.split('.')[0]) < 24) {
  console.error(JSON.stringify({code:'NODE_VERSION',error:'Node.js 24 or newer is required',message:'Node.js 24 or newer is required',operation:'startup',path:'',offset:null}));
  process.exitCode=1;
} else {
  require('../lib/moonflactag.cjs');
}
'''
    (dest / "bin/moonflactag.cjs").write_bytes(launcher.encode("utf-8"))
    (dest / "moonflactag.cmd").write_bytes(b'@echo off\r\nnode "%~dp0bin\\moonflactag.cjs" %*\r\nexit /b %errorlevel%\r\n')
    (dest / "moonflactag").write_bytes(b'#!/bin/sh\nbasedir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)\nexec node "$basedir/bin/moonflactag.cjs" "$@"\n')
    for name in ["LICENSE", "THIRD_PARTY.md"]:
        shutil.copyfile(ROOT / name, dest / name)
    core_license = Path(os.environ.get("MOON_HOME", str(Path.home() / ".moon"))) / "lib/core/LICENSE"
    if not core_license.is_file():
        raise FileNotFoundError("MoonBit core LICENSE is required in the standalone distribution")
    shutil.copyfile(core_license, dest / "MOONBIT-CORE-LICENSE")
    shutil.copyfile(ROOT / "docs/cli-guide.md", dest / "README.md")
    for name in ["tone.flac", "cover.png"]:
        shutil.copyfile(ROOT / "fixtures" / name, dest / "examples" / name)
    # Explicit allowlist keeps old or user-added files out of refreshed distributions.
    names = ["package.json", "bin/moonflactag.cjs", "lib/moonflactag.cjs", "moonflactag.cmd", "moonflactag", "LICENSE", "MOONBIT-CORE-LICENSE", "THIRD_PARTY.md", "README.md", "examples/tone.flac", "examples/cover.png"]
    archive = dest.parent / (dest.name + ".zip")
    with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED) as z:
        for name in names:
            info = zipfile.ZipInfo(dest.name + "/" + name)
            executable = name in ["moonflactag", "bin/moonflactag.cjs"]
            info.create_system = 3
            info.external_attr = (0o100755 if executable else 0o100644) << 16
            info.compress_type = zipfile.ZIP_DEFLATED
            z.writestr(info, (dest / name).read_bytes())
    npm_archive = dest.parent / f"moonflactag-local-cli-{version}.tgz"
    with tarfile.open(npm_archive, "w:gz") as tar:
        for name in names:
            info = tar.gettarinfo(str(dest / name), arcname="package/" + name)
            info.uid = info.gid = 0
            info.uname = info.gname = ""
            info.mode = 0o755 if name in ["moonflactag", "bin/moonflactag.cjs"] else 0o644
            with (dest / name).open("rb") as source:
                tar.addfile(info, source)
    print(json.dumps({"version": version, "directory": str(dest), "zip": str(archive), "npm_archive": str(npm_archive)}, indent=2))


if __name__ == "__main__":
    main()
