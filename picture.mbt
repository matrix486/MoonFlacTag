///|
fn validate_picture(picture : Picture) -> Unit raise FlacError {
  guard picture.kind >= 0 && picture.kind <= 20 else {
    raise Invalid(0, "reserved picture type")
  }
  guard !picture.media_type.is_empty() else {
    raise Invalid(0, "empty picture media type")
  }
  for c in picture.media_type.code_units() {
    guard c.to_int() >= 0x20 && c.to_int() <= 0x7e else {
      raise Invalid(0, "picture media type must be printable ASCII")
    }
  }
  if picture.kind == 1 {
    guard picture.media_type == "image/png" &&
      picture.width == 32U &&
      picture.height == 32U else {
      raise Invalid(0, "type 1 icon requires 32x32 image/png")
    }
  }
}

///|
pub fn decode_picture(data : Bytes) -> Picture raise FlacError {
  check_block_size(data.length())
  let r = { data, pos: 0, }
  let kind = r.u32()
  guard kind <= 20U else { raise Invalid(0, "reserved picture type") }
  let media_type = text(r.sized())
  let description = text(r.sized())
  let width = r.u32()
  let height = r.u32()
  let depth = r.u32()
  let colors = r.u32()
  let image = r.sized()
  guard r.pos == data.length() else {
    raise Invalid(r.pos, "trailing bytes in picture")
  }
  let picture = {
    kind: kind.reinterpret_as_int(),
    media_type,
    description,
    width,
    height,
    depth,
    colors,
    data: image,
  }
  validate_picture(picture)
  picture
}

///|
pub fn encode_picture(picture : Picture) -> Bytes raise FlacError {
  validate_picture(picture)
  let mime = text_bytes(picture.media_type)
  let description = text_bytes(picture.description)
  guard mime.length() <= MaxBlock - 32 &&
    description.length() <= MaxBlock - 32 - mime.length() &&
    picture.data.length() <=
    MaxBlock - 32 - mime.length() - description.length() else {
    raise Limit("picture exceeds metadata block limit")
  }
  let out = @buffer.Buffer()
  out.write_uint_be(picture.kind.reinterpret_as_uint())
  put_sized(out, mime)
  put_sized(out, description)
  out.write_uint_be(picture.width)
  out.write_uint_be(picture.height)
  out.write_uint_be(picture.depth)
  out.write_uint_be(picture.colors)
  put_sized(out, picture.data)
  out.to_bytes()
}
