"""Install the exact public release without a local workspace override and exercise it."""
import argparse
import json
from pathlib import Path
import re
import subprocess
import tempfile
from verify import ROOT, EVIDENCE, material_date


def run(args, cwd):
    p = subprocess.run([str(a) for a in args], cwd=cwd, capture_output=True)
    if p.returncode:
        raise RuntimeError((p.stdout + p.stderr).decode("utf-8", "replace"))
    return (p.stdout + p.stderr).decode("utf-8", "replace").strip()


def literal(data):
    return 'b"' + ''.join(f'\\x{b:02x}' for b in data) + '"'


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--no-update", action="store_true", help="Use the already refreshed official registry index")
    args = parser.parse_args()
    manifest = (ROOT / "moon.mod").read_text(encoding="utf-8")
    module = re.search(r'^name\s*=\s*"([^"]+)"', manifest, re.M)[1]
    version = re.search(r'^version\s*=\s*"([^"]+)"', manifest, re.M)[1]
    work = ROOT / "release-local"
    work.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="registry-", dir=work) as tmp:
        consumer = Path(tmp)
        (consumer / "moon.mod").write_text('name = "local/flactag_registry_consumer"\nversion = "0.0.1"\n', encoding="utf-8")
        (consumer / "moon.pkg").write_text(f'import {{ "{module}" @flac }} for "test"\n', encoding="utf-8")
        install = run(["moon", "add", *(["--no-update"] if args.no_update else []), f"{module}@{version}"], consumer)
        downloaded = consumer / ".mooncakes" / module
        fetched = (downloaded / "moon.mod").read_text(encoding="utf-8")
        assert re.search(r'^name\s*=\s*"([^"]+)"', fetched, re.M)[1] == module
        assert re.search(r'^version\s*=\s*"([^"]+)"', fetched, re.M)[1] == version
        for parent in [consumer, *consumer.parents]:
            assert not (parent / "moon.work").exists(), "registry check must not inherit a local workspace"
        source = '''///|
test "registry lossless rewrite and plan" {
  let doc = @flac.parse(INPUT)
  let edited = doc.rewrite([Set("TITLE", "Registry consumer"), Add("ARTIST", "Guest")])
  let parsed = @flac.parse(edited.bytes)
  assert_eq(parsed.comments().values("title"), ["Registry consumer"])
  assert_eq(parsed.comments().values("artist"), ["Synthetic source", "Guest"])
  assert_eq(parsed.audio_bytes(), doc.audio_bytes())
  let prefix = INPUT[:doc.audio_offset()].to_owned()
  let plan = @flac.plan_metadata(prefix, [Set("TITLE", "Registry consumer"), Add("ARTIST", "Guest")])
  assert_eq(plan.metadata + doc.audio_bytes(), edited.bytes)
}

///|
test "registry selective artwork and exact framing" {
  let image = @flac.picture_from_image(PNG)
  let back = {..image,kind:4}
  assert_eq(@flac.edit_pictures([back],[SetPicture(image)]),[back,image])
  match @flac.metadata_prefix_length(INPUT) {
    Complete(n) => assert_eq(n,@flac.parse(INPUT).audio_offset())
    NeedMore(_) => fail("complete fixture did not frame")
  }
}
'''.replace("INPUT", literal((ROOT / "fixtures/tone.flac").read_bytes())).replace("PNG", literal((ROOT / "fixtures/cover.png").read_bytes()))
        (consumer / "consumer_test.mbt").write_text(source, encoding="utf-8")
        results = {target: run(["moon", "test", "--package", "local/flactag_registry_consumer", "--target", target, "--deny-warn"], consumer) for target in ["wasm-gc", "js"]}
        inspected = run(["moon", "run", "cmd/main", "--target", "js", "--", "inspect", downloaded / "fixtures/tone.flac"], downloaded)
        assert json.loads(inspected)["stream"]["total_samples"] == "11025"
    result = {"material_date": material_date(), "module": module, "version": version, "source": "public registry via moon add exact version; no moon.work or local module substitution", "registry_index_refresh_skipped": args.no_update, "downloaded_manifest": "exact name and version verified", "consumers": results, "downloaded_cli": "inspect passed", "install_output": install.replace(str(ROOT), "<project>")}
    (EVIDENCE / "registry-consumption.json").write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
