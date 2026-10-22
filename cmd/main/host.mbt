///|
#external
type Source

///|
extern "js" fn open_source(path : String) -> Source =
  #|(path) => {
  #|  const fs = require('node:fs'); let fd = null;
  #|  try {
  #|    fd = fs.openSync(path, fs.constants.O_RDONLY | (fs.constants.O_NONBLOCK || 0));
  #|    const stat = fs.fstatSync(fd, {bigint:true});
  #|    if (!stat.isFile() || stat.size > BigInt(Number.MAX_SAFE_INTEGER)) throw Object.assign(new Error('input must be a regular file with an exact host size'), {code:'INVALID_SOURCE'});
  #|    return {fd, stat, buffer:Buffer.alloc(256), loaded:0, error:''};
  #|  } catch (e) {
  #|    if (fd !== null) { try { fs.closeSync(fd); } catch (_) {} }
  #|    return {fd:null, error:JSON.stringify({code:e.code || 'IO_ERROR', operation:'open', path, message:String(e.message || e)})};
  #|  }
  #|}

///|
extern "js" fn source_error(source : Source) -> String =
  #|(s) => s.error

///|
extern "js" fn source_prefix(source : Source) -> Bytes =
  #|(s) => new Uint8Array(s.buffer.buffer, s.buffer.byteOffset, s.loaded)

///|
extern "js" fn source_size(source : Source) -> Double =
  #|(s) => Number(s.stat.size)

///|
extern "js" fn read_more(source : Source, target : Int) -> String =
  #|(s, target) => {
  #|  const fs = require('node:fs');
  #|  try {
  #|    if (target < s.loaded || target > 16777216 || target > Number(s.stat.size)) throw Object.assign(new Error('input ends before requested metadata or image bytes'), {code:'TRUNCATED_INPUT'});
  #|    if (target > s.buffer.length) {
  #|      const next = Buffer.alloc(Math.min(16777216, Math.max(target, s.buffer.length * 2)));
  #|      s.buffer.copy(next, 0, 0, s.loaded); s.buffer = next;
  #|    }
  #|    while (s.loaded < target) {
  #|      const n = fs.readSync(s.fd, s.buffer, s.loaded, target - s.loaded, s.loaded);
  #|      if (n === 0) throw Object.assign(new Error('input truncated during read'), {code:'TRUNCATED_INPUT'});
  #|      s.loaded += n;
  #|    }
  #|    return '';
  #|  } catch (e) {
  #|    return JSON.stringify({code:e.code || 'IO_ERROR', operation:'read', path:'', message:String(e.message || e)});
  #|  }
  #|}

///|
extern "js" fn close_source(source : Source) -> Unit =
  #|(s) => { if (s.fd !== null) { try { require('node:fs').closeSync(s.fd); } catch (_) {} s.fd = null; } }

///|
// Publish a complete file with a no-replace hard link from a same-directory temp.
extern "js" fn copy_output(
  source : Source,
  output : String,
  metadata : Bytes,
  old_offset : Int,
  copy_audio : Bool,
) -> String =
  #|(s, output, metadata, oldOffset, copyAudio) => {
  #|  const fs = require('node:fs'), path = require('node:path');
  #|  let out = null, temp = null, created = null, committed = false;
  #|  const unchanged = () => {
  #|    const now = fs.fstatSync(s.fd, {bigint:true});
  #|    return now.size === s.stat.size && now.mtimeNs === s.stat.mtimeNs && now.ctimeNs === s.stat.ctimeNs;
  #|  };
  #|  const clean = () => {
  #|    if (out !== null) { try { fs.closeSync(out); } catch (_) {} out = null; }
  #|    if (temp !== null && created !== null) {
  #|      try { const st = fs.lstatSync(temp, {bigint:true}); if (st.dev === created.dev && st.ino === created.ino) fs.unlinkSync(temp); } catch (_) {}
  #|    }
  #|  };
  #|  try {
  #|    if (!unchanged()) throw Object.assign(new Error('source changed since inspection'), {code:'SOURCE_CHANGED'});
  #|    if (copyAudio && (oldOffset < 42 || oldOffset > Number(s.stat.size))) throw Object.assign(new Error('invalid source audio boundary'), {code:'INVALID_BOUNDARY'});
  #|    if (fs.existsSync(output)) throw Object.assign(new Error('output already exists'), {code:'EEXIST'});
  #|    temp = path.join(path.dirname(path.resolve(output)), '.moonflactag-' + require('node:crypto').randomUUID() + '.tmp');
  #|    out = fs.openSync(temp, 'wx', 0o600); created = fs.fstatSync(out, {bigint:true});
  #|    const writeAll = (data, count) => {
  #|      let pos = 0;
  #|      while (pos < count) {
  #|        const n = fs.writeSync(out, data, pos, count - pos);
  #|        if (n <= 0) throw Object.assign(new Error('output write made no progress'), {code:'WRITE_NO_PROGRESS'});
  #|        pos += n;
  #|      }
  #|    };
  #|    writeAll(metadata, metadata.length);
  #|    if (copyAudio) {
  #|      const chunk = Buffer.alloc(1048576); let pos = oldOffset;
  #|      while (pos < Number(s.stat.size)) {
  #|        const n = fs.readSync(s.fd, chunk, 0, Math.min(chunk.length, Number(s.stat.size) - pos), pos);
  #|        if (n === 0) throw Object.assign(new Error('source truncated during copy'), {code:'SOURCE_CHANGED'});
  #|        writeAll(chunk, n); pos += n;
  #|      }
  #|    }
  #|    if (!unchanged()) throw Object.assign(new Error('source changed during copy'), {code:'SOURCE_CHANGED'});
  #|    fs.fsyncSync(out); fs.closeSync(out); out = null;
  #|    fs.linkSync(temp, output); committed = true;
  #|    clean(); return '';
  #|  } catch (e) {
  #|    clean();
  #|    if (committed) return '';
  #|    return JSON.stringify({code:e.code || 'IO_ERROR', operation:'save', path:output, message:String(e.message || e)});
  #|  }
  #|}

///|
#external
type DirectoryScan

///|
extern "js" fn scan_directory(
  input : String,
  output : String,
  recursive : Bool,
) -> DirectoryScan =
  #|(input, output, recursive) => {
  #|  const fs = require('node:fs'), path = require('node:path');
  #|  const canonical = (value) => {
  #|    let base = path.resolve(value), tail = [];
  #|    while (!fs.existsSync(base)) { const parent = path.dirname(base); if (parent === base) break; tail.unshift(path.basename(base)); base = parent; }
  #|    return path.join(fs.realpathSync(base), ...tail);
  #|  };
  #|  const contains = (a,b) => { const rel = path.relative(a,b); return rel === '' || (!rel.startsWith('..' + path.sep) && rel !== '..' && !path.isAbsolute(rel)); };
  #|  try {
  #|    const root = fs.realpathSync(input), dest = output === '' ? '' : canonical(output);
  #|    if (!fs.statSync(root).isDirectory()) throw Object.assign(new Error('batch input must be a directory'), {code:'ENOTDIR'});
  #|    if (dest !== '' && (contains(root,dest) || contains(dest,root))) throw Object.assign(new Error('batch input and output trees must be disjoint'), {code:'PATH_OVERLAP'});
  #|    const files = [], pending = ['']; let skipped = 0, visited = 0;
  #|    while (pending.length) {
  #|      const rel = pending.pop();
  #|      if (++visited > 20000) throw Object.assign(new Error('directory scan exceeds 20000 directories'), {code:'BATCH_LIMIT'});
  #|      for (const entry of fs.readdirSync(path.join(root,rel), {withFileTypes:true})) {
  #|        const next = path.join(rel,entry.name);
  #|        if (entry.isSymbolicLink()) { skipped++; continue; }
  #|        if (entry.isDirectory() && recursive) pending.push(next);
  #|        if (entry.isFile() && path.extname(entry.name).toLowerCase() === '.flac') {
  #|          files.push(next.split(path.sep).join('/'));
  #|          if (files.length > 10000) throw Object.assign(new Error('batch exceeds 10000 FLAC files'), {code:'BATCH_LIMIT'});
  #|        }
  #|      }
  #|    }
  #|    files.sort(); return {root, dest, files, skipped, error:''};
  #|  } catch (e) { return {error:JSON.stringify({code:e.code || 'IO_ERROR', operation:'scan', path:input, message:String(e.message || e)})}; }
  #|}

///|
extern "js" fn scan_error(scan : DirectoryScan) -> String =
  #|(s) => s.error

///|
extern "js" fn scan_files(scan : DirectoryScan) -> FixedArray[String] =
  #|(s) => s.files

///|
extern "js" fn scan_skipped(scan : DirectoryScan) -> Int =
  #|(s) => s.skipped

///|
extern "js" fn scan_path(
  scan : DirectoryScan,
  relative : String,
  output : Bool,
) -> String =
  #|(s, rel, output) => require('node:path').join(output ? s.dest : s.root, ...rel.split('/'))

///|
extern "js" fn ensure_parent(output : String) -> String =
  #|(output) => { try { require('node:fs').mkdirSync(require('node:path').dirname(output), {recursive:true}); return ''; } catch (e) { return JSON.stringify({code:e.code || 'IO_ERROR',operation:'mkdir',path:output,message:String(e.message || e)}); } }

///|
extern "js" fn exit_failure() -> Unit =
  #|() => { process.exitCode = 1; }
