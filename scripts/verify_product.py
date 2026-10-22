"""Batch, selective artwork, extraction and atomic destination publication."""
from pathlib import Path
import json
import subprocess
import tempfile
from verify import ROOT, OUT, EVIDENCE, cli, inspect, metadata, run

MAIN = ROOT / "_build/js/debug/build/cmd/main/main.js"


def decoded_json(p):
    return json.loads(p.stdout)


def error_code(p):
    assert p.returncode != 0 and p.stdout == b""
    error = json.loads(p.stderr)
    assert error["code"] and error["message"] == error["error"]
    assert {"operation", "path", "offset"} <= error.keys()
    return error["code"]


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="product-", dir=OUT) as tmp:
        work = Path(tmp)
        original = ROOT / "fixtures/tone.flac"
        source = original.read_bytes()
        audio = metadata(source)[2]
        jpeg = work / "back.jpg"
        run("ffmpeg", "-v", "error", "-f", "lavfi", "-i", "color=c=blue:s=16x16:d=0.04", "-frames:v", "1", "-c:v", "mjpeg", "-threads", "1", "-update", "1", jpeg)
        png = ROOT / "fixtures/cover.png"
        back, pair, front_jpeg, removed, legacy = [work / f"{name}.flac" for name in ["back", "pair", "front", "removed", "legacy"]]
        cli("edit", original, back, "--picture-kind=4", f"--cover={jpeg}", "--compact")
        cli("edit", back, pair, f"--cover={png}", "--compact")
        pics = inspect(pair)["pictures"]
        assert [p["kind"] for p in pics] == [4, 3]
        assert pics[0]["media_type"] == "image/jpeg" and pics[0]["width"] == pics[0]["height"] == 16
        assert pics[1]["media_type"] == "image/png" and pics[1]["width"] == pics[1]["height"] == 1
        exported = work / "exported.jpg"
        cli("extract-cover", pair, exported, "--index=0")
        assert exported.read_bytes() == jpeg.read_bytes()
        cli("edit", pair, front_jpeg, f"--cover={jpeg}", "--compact")
        assert [p["kind"] for p in inspect(front_jpeg)["pictures"]] == [4, 3]
        assert all(p["media_type"] == "image/jpeg" for p in inspect(front_jpeg)["pictures"])
        append = work / "append.flac"
        cli("edit", pair, append, f"--append-cover={png}", "--compact")
        assert [p["kind"] for p in inspect(append)["pictures"]] == [4, 3, 3]
        cli("edit", append, removed, "--remove-picture-kind=3", "--compact")
        assert [p["kind"] for p in inspect(removed)["pictures"]] == [4]
        cli("edit", pair, legacy, f"--cover-png={png}", "--compact")
        assert [p["kind"] for p in inspect(legacy)["pictures"]] == [3]
        for path in [back, pair, front_jpeg, append, removed, legacy]:
            assert metadata(path.read_bytes())[2] == audio
        assert error_code(cli("extract-cover", pair, work / "missing.jpg", "--index=9", ok=False)) == "PICTURE_NOT_FOUND"
        assert error_code(cli("extract-cover", pair, exported, ok=False)) == "EEXIST"
        assert exported.read_bytes() == jpeg.read_bytes()
        # Batch preserves relative paths, continues after invalid files and never overwrites.
        inputs, outputs = work / "inputs", work / "outputs"
        (inputs / "nested").mkdir(parents=True)
        (inputs / "01.flac").write_bytes(source)
        (inputs / "nested/02.FLAC").write_bytes(source)
        (inputs / "bad.flac").write_bytes(b"not a flac")
        (inputs / "ignore.txt").write_text("ignored", encoding="utf-8")
        before = {p: p.read_bytes() for p in inputs.rglob("*") if p.is_file()}
        preview_result = cli("batch", "plan", inputs, "--recursive", "--set=ALBUM=Batch album", ok=False)
        preview = decoded_json(preview_result)
        assert preview_result.returncode != 0
        assert (preview["total"], preview["succeeded"], preview["failed"]) == (3, 2, 1)
        assert [r["relative"] for r in preview["results"]] == ["01.flac", "bad.flac", "nested/02.FLAC"]
        assert not outputs.exists()
        outputs.mkdir()
        (outputs / "01.flac").write_bytes(b"existing output")
        partial = decoded_json(cli("batch", "edit", inputs, outputs, "--recursive", "--set=ALBUM=Batch album", ok=False))
        assert (partial["succeeded"], partial["failed"]) == (1, 2)
        assert (outputs / "01.flac").read_bytes() == b"existing output"
        assert not (outputs / "bad.flac").exists()
        nested = outputs / "nested/02.FLAC"
        assert metadata(nested.read_bytes())[2] == audio
        assert any(e == {"key":"ALBUM","value":"Batch album"} for e in inspect(nested)["comments"]["entries"])
        for p, contents in before.items():
            assert p.read_bytes() == contents
        assert error_code(cli("batch", "edit", inputs, inputs / "generated", "--recursive", ok=False)) == "PATH_OVERLAP"
        assert error_code(cli("batch", "edit", inputs, work, ok=False)) == "PATH_OVERLAP"
        shallow = decoded_json(cli("batch", "plan", inputs, ok=False))
        assert shallow["total"] == 2
        clean = work / "clean"
        clean.mkdir()
        (clean / "one.flac").write_bytes(source)
        complete = decoded_json(cli("batch", "edit", clean, work / "clean-out", "--set=TITLE=Complete"))
        assert complete["failed"] == 0 and complete["succeeded"] == 1
        empty = work / "empty"
        empty.mkdir()
        assert decoded_json(cli("batch", "plan", empty))["total"] == 0
        symlink_case = "unavailable"
        try:
            (inputs / "link.flac").symlink_to(original)
            linked = decoded_json(cli("batch", "plan", inputs, ok=False))
            assert linked["skipped_symlinks"] == 1 and linked["total"] == 2
            symlink_case = "skipped without traversal"
        except OSError:
            pass
        assert error_code(cli("inspect", work / "missing.flac", ok=False)) == "ENOENT"
        assert error_code(cli("plan", original, "--padding=bad", ok=False)) == "INVALID_ARGUMENT"
        assert error_code(cli("plan", original, "--set=TITLE=" + "x" * 12000, ok=False)) == "PADDING_NO_SPACE"
        # Inject publication races and interruption through the actual CLI process.
        target = work / "atomic.flac"
        hook = work / "atomic-hook.cjs"
        for mode in ["observe", "race", "link-error", "interrupt"]:
            target.unlink(missing_ok=True)
            hook.write_text("const TARGET=" + json.dumps(str(target)) + "; const MODE=" + json.dumps(mode) + ";\n" + r'''
const fs = require('node:fs');
const write = fs.writeSync, link = fs.linkSync;
fs.writeSync = function(...args) {
  if (fs.existsSync(TARGET)) throw new Error('destination appeared before publication');
  const n = write.apply(fs,args);
  if (MODE === 'interrupt') process.exit(97);
  return n;
};
fs.linkSync = function(a,b) {
  if (MODE === 'race') {
    const fd = fs.openSync(TARGET,'wx'), data = Buffer.from('racing owner');
    write.call(fs,fd,data,0,data.length); fs.closeSync(fd);
  }
  if (MODE === 'link-error') throw Object.assign(new Error('injected link failure'), {code:'EPERM'});
  return link.call(fs,a,b);
};
''', encoding="utf-8")
            p = subprocess.run(["node", "--require", str(hook), str(MAIN), "edit", str(original), str(target), "--set=TITLE=Atomic"], cwd=ROOT, capture_output=True)
            if mode == "observe":
                assert p.returncode == 0, p.stderr
                assert metadata(target.read_bytes())[2] == audio
            elif mode == "race":
                assert error_code(p) == "EEXIST" and target.read_bytes() == b"racing owner"
            elif mode == "link-error":
                assert error_code(p) == "EPERM" and not target.exists()
            else:
                assert p.returncode == 97 and not target.exists()
            temps = list(work.glob(".moonflactag-*.tmp"))
            if mode != "interrupt":
                assert temps == [], (mode, temps)
            else:
                assert len(temps) == 1
                temps[0].unlink()
        assert original.read_bytes() == source
    result = {"material_date":"2026-10-22", "artwork":"PNG/JPEG headers, selective replacement, append, remove, exact export, legacy replacement passed",
              "batch":"preview, recursion, stable ordering, partial failure, collisions, disjoint roots, empty directories passed",
              "symlinks":symlink_case, "structured_errors":True,
              "atomic_publication":{"destination_hidden_until_complete":True,"racing_destination_preserved":True,"publish_failure_cleanup":True,"forced_exit_leaves_no_destination":True},
              "original_audio_preserved":True}
    (EVIDENCE / "product-workflows.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
