///|
fn validate_key(key : String) -> Unit raise FlacError {
  guard !key.is_empty() else { raise Invalid(0, "empty comment key") }
  for c in key.code_units() {
    guard c.to_int() >= 0x20 && c.to_int() <= 0x7d && c.to_int() != 0x3d else {
      raise Invalid(0, "comment key must be ASCII 0x20..0x7d except equals")
    }
  }
}

///|
pub fn decode_comments(data : Bytes) -> Comments raise FlacError {
  check_block_size(data.length())
  let r = { data, pos: 0, }
  let vendor = text(r.sized(little=true))
  let count = r.u32(little=true)
  // Each entry requires at least four length bytes. Check before allocating/looping.
  guard count <= ((data.length() - r.pos) / 4).reinterpret_as_uint() else {
    raise Invalid(r.pos, "comment count exceeds block")
  }
  let entries : Array[Comment] = []
  for _ in 0..<count.reinterpret_as_int() {
    let value = text(r.sized(little=true))
    guard value.split_once("=") is Some((key, content)) else {
      raise Invalid(r.pos, "comment lacks equals")
    }
    let key = key.to_owned()
    validate_key(key)
    entries.push({ key, value: content.to_owned(), })
  }
  guard r.pos == data.length() else {
    raise Invalid(r.pos, "trailing bytes in Vorbis comment")
  }
  { vendor, entries, }
}

///|
pub fn encode_comments(comments : Comments) -> Bytes raise FlacError {
  let out = @buffer.Buffer()
  put_sized(out, text_bytes(comments.vendor), little=true)
  out.write_uint_le(comments.entries.length().reinterpret_as_uint())
  for entry in comments.entries {
    validate_key(entry.key)
    let data = text_bytes("\{entry.key}=\{entry.value}")
    guard data.length() <= MaxBlock - out.length() - 4 else {
      raise Limit("comments exceed metadata block limit")
    }
    put_sized(out, data, little=true)
  }
  check_block_size(out.length())
  out.to_bytes()
}

///|
/// Preserve duplicate keys and their order; matching is ASCII case-insensitive.
pub fn Comments::values(self : Comments, key : String) -> Array[String] {
  self.entries.filter(e => e.key.equal_ignore_ascii_case(key)).map(e => e.value)
}

///|
fn edit_comments(
  comments : Comments,
  edits : Array[TagEdit],
) -> Comments raise FlacError {
  let mut entries = comments.entries.copy()
  for edit in edits {
    match edit {
      Set(key, value) => {
        validate_key(key)
        entries = entries.filter(e => !e.key.equal_ignore_ascii_case(key))
        entries.push({ key, value, })
      }
      Add(key, value) => {
        validate_key(key)
        entries.push({ key, value, })
      }
      Remove(key) => {
        validate_key(key)
        entries = entries.filter(e => !e.key.equal_ignore_ascii_case(key))
      }
    }
  }
  { vendor: comments.vendor, entries, }
}
