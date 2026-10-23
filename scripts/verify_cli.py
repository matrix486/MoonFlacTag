"""Streaming and ordinary I/O fault checks through the actual compiled CLI."""
from pathlib import Path
import json
import subprocess
from verify import ROOT, OUT, EVIDENCE, cli, inspect, metadata, material_date


def main():
    work = OUT / "streaming"
    work.mkdir(parents=True, exist_ok=True)
    source = ROOT / "fixtures/tone.flac"
    raw = source.read_bytes()
    boundary, _, audio = metadata(raw)
    snapshot = set(work.iterdir())
    preview = json.loads(cli("plan", source, "--set=TITLE=Preview").stdout)
    assert preview["preview"] and preview["metadata_delta"] == 0
    assert set(work.iterdir()) == snapshot and source.read_bytes() == raw
    exact = work / "exact.flac"
    exact.unlink(missing_ok=True)
    applied = json.loads(cli("edit", source, exact, "--set=TITLE=Exact", "--padding=17").stdout)
    offset, blocks, suffix = metadata(exact.read_bytes())
    assert blocks[-1] == (1, b"\0" * 17) and suffix == audio
    assert applied["output_bytes"] == exact.stat().st_size
    for args in [("inspect", work / "missing.flac"), ("inspect", work), ("plan", source, "--padding=-1"), ("plan", source, "--padding=16777216"), ("plan", source, "--padding="), ("plan", source, "--cover-png=" + str(source))]:
        result = cli(*args, ok=False)
        assert result.returncode != 0 and result.stdout == b""
        assert isinstance(json.loads(result.stderr)["error"], str)
        assert b"at Module" not in result.stderr
    assert cli("--help").returncode == 0
    assert "0.4.0" in cli("--version").stdout.decode()
    # Inject ordinary host failures, not fake success paths in the core library.
    hook = work / "fault.cjs"
    base_hook = r'''
const fs = require('node:fs');
const originalWrite = fs.writeSync, originalRead = fs.readSync;
let writes = 0, reads = 0;
fs.writeSync = function(fd, data, offset, length, position) {
  writes++;
  if (MODE === 'short') return originalWrite.call(fs, fd, data, offset, Math.min(length, 7), position);
  if (MODE === 'write' && writes === 2) throw new Error('injected write failure');
  if (MODE === 'zero') return 0;
  if (MODE === 'mutate' && writes === 1) fs.appendFileSync(INPUT, Buffer.from('changed'));
  return originalWrite.call(fs, fd, data, offset, length, position);
};
fs.readSync = function(...args) {
  reads++;
  if (MODE === 'read' && writes > 0) throw new Error('injected read failure');
  return originalRead.apply(fs, args);
};
if (MODE === 'sync') fs.fsyncSync = () => { throw new Error('injected fsync failure'); };
'''
    fault_results = {}
    for mode in ["short", "write", "zero", "read", "sync", "mutate"]:
        input_path, output_path = work / "fault-input.flac", work / "fault-output.flac"
        input_path.write_bytes(raw)
        output_path.unlink(missing_ok=True)
        hook.write_text("const MODE=" + json.dumps(mode) + "; const INPUT=" + json.dumps(str(input_path)) + ";\n" + base_hook, encoding="utf-8")
        p = subprocess.run(["node", "--require", str(hook), str(ROOT / "_build/js/debug/build/cmd/main/main.js"), "edit", str(input_path), str(output_path), "--set=TITLE=Fault test"], cwd=ROOT, capture_output=True)
        if mode == "short":
            assert p.returncode == 0, p.stderr
            assert metadata(output_path.read_bytes())[2] == audio
        else:
            assert p.returncode != 0 and not output_path.exists(), (mode, p.stderr)
            assert "error" in json.loads(p.stderr)
        if mode != "mutate":
            assert input_path.read_bytes() == raw
        fault_results[mode] = "passed"
    # Sparse synthetic suffix exercises >256 MiB host I/O, not audio validity.
    large_input, large_output = work / "large-synthetic.flac", work / "large-output.flac"
    large_size = 256 * 1024 * 1024 + 4097
    with large_input.open("wb") as f:
        f.write(raw[:boundary])
        f.truncate(large_size)
    large_output.unlink(missing_ok=True)
    assert inspect(large_input)["audio_bytes"] == large_size - boundary
    large = json.loads(cli("edit", large_input, large_output, "--set=TITLE=Large synthetic").stdout)
    assert large_output.stat().st_size == large_size
    assert large["audio_offset"] == boundary
    with large_input.open("rb") as a, large_output.open("rb") as b:
        a.seek(boundary)
        b.seek(boundary)
        while True:
            chunk = a.read(1024 * 1024)
            if not chunk:
                assert b.read(1) == b""
                break
            assert b.read(len(chunk)) == chunk
    # Remove the generated large pair after comparison; fixtures remain tiny.
    large_input.unlink()
    large_output.unlink()
    result = {"material_date": material_date(), "preview_no_write": True, "explicit_padding": True, "json_error_cases": 6, "host_faults": fault_results, "large_synthetic_bytes": large_size, "large_suffix_compared_byte_for_byte": True, "large_pair_removed_after_test": True}
    (EVIDENCE / "streaming-cli.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
