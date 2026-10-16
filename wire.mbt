///|
const MaxMetadata : Int = 16777216

///|
const MaxBlock : Int = 16777215

///|
const MaxBlocks : Int = 4096

///|
priv struct Reader {
  data : Bytes
  mut pos : Int
}

///|
fn Reader::take(self : Reader, count : Int) -> Bytes raise FlacError {
  guard count >= 0 && count <= self.data.length() - self.pos else {
    raise Invalid(self.pos, "truncated field")
  }
  let result = self.data[self.pos:self.pos + count].to_owned()
  self.pos += count
  result
}

///|
fn Reader::u32(self : Reader, little? : Bool = false) -> UInt raise FlacError {
  let b = self.take(4)
  if little {
    b[0].to_uint() |
    (b[1].to_uint() << 8) |
    (b[2].to_uint() << 16) |
    (b[3].to_uint() << 24)
  } else {
    (b[0].to_uint() << 24) |
    (b[1].to_uint() << 16) |
    (b[2].to_uint() << 8) |
    b[3].to_uint()
  }
}

///|
fn Reader::sized(
  self : Reader,
  little? : Bool = false,
) -> Bytes raise FlacError {
  let n = self.u32(little~)
  guard n <= (self.data.length() - self.pos).reinterpret_as_uint() else {
    raise Invalid(self.pos, "length exceeds block")
  }
  self.take(n.reinterpret_as_int())
}

///|
fn text(data : Bytes) -> String raise FlacError {
  @utf8.decode(data, ignore_bom=false) catch {
    _ => raise Invalid(0, "invalid UTF-8")
  }
}

///|
// Reject malformed UTF-16 before the core UTF-8 encoder, which assumes validity.
fn text_bytes(value : String) -> Bytes raise FlacError {
  let units = value.code_units()
  for i = 0; i < units.length(); {
    let c = units[i].to_int()
    if c >= 0xd800 && c <= 0xdbff {
      guard i + 1 < units.length() &&
        units[i + 1].to_int() >= 0xdc00 &&
        units[i + 1].to_int() <= 0xdfff else {
        raise Invalid(i, "unpaired UTF-16 surrogate")
      }
      continue i + 2
    } else {
      guard c < 0xdc00 || c > 0xdfff else {
        raise Invalid(i, "unpaired UTF-16 surrogate")
      }
      continue i + 1
    }
  }
  @utf8.encode(value)
}

///|
fn put_sized(
  out : @buffer.Buffer,
  data : Bytes,
  little? : Bool = false,
) -> Unit raise FlacError {
  guard data.length() <= MaxBlock else {
    raise Limit("field exceeds 24-bit block limit")
  }
  if little {
    out.write_uint_le(data.length().reinterpret_as_uint())
  } else {
    out.write_uint_be(data.length().reinterpret_as_uint())
  }
  out.write_bytes(data)
}

///|
fn check_block_size(size : Int) -> Unit raise FlacError {
  guard size <= MaxBlock else {
    raise Limit("metadata block exceeds 24-bit size")
  }
}
