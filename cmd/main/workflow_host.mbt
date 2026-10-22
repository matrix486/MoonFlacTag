///|
extern "js" fn emit_progress(
  current : Int,
  total : Int,
  relative : String,
) -> Unit =
  #|(current,total,relative) => console.error(JSON.stringify({progress:current,total,relative}))

///|
extern "js" fn existing_destination(output : String) -> String =
  #|(output) => {
  #|  const fs = require('node:fs');
  #|  try {
  #|    const st = fs.lstatSync(output);
  #|    if (st.isFile()) return 'file';
  #|    throw Object.assign(new Error('existing output is not a regular file'), {code:'EEXIST'});
  #|  } catch (e) {
  #|    if (e.code === 'ENOENT') return '';
  #|    return JSON.stringify({code:e.code || 'IO_ERROR', operation:'skip', path:output, message:String(e.message || e)});
  #|  }
  #|}

///|
extern "js" fn prepare_report(output : String) -> String =
  #|(output) => {
  #|  const fs = require('node:fs');
  #|  try {
  #|    if (!output.toLowerCase().endsWith('.json')) throw Object.assign(new Error('report filename must end in .json'), {code:'INVALID_ARGUMENT'});
  #|    try { fs.lstatSync(output); throw Object.assign(new Error('report already exists'), {code:'EEXIST'}); }
  #|    catch (e) { if (e.code !== 'ENOENT') throw e; }
  #|    return '';
  #|  } catch (e) { return JSON.stringify({code:e.code || 'IO_ERROR', operation:'report', path:output, message:String(e.message || e)}); }
  #|}

///|
extern "js" fn save_report(output : String, text : String) -> String =
  #|(output,text) => {
  #|  const fs = require('node:fs'), path = require('node:path');
  #|  let fd = null, temp = null, created = null;
  #|  try {
  #|    fs.mkdirSync(path.dirname(output), {recursive:true});
  #|    temp = path.join(path.dirname(path.resolve(output)), '.moonflactag-' + require('node:crypto').randomUUID() + '.tmp');
  #|    fd = fs.openSync(temp,'wx',0o600); created = fs.fstatSync(fd,{bigint:true});
  #|    const data = Buffer.from(text,'utf8'); let offset = 0;
  #|    while (offset < data.length) {
  #|      const n = fs.writeSync(fd,data,offset,data.length-offset);
  #|      if (n <= 0) throw Object.assign(new Error('report write made no progress'),{code:'WRITE_NO_PROGRESS'});
  #|      offset += n;
  #|    }
  #|    fs.fsyncSync(fd); fs.closeSync(fd); fd = null;
  #|    fs.linkSync(temp,output);
  #|    return '';
  #|  } catch (e) { return JSON.stringify({code:e.code || 'IO_ERROR',operation:'report',path:output,message:String(e.message || e)}); }
  #|  finally {
  #|    if (fd !== null) { try { fs.closeSync(fd); } catch (_) {} }
  #|    if (created !== null) { try { const st=fs.lstatSync(temp,{bigint:true}); if (st.dev===created.dev && st.ino===created.ino) fs.unlinkSync(temp); } catch (_) {} }
  #|  }
  #|}
