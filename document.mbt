///|
fn stream_info(data : Bytes) -> StreamInfo raise FlacError {
  guard data.length() == 34 else {
    raise Invalid(0, "STREAMINFO must be 34 bytes")
  }
  let min_block = (data[0].to_int() << 8) | data[1].to_int()
  let max_block = (data[2].to_int() << 8) | data[3].to_int()
  guard min_block >= 16 && max_block >= min_block else {
    raise Invalid(0, "invalid STREAMINFO block sizes")
  }
  let sample_rate = (data[10].to_int() << 12) |
    (data[11].to_int() << 4) |
    (data[12].to_int() >> 4)
  let channels = ((data[12].to_int() >> 1) & 7) + 1
  let bits_per_sample = (
      ((data[12].to_int() & 1) << 4) | (data[13].to_int() >> 4)
    ) +
    1
  guard bits_per_sample >= 4 else { raise Invalid(13, "invalid bit depth") }
  let mut total = (data[13].to_int() & 15).to_int64()
  for i in 14..<18 {
    total = (total << 8) | data[i].to_int().to_int64()
  }
  {
    sample_rate,
    channels,
    bits_per_sample,
    total_samples: total,
    md5: data[18:34].to_owned(),
  }
}

///|
/// Parse native FLAC metadata. Audio frames are opaque and not validated.
pub fn parse(
  data : Bytes,
  max_metadata? : Int = MaxMetadata,
) -> Document raise FlacError {
  guard max_metadata >= 42 && max_metadata <= MaxMetadata else {
    raise Limit("max_metadata must be 42..16777216")
  }
  guard data.has_prefix(b"fLaC") else {
    raise Invalid(0, "missing native FLAC signature")
  }
  let r = { data, pos: 4, }
  let blocks : Array[Block] = []
  let mut comments_seen = false
  let mut seektable_seen = false
  let mut cuesheet_seen = false
  let mut icon1 = false
  let mut icon2 = false
  for ;; {
    guard blocks.length() < MaxBlocks else {
      raise Limit("too many metadata blocks")
    }
    let header = r.take(4)
    let kind = header[0].to_int() & 127
    let last = (header[0].to_int() & 128) != 0
    let size = (header[1].to_int() << 16) |
      (header[2].to_int() << 8) |
      header[3].to_int()
    guard r.pos <= max_metadata && size <= max_metadata - r.pos else {
      raise Limit("metadata budget exceeded")
    }
    guard kind != 127 else {
      raise Invalid(r.pos - 4, "forbidden block type 127")
    }
    guard !blocks.is_empty() || kind == 0 else {
      raise Invalid(4, "first block must be STREAMINFO")
    }
    let payload = r.take(size)
    match kind {
      0 => {
        guard blocks.is_empty() else {
          raise Invalid(r.pos, "duplicate STREAMINFO")
        }
        ignore(stream_info(payload))
      }
      1 =>
        for byte in payload {
          guard byte == b'\x00' else { raise Invalid(r.pos, "nonzero padding") }
        }
      2 => {
        guard size >= 4 else {
          raise Invalid(r.pos, "APPLICATION requires identifier")
        }
      }
      3 => {
        guard !seektable_seen else {
          raise Invalid(r.pos, "duplicate SEEKTABLE")
        }
        seektable_seen = true
        guard size % 18 == 0 else {
          raise Invalid(r.pos, "SEEKTABLE size must be multiple of 18")
        }
        validate_seektable(payload)
      }
      4 => {
        guard !comments_seen else {
          raise Invalid(r.pos, "duplicate VORBIS_COMMENT")
        }
        comments_seen = true
        ignore(decode_comments(payload))
      }
      6 => {
        let picture = decode_picture(payload)
        if picture.kind == 1 {
          guard !icon1 else { raise Invalid(r.pos, "duplicate type 1 icon") }
          icon1 = true
        }
        if picture.kind == 2 {
          guard !icon2 else { raise Invalid(r.pos, "duplicate type 2 icon") }
          icon2 = true
        }
      }
      5 => {
        guard !cuesheet_seen else { raise Invalid(r.pos, "duplicate CUESHEET") }
        cuesheet_seen = true
      }
      _ => ()
    }
    blocks.push({ kind, data: payload, })
    if last {
      break
    }
  }
  let offset = r.pos
  let audio = r.take(data.length() - r.pos)
  { blocks, audio, offset, }
}

///|
pub fn Document::stream_info(self : Document) -> StreamInfo raise FlacError {
  stream_info(self.blocks[0].data)
}

///|
pub fn Document::blocks(self : Document) -> Array[Block] {
  self.blocks.copy()
}

///|
pub fn Document::audio_bytes(self : Document) -> Bytes {
  self.audio
}

///|
pub fn Document::audio_offset(self : Document) -> Int {
  self.offset
}

///|
pub fn Document::comments(self : Document) -> Comments raise FlacError {
  for block in self.blocks {
    if block.kind == 4 {
      return decode_comments(block.data)
    }
  }
  { vendor: "MoonFlacTag/0.2.0", entries: [], }
}

///|
pub fn Document::pictures(self : Document) -> Array[Picture] raise FlacError {
  let result = []
  for block in self.blocks {
    if block.kind == 6 {
      result.push(decode_picture(block.data))
    }
  }
  result
}
