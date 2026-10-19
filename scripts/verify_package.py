"""Consume actual moon package output from an isolated local module."""
from pathlib import Path
import json
import re
import subprocess
import tempfile
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def run(args, cwd):
    p = subprocess.run(args, cwd=cwd, capture_output=True)
    if p.returncode:
        raise RuntimeError((p.stdout + p.stderr).decode("utf-8", "replace"))
    return (p.stdout + p.stderr).decode("utf-8", "replace").strip()


def main():
    version = re.search(r'^version\s*=\s*"([^"]+)"', (ROOT / "moon.mod").read_text(encoding="utf-8"), re.M)[1]
    packaging = run(["moon", "package"], ROOT)
    archive = ROOT / f"_build/publish/local-moonflactag-{version}.zip"
    work = ROOT / "release-local"
    work.mkdir(exist_ok=True)
    with zipfile.ZipFile(archive) as z:
        entries = z.namelist()
        forbidden = {".git", "research", "release-local", "_build", "demo-output", "tmp", "output", "__pycache__"}
        for name in entries:
            parts = Path(name).parts
            assert not (set(parts) & forbidden), name
            assert ".local-ledger.md" not in parts
            assert ".." not in parts and not Path(name).is_absolute()
            assert not Path(name).drive
        assert "moon.mod" in entries and "LICENSE" in entries
        assert "cmd/main/main.mbt" in entries
        assert "fixtures/tone.flac" in entries and "fixtures/cover.png" in entries
        with tempfile.TemporaryDirectory(prefix="consume-", dir=work) as tmp:
            tmp = Path(tmp)
            library = tmp / "library"
            z.extractall(library)
            consumer = tmp / "consumer"
            consumer.mkdir()
            (tmp / "moon.work").write_text('members = ["library", "consumer"]\n', encoding="utf-8")
            (consumer / "moon.mod").write_text(f'name = "local/flactag_consumer"\nversion = "0.0.1"\nimport {{ "local/moonflactag@{version}" }}\n', encoding="utf-8")
            (consumer / "moon.pkg").write_text('import { "local/moonflactag" @flac } for "test"\n', encoding="utf-8")
            fixture = (ROOT / "fixtures/tone.flac").read_bytes()
            literal = 'b"' + ''.join(f'\\x{b:02x}' for b in fixture) + '"'
            source = '''///|
test "independent archive consumer" {
  let doc = @flac.parse(INPUT)
  let changed = doc.rewrite([Set("TITLE", "Archive consumer"), Add("ARTIST", "A"), Add("ARTIST", "B")])
  let parsed = @flac.parse(changed.bytes)
  assert_eq(parsed.comments().values("title"), ["Archive consumer"])
  assert_eq(parsed.comments().values("ARTIST"), ["Synthetic source", "A", "B"])
  assert_eq(parsed.audio_bytes(), doc.audio_bytes())
  assert_eq(changed.audio_offset, doc.audio_offset())
  assert_eq(parsed.stream_info().total_samples, 11025L)
  let prefix = INPUT[:doc.audio_offset()].to_owned()
  let plan = @flac.plan_metadata(prefix, [Set("TITLE", "Archive consumer"), Add("ARTIST", "A"), Add("ARTIST", "B")])
  assert_eq(plan.metadata + doc.audio_bytes(), changed.bytes)
  assert_eq(plan.old_audio_offset, doc.audio_offset())
}
'''.replace("INPUT", literal)
            (consumer / "consumer_test.mbt").write_text(source, encoding="utf-8")
            results = {target: run(["moon", "test", "--package", "local/flactag_consumer", "--target", target, "--deny-warn"], consumer) for target in ["wasm-gc", "js"]}
            # Verify the extracted CLI can also be built and run without the source checkout.
            run(["moon", "build", "--target", "js", "--deny-warn"], library)
            cli_result = subprocess.run(["moon", "run", "cmd/main", "--target", "js", "--", "inspect", str(library / "fixtures/tone.flac")], cwd=library, capture_output=True, check=True)
            output = json.loads(cli_result.stdout)
            assert output["stream"]["total_samples"] == "11025"
            planned = subprocess.run(["moon", "run", "cmd/main", "--target", "js", "--", "plan", str(library / "fixtures/tone.flac"), "--set=TITLE=Packaged preview"], cwd=library, capture_output=True, check=True)
            assert json.loads(planned.stdout)["preview"] is True
    result = {"material_date": "2026-10-19", "version": version, "archive": archive.name, "file_count": len(entries), "archive_bytes": archive.stat().st_size, "consumers": results, "extracted_cli": "inspect and plan passed", "distribution_exclusions": "passed", "packaging_output": packaging.replace(str(ROOT), "<project>")}
    (ROOT / "docs/test-evidence/package-consumption.json").write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
