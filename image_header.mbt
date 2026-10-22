///|
fn image_u32(data : Bytes, pos : Int) -> UInt {
  (data[pos].to_uint() << 24) |
  (data[pos + 1].to_uint() << 16) |
  (data[pos + 2].to_uint() << 8) |
  data[pos + 3].to_uint()
}

///|
/// Construct PNG/JPEG artwork from its image header; pixels and CRC are not decoded.
pub fn picture_from_image(
  data : Bytes,
  kind? : Int = 3,
  description? : String = "",
) -> Picture raise FlacError {
  check_block_size(data.length())
  let (media_type, width, height, depth) = if data.has_prefix(
      b"\x89PNG\r\n\x1a\n",
    ) {
    guard data.length() >= 33 && data[8:16] == b"\x00\x00\x00\x0dIHDR" else {
      raise Invalid(8, "missing complete PNG IHDR")
    }
    let width = image_u32(data, 16)
    let height = image_u32(data, 20)
    guard width > 0U &&
      height > 0U &&
      width <= 0x7fffffffU &&
      height <= 0x7fffffffU else {
      raise Invalid(16, "invalid PNG dimensions")
    }
    let bits = data[24].to_int()
    let channels = match data[25].to_int() {
      0 => {
        guard [1, 2, 4, 8, 16].contains(bits) else {
          raise Invalid(24, "invalid PNG bit depth")
        }
        1
      }
      2 => {
        guard bits == 8 || bits == 16 else {
          raise Invalid(24, "invalid PNG bit depth")
        }
        3
      }
      3 => {
        guard [1, 2, 4, 8].contains(bits) else {
          raise Invalid(24, "invalid PNG bit depth")
        }
        1
      }
      4 => {
        guard bits == 8 || bits == 16 else {
          raise Invalid(24, "invalid PNG bit depth")
        }
        2
      }
      6 => {
        guard bits == 8 || bits == 16 else {
          raise Invalid(24, "invalid PNG bit depth")
        }
        4
      }
      _ => raise Invalid(25, "invalid PNG color type")
    }
    guard data[26] == b'\x00' && data[27] == b'\x00' && data[28].to_int() <= 1 else {
      raise Invalid(26, "unsupported PNG IHDR methods")
    }
    ("image/png", width, height, (bits * channels).reinterpret_as_uint())
  } else if data.has_prefix(b"\xff\xd8") {
    jpeg_dimensions(data)
  } else {
    raise Invalid(0, "cover must have a PNG or JPEG header")
  }
  let picture = {
    kind,
    media_type,
    description,
    width,
    height,
    depth,
    colors: 0U,
    data,
  }
  validate_picture(picture)
  ignore(encode_picture(picture))
  picture
}

///|
fn jpeg_dimensions(data : Bytes) -> (String, UInt, UInt, UInt) raise FlacError {
  let mut pos = 2
  for ;; {
    guard pos < data.length() && data[pos] == b'\xff' else {
      raise Invalid(pos, "missing JPEG marker")
    }
    for ;; {
      pos += 1
      guard pos < data.length() else {
        raise Invalid(pos, "truncated JPEG marker")
      }
      if data[pos] != b'\xff' {
        break
      }
    }
    let marker = data[pos].to_int()
    pos += 1
    guard marker != 0xda && marker != 0xd9 else {
      raise Invalid(pos, "JPEG lacks a supported SOF header")
    }
    guard marker != 0 && marker != 0xd8 && !(marker >= 0xd0 && marker <= 0xd7) else {
      raise Invalid(pos, "unexpected JPEG standalone marker")
    }
    if marker == 1 {
      continue
    }
    guard data.length() - pos >= 2 else {
      raise Invalid(pos, "truncated JPEG segment length")
    }
    let length = (data[pos].to_int() << 8) | data[pos + 1].to_int()
    guard length >= 2 && length <= data.length() - pos else {
      raise Invalid(pos, "truncated JPEG segment")
    }
    let sof = marker >= 0xc0 &&
      marker <= 0xcf &&
      marker != 0xc4 &&
      marker != 0xc8 &&
      marker != 0xcc
    if sof {
      guard length >= 8 else { raise Invalid(pos, "short JPEG SOF") }
      let precision = data[pos + 2].to_int()
      let height = (data[pos + 3].to_int() << 8) | data[pos + 4].to_int()
      let width = (data[pos + 5].to_int() << 8) | data[pos + 6].to_int()
      let components = data[pos + 7].to_int()
      guard precision > 0 &&
        height > 0 &&
        width > 0 &&
        components > 0 &&
        length == 8 + components * 3 else {
        raise Invalid(pos, "invalid JPEG SOF dimensions or components")
      }
      return (
        "image/jpeg",
        width.reinterpret_as_uint(),
        height.reinterpret_as_uint(),
        (precision * components).reinterpret_as_uint(),
      )
    }
    pos += length
  }
}
