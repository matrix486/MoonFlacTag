"""Use the real standalone archive and install its local tgz with npm offline."""
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import zipfile
from verify import ROOT, EVIDENCE, metadata


def call(args, cwd, env):
    p = subprocess.run([str(a) for a in args], cwd=cwd, env=env, capture_output=True)
    if p.returncode:
        raise RuntimeError((p.stdout + p.stderr).decode("utf-8", "replace"))
    return p


def main():
    subprocess.run([sys.executable, str(ROOT / "scripts/build_cli.py")], cwd=ROOT, check=True)
    version = re.search(r'^version\s*=\s*"([^"]+)"', (ROOT / "moon.mod").read_text(encoding="utf-8"), re.M)[1]
    release = ROOT / "release-local"
    node = Path(shutil.which("node"))
    npm = Path(shutil.which("npm.cmd" if os.name == "nt" else "npm"))
    with tempfile.TemporaryDirectory(prefix="standalone-", dir=release) as tmp:
        work = Path(tmp) / "独立 目录 & album"
        work.mkdir()
        with zipfile.ZipFile(release / f"moonflactag-cli-{version}.zip") as z:
            z.extractall(work)
        package = work / f"moonflactag-cli-{version}"
        env = os.environ.copy()
        # Exclude MoonBit, Python and media tooling from runtime command lookup.
        env["PATH"] = str(node.parent) + os.pathsep + str(Path(env.get("SystemRoot", "/")) / "System32") if os.name == "nt" else str(node.parent) + ":/usr/bin:/bin"
        env["npm_config_cache"] = str(work / "npm-cache")
        env["npm_config_update_notifier"] = "false"
        launcher = package / "bin/moonflactag.cjs"
        assert call([node, launcher, "--version"], work, env).stdout.decode().strip() == f"MoonFlacTag {version}"
        source = package / "examples/tone.flac"
        output = work / "整理结果/disc 1/01.flac"
        report = work / "报告/完成.json"
        data = json.loads(call([node, launcher, "edit", source, output, "--set=TITLE=中文 & spaces", "--cover=" + str(package / "examples/cover.png"), "--report=" + str(report)], work, env).stdout)
        assert data == json.loads(report.read_text(encoding="utf-8"))
        assert metadata(source.read_bytes())[2] == metadata(output.read_bytes())[2]
        assert any(e["value"] == "中文 & spaces" for e in data["comments"]["entries"])
        extracted = work / "导出/front.png"
        call([node, launcher, "extract-cover", output, extracted], work, env)
        assert extracted.read_bytes() == (package / "examples/cover.png").read_bytes()
        # Install actual tgz; private local package, no dependencies or lifecycle scripts.
        # npm's generated Windows cmd shim uses unquoted SET dp0 and cannot handle &.
        # Keep npm's prefix free of shell metacharacters; our portable launcher is
        # still exercised inside the directory containing & below.
        prefix = Path(tmp) / "安装 tools"
        call([npm, "install", "--prefix", prefix, "--offline", "--ignore-scripts", "--no-audit", "--no-fund", release / f"moonflactag-local-cli-{version}.tgz"], work, env)
        shim = prefix / "node_modules/.bin" / ("moonflactag.cmd" if os.name == "nt" else "moonflactag")
        assert version in call([shim, "--version"], work, env).stdout.decode()
        installed_report = json.loads(call([shim, "inspect", source], work, env).stdout)
        assert installed_report["stream"]["total_samples"] == "11025"
        portable = package / ("moonflactag.cmd" if os.name == "nt" else "moonflactag")
        command = [portable] if os.name == "nt" else ["sh", portable]
        assert version in call([*command, "--version"], work, env).stdout.decode()
        call([npm, "uninstall", "--prefix", prefix, "moonflactag-local-cli", "--offline", "--ignore-scripts", "--no-audit", "--no-fund"], work, env)
        assert not shim.exists()
    result = {"material_date": "2026-10-22", "version": version, "runtime": "Node.js only; MoonBit excluded from PATH", "portable_zip": "passed", "independent_unicode_space_directory": "passed", "tag_cover_export_report": "passed", "npm_offline_tgz_install_command_and_uninstall": "passed", "platform": sys.platform}
    (EVIDENCE / "cli-distribution.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
