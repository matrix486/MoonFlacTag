"""A second encoder path (libsndfile), complex metadata, independent PCM checks."""
import json
import struct
import tempfile
import numpy as np
import soundfile as sf
from verify import ROOT, OUT, EVIDENCE, run, cli, inspect, metadata, material_date


def block(kind, data, last=False):
    return bytes([kind | (128 if last else 0)]) + len(data).to_bytes(3,"big") + data


def comments(vendor, entries):
    values = [f"{k}={v}".encode("utf-8") for k,v in entries]
    vendor = vendor.encode("utf-8")
    return struct.pack("<I",len(vendor)) + vendor + struct.pack("<I",len(values)) + b"".join(struct.pack("<I",len(v))+v for v in values)


def main():
    rows = []
    with tempfile.TemporaryDirectory(prefix="corpus-", dir=OUT) as tmp:
        from pathlib import Path
        work = Path(tmp)
        for subtype,channels,rate in [("PCM_S8",1,16000),("PCM_16",2,44100),("PCM_24",2,48000)]:
            n = 2400
            t = np.arange(n,dtype=np.float64)/rate
            signal = np.column_stack([0.25*np.sin(2*np.pi*(137+c*83)*t) for c in range(channels)])
            original, tagged, edited = [work/f"{subtype}-{name}.flac" for name in ["original","tagged","edited"]]
            sf.write(original,signal,rate,format="FLAC",subtype=subtype)
            raw = original.read_bytes()
            boundary, blocks, suffix = metadata(raw)
            # Metadata framing is independent Python code; no MoonFlacTag encoder used.
            entries = [("ARTIST","A"),("artist","B"),("TITLE","多语言 🌙 Ελληνικά العربية"),
                       ("EMPTY",""),("EQUALS","a=b=c"),("COMMENT","声"*32768),("CUSTOM FIELD","punctuation !#$%&'()*+,")]
            vendor = "\ufeffIndependent corpus vendor"
            kept = [(k,d) for k,d in blocks if k not in [1,4]]
            payloads = kept + [(2,b"TST0independent application"),(4,comments(vendor,entries)),(1,b"\0"*512)]
            tagged.write_bytes(b"fLaC"+b"".join(block(k,d,i==len(payloads)-1) for i,(k,d) in enumerate(payloads))+suffix)
            before = inspect(tagged)
            assert before["comments"]["vendor"] == vendor
            assert [(x["key"],x["value"]) for x in before["comments"]["entries"]] == entries
            cli("edit",tagged,edited,"--set=TITLE=Edited 🌙","--add=ARTIST=C","--remove=EMPTY")
            after = inspect(edited)
            assert after["comments"]["vendor"] == vendor
            assert [e["value"] for e in after["comments"]["entries"] if e["key"].lower()=="artist"] == ["A","B","C"]
            assert not any(e["key"]=="EMPTY" for e in after["comments"]["entries"])
            assert any(e["key"]=="COMMENT" and e["value"]=="声"*32768 for e in after["comments"]["entries"])
            assert metadata(edited.read_bytes())[2] == suffix
            assert (2,b"TST0independent application") in metadata(edited.read_bytes())[1]
            a, sr1 = sf.read(tagged,dtype="int32",always_2d=True)
            b, sr2 = sf.read(edited,dtype="int32",always_2d=True)
            assert sr1 == sr2 == rate and np.array_equal(a,b)
            pcm = run("ffmpeg","-v","error","-i",edited,"-map","0:a:0","-f","s32le","-").stdout
            assert pcm == b.astype("<i4",copy=False).tobytes()
            rows.append({"encoder":"libsndfile FLAC", "subtype":subtype,"rate":rate,"channels":channels,
                         "samples":n,"complex_comment_bytes":len(comments(vendor,entries)),
                         "compressed_identical":True,"libsndfile_pcm_identical":True,"ffmpeg_pcm_matches":True})
    result = {"material_date":material_date(),"soundfile":sf.__version__,"libsndfile":sf.__libsndfile_version__,
              "numpy":np.__version__,"cases":rows,
              "source":"locally generated signal; complex comments encoded independently; no third-party recordings"}
    (EVIDENCE/"compatibility-corpus.json").write_text(json.dumps(result,indent=2)+"\n",encoding="utf-8")
    print(json.dumps(result,indent=2))


if __name__=="__main__":
    main()
