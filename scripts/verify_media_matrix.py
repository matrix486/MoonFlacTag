"""Independent FFmpeg oracle across rates, channel counts and FLAC bit depths."""
import json
from verify import ROOT, OUT, EVIDENCE, run, cli, metadata


def decoded(path):
    return run("ffmpeg", "-v", "error", "-i", path, "-map", "0:a:0", "-f", "s32le", "-").stdout


def main():
    work = OUT / "media-matrix"
    work.mkdir(parents=True, exist_ok=True)
    results = []
    for rate, channels, bits in [(22050, 1, 16), (48000, 2, 24), (96000, 2, 16), (48000, 6, 24)]:
        key = f"{rate}-{channels}-{bits}"
        before, after = work / f"{key}.flac", work / f"{key}-edited.flac"
        after.unlink(missing_ok=True)
        run("ffmpeg", "-v", "error", "-f", "lavfi", "-i", f"sine=frequency=733:duration=0.18:sample_rate={rate}", "-ac", channels, "-c:a", "flac", "-sample_fmt", "s16" if bits == 16 else "s32", "-bits_per_raw_sample", bits, "-metadata", "title=Matrix source", "-y", before)
        original_pcm = decoded(before)
        before_meta = metadata(before.read_bytes())
        cli("edit", before, after, "--set=TITLE=矩阵🌙", "--add=ARTIST=A", "--add=artist=B", "--compact")
        output_meta = metadata(after.read_bytes())
        assert before_meta[2] == output_meta[2]
        assert decoded(after) == original_pcm
        actual = json.loads(cli("inspect", after).stdout)
        probe = json.loads(run("ffprobe", "-v", "error", "-show_entries", "stream=sample_rate,channels,bits_per_raw_sample:format_tags", "-of", "json", after).stdout)
        s = probe["streams"][0]
        assert int(s["sample_rate"]) == actual["stream"]["sample_rate"] == rate
        assert s["channels"] == actual["stream"]["channels"] == channels
        assert int(s["bits_per_raw_sample"]) == actual["stream"]["bits_per_sample"] == bits
        assert {k.lower(): v for k, v in probe["format"]["tags"].items()}["title"] == "矩阵🌙"
        results.append({"sample_rate": rate, "channels": channels, "bits": bits, "pcm_s32le_bytes": len(original_pcm), "audio_bytes": len(before_meta[2]), "compressed_identical": True, "decoded_identical": True, "metadata_matches_ffprobe": True})
    result = {"material_date": "2026-10-22", "fixtures": "generated sine; not third-party recordings", "cases": results}
    (EVIDENCE / "media-matrix.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
