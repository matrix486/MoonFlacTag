///|
/// Plan replacement metadata without copying the audio suffix.
/// Omitted pictures preserves existing pictures; [] removes all.
/// PreserveOffset fails if the remaining budget is negative or 1..3 bytes.
pub fn Document::plan(
  self : Document,
  edits : Array[TagEdit],
  pictures? : Array[Picture],
  padding? : Padding = PreserveOffset,
) -> RewritePlan raise FlacError {
  let blocks : Array[Block] = []
  let new_comments = if edits.is_empty() {
    None
  } else {
    Some(encode_comments(edit_comments(self.comments(), edits)))
  }
  let mut comment_written = false
  for block in self.blocks {
    if block.kind == 1 {
      continue
    }
    if block.kind == 6 && pictures is Some(_) {
      continue
    }
    if block.kind == 4 {
      if new_comments is Some(data) {
        blocks.push({ kind: 4, data, })
        comment_written = true
        continue
      }
    }
    blocks.push(block)
  }
  if !comment_written && new_comments is Some(data) {
    blocks.push({ kind: 4, data, })
  }
  let mut size = 4
  for block in blocks {
    guard block.data.length() <= MaxMetadata - size - 4 else {
      raise Limit("rewritten metadata exceeds budget")
    }
    size += 4 + block.data.length()
  }
  if pictures is Some(images) {
    guard images.length() <= MaxBlocks - blocks.length() else {
      raise Limit("too many pictures")
    }
    let mut icon1 = false
    let mut icon2 = false
    for picture in images {
      if picture.kind == 1 {
        guard !icon1 else { raise Invalid(0, "duplicate type 1 icon") }
        icon1 = true
      }
      if picture.kind == 2 {
        guard !icon2 else { raise Invalid(0, "duplicate type 2 icon") }
        icon2 = true
      }
      let data = encode_picture(picture)
      guard data.length() <= MaxMetadata - size - 4 else {
        raise Limit("rewritten metadata exceeds budget")
      }
      size += 4 + data.length()
      blocks.push({ kind: 6, data, })
    }
  }
  let pad = match padding {
    Compact => None
    Exact(n) => {
      guard n >= 0 && n <= MaxBlock else {
        raise Limit("invalid padding length")
      }
      Some(n)
    }
    PreserveOffset => {
      let slack = self.offset - size
      if slack == 0 {
        None
      } else {
        guard slack >= 4 else { raise NoSpace(slack) }
        Some(slack - 4)
      }
    }
  }
  if pad is Some(n) {
    guard n <= MaxMetadata - size - 4 else {
      raise Limit("padding exceeds metadata budget")
    }
    blocks.push({ kind: 1, data: Bytes::make(n, b'\x00'), })
    size += n + 4
  }
  guard blocks.length() <= MaxBlocks else {
    raise Limit("too many rewritten blocks")
  }
  let out = @buffer.Buffer()
  out.write_bytes(b"fLaC")
  for i, block in blocks {
    let n = block.data.length()
    out.write_byte(
      (block.kind | (if i == blocks.length() - 1 { 128 } else { 0 })).to_byte(),
    )
    out.write_byte((n >> 16).to_byte())
    out.write_byte((n >> 8).to_byte())
    out.write_byte(n.to_byte())
    out.write_bytes(block.data)
  }
  {
    metadata: out.to_bytes(),
    old_audio_offset: self.offset,
    audio_offset: size,
  }
}

///|
/// Build an in-memory file. Streaming hosts should use plan() instead.
pub fn Document::rewrite(
  self : Document,
  edits : Array[TagEdit],
  pictures? : Array[Picture],
  padding? : Padding = PreserveOffset,
) -> RewriteResult raise FlacError {
  let plan = self.plan(edits, pictures?, padding~)
  {
    bytes: plan.metadata + self.audio,
    old_audio_offset: plan.old_audio_offset,
    audio_offset: plan.audio_offset,
  }
}

///|
/// Plan from an exact metadata prefix, rejecting accidental audio/trailing data.
pub fn plan_metadata(
  prefix : Bytes,
  edits : Array[TagEdit],
  pictures? : Array[Picture],
  padding? : Padding = PreserveOffset,
) -> RewritePlan raise FlacError {
  let doc = parse(prefix)
  guard doc.audio.is_empty() else {
    raise Invalid(doc.offset, "plan_metadata requires an exact metadata prefix")
  }
  doc.plan(edits, pictures?, padding~)
}
