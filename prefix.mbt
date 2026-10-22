///|
/// Frame only the metadata prefix; parse/plan validate payload semantics afterwards.
/// Complete may be returned for a buffer that also contains audio.
pub fn metadata_prefix_length(data : Bytes) -> PrefixStatus raise FlacError {
  if data.length() < 4 {
    return NeedMore(4)
  }
  guard data.has_prefix(b"fLaC") else {
    raise Invalid(0, "missing native FLAC signature")
  }
  let mut pos = 4
  for n in 0..<MaxBlocks {
    guard pos <= MaxMetadata - 4 else {
      raise Limit("metadata budget exceeded")
    }
    if data.length() < pos + 4 {
      return NeedMore(pos + 4)
    }
    let kind = data[pos].to_int() & 127
    guard kind != 127 else { raise Invalid(pos, "forbidden block type 127") }
    guard n != 0 || kind == 0 else {
      raise Invalid(pos, "first block must be STREAMINFO")
    }
    let length = (data[pos + 1].to_int() << 16) |
      (data[pos + 2].to_int() << 8) |
      data[pos + 3].to_int()
    guard length <= MaxMetadata - pos - 4 else {
      raise Limit("metadata budget exceeded")
    }
    let end = pos + 4 + length
    if data.length() < end {
      return NeedMore(end)
    }
    if (data[pos].to_int() & 128) != 0 {
      return Complete(end)
    }
    pos = end
  }
  raise Limit("too many metadata blocks")
}
