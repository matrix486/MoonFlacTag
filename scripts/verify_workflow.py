"""User workflows: automatic padding, restartable batch, progress and UTF-8 reports."""
import json
from pathlib import Path
import subprocess
import tempfile
from verify import ROOT, OUT, EVIDENCE, cli, metadata, material_date


def main():
    OUT.mkdir(exist_ok=True, parents=True)
    with tempfile.TemporaryDirectory(prefix="workflow-", dir=OUT) as tmp:
        work = Path(tmp)
        raw = (ROOT / "fixtures/tone.flac").read_bytes()
        input_file = work / "输入 曲目.flac"
        input_file.write_bytes(raw)
        tag = "--set=TITLE=" + "曲目" * 5000
        report_file = work / "logs/预览.json"
        preview = json.loads(cli("plan", input_file, tag, "--report=" + str(report_file)).stdout)
        assert preview == json.loads(report_file.read_text(encoding="utf-8"))
        assert preview["metadata_delta"] > 0 and preview["preview"]
        assert input_file.read_bytes() == raw
        strict = cli("plan", input_file, tag, "--preserve-offset", ok=False)
        assert json.loads(strict.stderr)["code"] == "PADDING_NO_SPACE"
        # Last explicit strategy wins; default CLI can handle ordinary full-size covers/tags.
        assert cli("plan", input_file, tag, "--preserve-offset", "--auto-padding").returncode == 0
        strict_last = cli("plan", input_file, tag, "--auto-padding", "--preserve-offset", ok=False)
        assert json.loads(strict_last.stderr)["code"] == "PADDING_NO_SPACE"
        output_file = work / "new/album/tagged.flac"
        cli("edit", input_file, output_file, tag)
        assert metadata(output_file.read_bytes())[2] == metadata(raw)[2]
        # Existing report is rejected before any edits, even if it is a dangling link.
        blocked = work / "should-not-exist.flac"
        conflict = cli("edit", input_file, blocked, "--report=" + str(report_file), ok=False)
        assert json.loads(conflict.stderr)["code"] == "EEXIST" and not blocked.exists()
        for option in ["--report=a.txt", "--report="]:
            assert json.loads(cli("plan", input_file, option, ok=False).stderr)["code"] == "INVALID_ARGUMENT"
        assert json.loads(cli("plan", input_file, "--report=a.json", "--report=b.json", ok=False).stderr)["code"] == "INVALID_ARGUMENT"
        # A late report collision must not hide completed results or overwrite its owner.
        late_report, completed = work / "late-report.json", work / "completed.flac"
        hook = work / "report-race.cjs"
        hook.write_text("const TARGET=" + json.dumps(str(late_report)) + ";\n" + "const fs=require('node:fs'),link=fs.linkSync; fs.linkSync=function(a,b){ if(b===TARGET) fs.writeFileSync(TARGET,'racing report owner',{flag:'wx'}); return link.call(fs,a,b); };\n", encoding="utf-8")
        late = subprocess.run(["node", "--require", str(hook), str(ROOT / "_build/js/debug/build/cmd/main/main.js"), "edit", str(input_file), str(completed), "--report=" + str(late_report)], cwd=ROOT, capture_output=True)
        assert late.returncode != 0 and json.loads(late.stdout)["preview"] is False
        assert json.loads(late.stderr)["operation"] == "report"
        assert late_report.read_text() == "racing report owner"
        assert metadata(completed.read_bytes())[2] == metadata(raw)[2]
        assert not list(work.glob(".moonflactag-*.tmp"))
        inputs, outputs = work / "album in", work / "album out"
        (inputs / "disc 2").mkdir(parents=True)
        (inputs / "01.flac").write_bytes(raw)
        (inputs / "disc 2/02.FLAC").write_bytes(raw)
        (inputs / "bad.flac").write_bytes(b"bad")
        batch_report = work / "logs/执行.json"
        first = cli("batch", "edit", inputs, outputs, "--recursive", "--set=ALBUM=专辑 A", "--progress", "--report=" + str(batch_report), ok=False)
        summary = json.loads(first.stdout)
        assert summary == json.loads(batch_report.read_text(encoding="utf-8"))
        assert (summary["total"], summary["succeeded"], summary["failed"], summary["skipped"]) == (3, 2, 1, 0)
        progress = [json.loads(line) for line in first.stderr.splitlines()]
        assert [p["progress"] for p in progress] == [1, 2, 3]
        saved = {p: p.read_bytes() for p in outputs.rglob("*.flac")}
        (inputs / "bad.flac").write_bytes(raw)
        second = json.loads(cli("batch", "edit", inputs, outputs, "--recursive", "--set=ALBUM=专辑 A", "--skip-existing").stdout)
        assert (second["succeeded"], second["failed"], second["skipped"]) == (1, 0, 2)
        assert sum(r["status"] == "skipped" for r in second["results"]) == 2
        for file, data in saved.items():
            assert file.read_bytes() == data
        assert json.loads(cli("batch", "plan", inputs, "--skip-existing", ok=False).stderr)["code"] == "INVALID_ARGUMENT"
        # A directory must not be accepted as a successfully skipped music file.
        (outputs / "bad.flac").unlink()
        (outputs / "bad.flac").mkdir()
        bad_destination = json.loads(cli("batch", "edit", inputs, outputs, "--recursive", "--skip-existing", ok=False).stdout)
        assert bad_destination["failed"] == 1 and bad_destination["skipped"] == 2
        assert cli().returncode == 0 and cli("batch", "edit", "--help").returncode == 0
    result = {"material_date": material_date(), "automatic_padding_and_strict_override": "passed", "nested_output_parents": "passed", "utf8_reports_and_preflight_conflicts": "passed", "partial_batch_progress_and_restart": "passed", "nonregular_skip_rejected": "passed"}
    (EVIDENCE / "cli-workflows.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
