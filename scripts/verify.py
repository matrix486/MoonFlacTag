"""Verify MoonBit, real FLAC media and the CLI. No network or publishing."""
from pathlib import Path
import json
import shutil
import struct
import subprocess
import zlib

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "demo-output" / "verification"
EVIDENCE = ROOT / "docs" / "test-evidence"


def run(*args, ok=True):
    p = subprocess.run([str(a) for a in args], cwd=ROOT, capture_output=True)
    if ok and p.returncode:
        raise RuntimeError(f"Command failed: {args}\n{p.stdout.decode('utf-8', 'replace')}\n{p.stderr.decode('utf-8', 'replace')}")
    return p


def cli(*args, ok=True):
    return run("node", ROOT / "_build/js/debug/build/cmd/main/main.js", *args, ok=ok)


def inspect(path):
    return json.loads(cli("inspect", path).stdout)


def metadata(raw):
    """Independent framing oracle: does not import or call production parser."""
    assert raw[:4] == b"fLaC"
    pos, blocks = 4, []
    while True:
        flag = raw[pos]
        size = int.from_bytes(raw[pos + 1:pos + 4], "big")
        data = raw[pos + 4:pos + 4 + size]
        assert len(data) == size
        blocks.append((flag & 127, data))
        pos += 4 + size
        if flag & 128:
            return pos, blocks, raw[pos:]


def png():
    def chunk(kind, data):
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data))
    return b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", 1, 1, 8, 2, 0, 0, 0)) + chunk(b"IDAT", zlib.compress(b"\0\x2b\x6c\xb0")) + chunk(b"IEND", b"")


def pcm(path):
    return run("ffmpeg", "-v", "error", "-i", path, "-map", "0:a:0", "-f", "s16le", "-").stdout


def main():
    for tool in ["moon", "node", "ffmpeg", "ffprobe"]:
        if not shutil.which(tool):
            raise RuntimeError(f"Required verification tool missing: {tool}")
    OUT.mkdir(parents=True, exist_ok=True)
    EVIDENCE.mkdir(parents=True, exist_ok=True)
    checks = {}
    commands = [["moon", "fmt", "--check"]]
    for target in ["wasm-gc", "js"]:
        commands += [["moon", "check", "--target", target, "--warn-list", "+73", "--deny-warn"], ["moon", "test", "--target", target, "--deny-warn"], ["moon", "build", "--target", target, "--deny-warn"]]
    commands += [["moon", "info", "--target", "wasm-gc"]]
    for command in commands:
        p = run(*command)
        checks[" ".join(command)] = (p.stdout + p.stderr).decode("utf-8", "replace").strip()
        print("PASS", " ".join(command), flush=True)
    original = ROOT / "fixtures/tone.flac"
    cover = ROOT / "fixtures/cover.png"
    assert cover.read_bytes() == png()
    before = inspect(original)
    source = original.read_bytes()
    boundary, blocks, audio = metadata(source)
    assert before["audio_offset"] == boundary
    assert before["stream"]["sample_rate"] == 44100
    assert before["stream"]["channels"] == 1
    assert before["stream"]["total_samples"] == "11025"
    assert before["comments"]["entries"][0] == {"key": "title", "value": "Original"}
    expected_pcm = pcm(original)
    assert len(expected_pcm) == 22050
    # All outputs stay inside this script's dedicated output directory.
    names = ["tagged.flac", "covered.flac", "removed.flac", "unknown.flac", "unknown-edited.flac", "bad.flac", "bad-output.flac", "no-space.flac"]
    for name in names:
        path = OUT / name
        if path.exists():
            path.unlink()
    tagged, covered, removed = [OUT / n for n in names[:3]]
    cli("edit", original, tagged, "--set=TITLE=月亮🌙", "--add=ARTIST=Guest", "--remove=encoder")
    after = inspect(tagged)
    assert after["audio_offset"] == boundary
    assert metadata(tagged.read_bytes())[2] == audio
    assert pcm(tagged) == expected_pcm
    probe = json.loads(run("ffprobe", "-v", "error", "-show_entries", "format_tags:stream=codec_type,sample_rate,channels,bits_per_raw_sample", "-of", "json", tagged).stdout)
    tags = {k.lower(): v for k, v in probe["format"]["tags"].items()}
    assert tags["title"] == "月亮🌙"
    assert "Guest" in tags["artist"]
    assert "encoder" not in tags
    assert probe["streams"][0]["sample_rate"] == "44100"
    cli("edit", tagged, covered, f"--cover-png={cover}", "--compact")
    with_cover = inspect(covered)
    assert len(with_cover["pictures"]) == 1
    assert with_cover["pictures"][0]["bytes"] == len(cover.read_bytes())
    picture_probe = json.loads(run("ffprobe", "-v", "error", "-show_streams", "-of", "json", covered).stdout)
    picture_stream = [s for s in picture_probe["streams"] if s["codec_type"] == "video"]
    assert len(picture_stream) == 1
    assert picture_stream[0]["codec_name"] == "png"
    assert picture_stream[0]["width"] == picture_stream[0]["height"] == 1
    extracted = run("ffmpeg", "-v", "error", "-i", covered, "-map", "0:v:0", "-c", "copy", "-f", "image2pipe", "-").stdout
    assert extracted == cover.read_bytes()
    assert metadata(covered.read_bytes())[2] == audio
    assert pcm(covered) == expected_pcm
    cli("edit", covered, removed, "--remove-pictures", "--remove=artist", "--compact")
    assert inspect(removed)["pictures"] == []
    assert not any(e["key"].lower() == "artist" for e in inspect(removed)["comments"]["entries"])
    assert pcm(removed) == expected_pcm
    # Add an unknown block using independent framing, then verify preservation.
    extra = b"opaque-application-data"
    altered = bytearray(source[:boundary])
    pos = 4
    while True:
        size = int.from_bytes(altered[pos+1:pos+4], "big")
        if altered[pos] & 128:
            altered[pos] &= 127
            break
        pos += 4 + size
    altered += bytes([0x80 | 120]) + len(extra).to_bytes(3, "big") + extra + audio
    unknown, rewritten = OUT / "unknown.flac", OUT / "unknown-edited.flac"
    unknown.write_bytes(altered)
    cli("edit", unknown, rewritten, "--set=TITLE=Keep unknown", "--compact")
    _, rewritten_blocks, rewritten_audio = metadata(rewritten.read_bytes())
    assert (120, extra) in rewritten_blocks
    assert rewritten_audio == audio
    # Error paths must fail without producing an output or changing sources.
    bad = OUT / "bad.flac"
    bad.write_bytes(b"fLaC\x80\xff\xff\xff")
    bad_output = OUT / "bad-output.flac"
    assert cli("edit", bad, bad_output, "--set=TITLE=X", ok=False).returncode != 0
    assert not bad_output.exists()
    assert cli("edit", original, tagged, "--set=TITLE=Overwrite", ok=False).returncode != 0
    assert inspect(tagged) == after
    assert cli("inspect", ok=False).returncode != 0
    assert cli("edit", original, OUT / "no-space.flac", "--set=TITLE=" + "x" * 12000, ok=False).returncode != 0
    assert not (OUT / "no-space.flac").exists()
    assert original.read_bytes() == source
    result = {
        "material_date": "2026-10-17",
        "toolchain": run("moon", "version", "--all").stdout.decode().strip(),
        "ffmpeg": run("ffmpeg", "-version").stdout.decode().splitlines()[0],
        "node": run("node", "--version").stdout.decode().strip(),
        "checks": checks,
        "media": {"sample_rate": 44100, "channels": 1, "samples": 11025, "compressed_audio_bytes": len(audio), "decoded_pcm_bytes": len(expected_pcm), "original_audio_offset": boundary, "preserved_audio_offset": after["audio_offset"], "compressed_audio_identical": True, "decoded_pcm_identical": True, "ffprobe_tags_match": True, "cover_extracted_identical": True, "unknown_block_preserved": True, "cli_error_paths": "passed"},
    }
    (EVIDENCE / "local-verification.json").write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("PASS media oracle, artwork extraction, unknown blocks and CLI error paths")


if __name__ == "__main__":
    main()
