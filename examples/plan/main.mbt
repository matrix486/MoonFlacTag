///|
// Synthetic metadata only; suitable for a streaming host with external audio.
fn main raise {
  let info = b"\x00\x10\x00\x10\x00\x00\x00\x00\x00\x00\x0a\xc4\x42\xf0\x00\x00\xac\x44" +
    Bytes::make(16, b'\x00')
  let prefix = b"fLaC\x00\x00\x00\x22" +
    info +
    b"\x81\x00\x00\x80" +
    Bytes::make(128, b'\x00')
  let plan = @flac.plan_metadata(prefix, [
    Set("TITLE", "MoonFlacTag"),
    Add("ARTIST", "A"),
    Add("artist", "B"),
  ])
  println(@hex.encode(plan.metadata))
}
