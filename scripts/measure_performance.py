"""Instrumented local baseline: source I/O counts, elapsed time and Node peak RSS."""
import json
from pathlib import Path
import subprocess
import tempfile
import time
from verify import ROOT, OUT, EVIDENCE, metadata

MAIN=ROOT/"_build/js/debug/build/cmd/main/main.js"


def main():
    rows=[]
    with tempfile.TemporaryDirectory(prefix="performance-",dir=OUT) as tmp:
        work=Path(tmp)
        raw=(ROOT/"fixtures/tone.flac").read_bytes()
        boundary=metadata(raw)[0]
        source=work/"synthetic.flac"
        size=64*1024*1024+boundary
        with source.open("wb") as f:
            f.write(raw[:boundary])
            f.truncate(size)
        hook=work/"profile.cjs"
        metrics=work/"metrics.json"
        hook.write_text("const INPUT="+json.dumps(str(source))+"; const METRICS="+json.dumps(str(metrics))+";\n"+r'''
const fs=require('node:fs'),path=require('node:path');
const open=fs.openSync,read=fs.readSync,close=fs.closeSync;
const descriptors=new Set(); let bytes=0,calls=0;
fs.openSync=function(p,...args) {const fd=open.call(fs,p,...args); if(typeof p==='string'&&path.resolve(p)===path.resolve(INPUT))descriptors.add(fd); return fd;};
fs.closeSync=function(fd) {descriptors.delete(fd); return close.call(fs,fd);};
fs.readSync=function(fd,...args) {const n=read.call(fs,fd,...args);if(descriptors.has(fd)){bytes+=n;calls++;}return n;};
process.on('exit',()=>fs.writeFileSync(METRICS,JSON.stringify({source_bytes_read:bytes,read_calls:calls,node_max_rss_kib:process.resourceUsage().maxRSS})));
''',encoding="utf-8")
        for operation in ["inspect","edit"]:
            args=[operation,str(source)]
            if operation=="edit":
                args += [str(work/"out.flac"),"--set=TITLE=Profile"]
            start=time.perf_counter()
            p=subprocess.run(["node","--require",str(hook),str(MAIN),*args],cwd=ROOT,capture_output=True,check=True)
            elapsed=time.perf_counter()-start
            measured=json.loads(metrics.read_text())
            assert measured["source_bytes_read"]==(boundary if operation=="inspect" else size)
            assert json.loads(p.stdout)["audio_offset"]==boundary
            rows.append({"operation":operation,"synthetic_file_bytes":size,"metadata_bytes":boundary,
                         "wall_seconds_including_node_startup":round(elapsed,6),**measured})
    result={"material_date":"2026-10-22","runs":rows,
            "method":"One local instrumented run per operation; sparse synthetic suffix; timing includes Node startup and read counters. RSS is Node resourceUsage maxRSS, not a general performance guarantee."}
    (EVIDENCE/"performance-baseline.json").write_text(json.dumps(result,indent=2)+"\n",encoding="utf-8")
    print(json.dumps(result,indent=2))


if __name__=="__main__":
    main()
