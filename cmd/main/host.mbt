///|
#external
type Source

///|
// Read a bounded prefix from a pinned descriptor; format decisions stay in MoonBit.
extern "js" fn open_source(path : String) -> Source =
  #|(path) => {
  #|  const fs = require('node:fs'); let fd = null;
  #|  try {
  #|    fd = fs.openSync(path, 'r');
  #|    const stat = fs.fstatSync(fd, {bigint:true});
  #|    if (!stat.isFile() || stat.size > BigInt(Number.MAX_SAFE_INTEGER)) throw new Error('input must be a regular file with an exact host size');
  #|    const prefix = Buffer.alloc(Math.min(Number(stat.size), 16777216));
  #|    let pos = 0;
  #|    while (pos < prefix.length) {
  #|      const n = fs.readSync(fd, prefix, pos, prefix.length - pos, pos);
  #|      if (n === 0) throw new Error('input changed or was truncated while reading');
  #|      pos += n;
  #|    }
  #|    return {fd, stat, prefix:new Uint8Array(prefix), error:''};
  #|  } catch (e) {
  #|    if (fd !== null) { try { fs.closeSync(fd); } catch (_) {} }
  #|    return {fd:null, prefix:new Uint8Array(), error:String(e.message || e)};
  #|  }
  #|}

///|
extern "js" fn source_error(source : Source) -> String =
  #|(s) => s.error

///|
extern "js" fn source_prefix(source : Source) -> Bytes =
  #|(s) => s.prefix

///|
extern "js" fn source_size(source : Source) -> Double =
  #|(s) => Number(s.stat.size)

///|
extern "js" fn close_source(source : Source) -> Unit =
  #|(s) => { if (s.fd !== null) { try { require('node:fs').closeSync(s.fd); } catch (_) {} s.fd = null; } }

///|
// New output only. Short writes are retried; ordinary failures remove our own file.
extern "js" fn copy_output(
  source : Source,
  output : String,
  metadata : Bytes,
  old_offset : Int,
) -> String =
  #|(s, output, metadata, oldOffset) => {
  #|  const fs = require('node:fs'); let out = null, created = null;
  #|  const unchanged = () => {
  #|    const now = fs.fstatSync(s.fd, {bigint:true});
  #|    return now.size === s.stat.size && now.mtimeNs === s.stat.mtimeNs && now.ctimeNs === s.stat.ctimeNs;
  #|  };
  #|  try {
  #|    if (!unchanged()) throw new Error('source changed since inspection');
  #|    if (oldOffset < 42 || oldOffset > Number(s.stat.size)) throw new Error('invalid source audio boundary');
  #|    out = fs.openSync(output, 'wx');
  #|    created = fs.fstatSync(out, {bigint:true});
  #|    const writeAll = (data, count) => {
  #|      let pos = 0;
  #|      while (pos < count) {
  #|        const n = fs.writeSync(out, data, pos, count - pos);
  #|        if (n <= 0) throw new Error('output write made no progress');
  #|        pos += n;
  #|      }
  #|    };
  #|    writeAll(metadata, metadata.length);
  #|    const chunk = Buffer.alloc(1048576); let pos = oldOffset;
  #|    while (pos < Number(s.stat.size)) {
  #|      const n = fs.readSync(s.fd, chunk, 0, Math.min(chunk.length, Number(s.stat.size) - pos), pos);
  #|      if (n === 0) throw new Error('source truncated during copy');
  #|      writeAll(chunk, n); pos += n;
  #|    }
  #|    if (!unchanged()) throw new Error('source changed during copy');
  #|    fs.fsyncSync(out); fs.closeSync(out); out = null;
  #|    return '';
  #|  } catch (e) {
  #|    if (out !== null) { try { fs.closeSync(out); } catch (_) {} }
  #|    if (created !== null) {
  #|      try {
  #|        const pathStat = fs.lstatSync(output, {bigint:true});
  #|        if (pathStat.dev === created.dev && pathStat.ino === created.ino) fs.unlinkSync(output);
  #|      } catch (_) {}
  #|    }
  #|    return String(e.message || e);
  #|  }
  #|}
