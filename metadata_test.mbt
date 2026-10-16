///|
fn[T] rejected(action : () -> T raise) -> Bool {
  try {
    ignore(action())
    false
  } catch {
    _ => true
  }
}

///|
fn info_bytes() -> Bytes {
  b"\x00\x10\x00\x10\x00\x00\x00\x00\x00\x00\x0a\xc4\x42\xf0\x00\x00\xac\x44" +
  Bytes::make(16, b'\x00')
}

///|
// Independent fixture framing: no production serializer is used.
fn fixture(
  extra : Array[@moonflactag.Block],
  audio? : Bytes = b"\xff\xf8synthetic-audio",
) -> Bytes {
  let blocks : Array[@moonflactag.Block] = [
    { kind: 0, data: info_bytes(), },
    ..extra,
  ]
  let bytes = b"fLaC".to_array()
  for i, block in blocks {
    let n = block.data.length()
    bytes.push(
      (block.kind + (if i == blocks.length() - 1 { 128 } else { 0 })).to_byte(),
    )
    bytes.push((n >> 16).to_byte())
    bytes.push((n >> 8).to_byte())
    bytes.push(n.to_byte())
    for byte in block.data {
      bytes.push(byte)
    }
  }
  Bytes::from_array(bytes) + audio
}

///|
fn invalid(data : Bytes) -> Unit raise {
  let result = rejected(fn() raise { @moonflactag.parse(data) })
  assert_true(result)
}

///|
test "STREAMINFO fields and exact audio boundary" {
  let doc = @moonflactag.parse(fixture([]))
  let info = doc.stream_info()
  assert_eq(info.sample_rate, 44100)
  assert_eq(info.channels, 2)
  assert_eq(info.bits_per_sample, 16)
  assert_eq(info.total_samples, 44100L)
  assert_eq(doc.audio_offset(), 42)
  assert_eq(doc.audio_bytes(), b"\xff\xf8synthetic-audio")
}

///|
test "hand encoded little endian Vorbis comment golden" {
  let golden = b"\x01\x00\x00\x00v\x02\x00\x00\x00\x08\x00\x00\x00ARTIST=A\x08\x00\x00\x00artist=B"
  let comments = @moonflactag.decode_comments(golden)
  assert_eq(comments.vendor, "v")
  assert_eq(comments.values("ArTiSt"), ["A", "B"])
  assert_eq(@moonflactag.encode_comments(comments), golden)
}

///|
test "set add remove semantics and input isolation" {
  let c = @moonflactag.encode_comments({
    vendor: "encoder",
    entries: [
      { key: "ARTIST", value: "A", },
      { key: "artist", value: "B", },
      { key: "TITLE", value: "old", },
    ],
  })
  let doc = @moonflactag.parse(fixture([{ kind: 4, data: c, }]))
  let result = doc.rewrite(
    [Set("Artist", "C"), Add("ARTIST", "D"), Remove("title")],
    padding=Compact,
  )
  let after = @moonflactag.parse(result.bytes).comments()
  assert_eq(after.values("artist"), ["C", "D"])
  assert_eq(after.values("TITLE"), [])
  assert_eq(after.vendor, "encoder")
  assert_eq(doc.comments().values("artist"), ["A", "B"])
  let exposed = doc.blocks()
  exposed.clear()
  assert_eq(doc.blocks().length(), 2)
}

///|
test "UTF8 values equals empty values and BOM preservation" {
  let c : @moonflactag.Comments = {
    vendor: "\u{feff}厂商",
    entries: [
      { key: "TITLE", value: "月亮🌙=声音", },
      { key: "EMPTY", value: "", },
    ],
  }
  assert_eq(@moonflactag.decode_comments(@moonflactag.encode_comments(c)), c)
}

///|
test "invalid comment names UTF8 counts lengths trailing framing" {
  for key in ["", "A=B", "中文", "A~", "A\n"] {
    let result = rejected(fn() raise {
      @moonflactag.encode_comments({
        vendor: "",
        entries: [{ key, value: "x", }],
      })
    })
    assert_true(result)
  }
  for
    bytes in [
      b"\xff\xff\xff\xff", b"\x00\x00\x00\x00\xff\xff\xff\xff", b"\x01\x00\x00\x00\xff\x00\x00\x00\x00",
      b"\x00\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00X", b"\x00\x00\x00\x00\x00\x00\x00\x00\x01",
    ] {
    let result = rejected(fn() raise { @moonflactag.decode_comments(bytes) })
    assert_true(result)
  }
}

///|
test "picture big endian golden and unsigned dimensions" {
  let golden = b"\x00\x00\x00\x03\x00\x00\x00\x09image/png\x00\x00\x00\x01x\xff\xff\xff\xff\x00\x00\x00\x02\x00\x00\x00\x18\x00\x00\x00\x00\x00\x00\x00\x03PNG"
  let p = @moonflactag.decode_picture(golden)
  assert_eq(p.kind, 3)
  assert_eq(p.width, 0xffffffffU)
  assert_eq(p.height, 2U)
  assert_eq(p.data, b"PNG")
  assert_eq(@moonflactag.encode_picture(p), golden)
  for n in 0..<golden.length() {
    let result = rejected(fn() raise {
      @moonflactag.decode_picture(golden[:n].to_owned())
    })
    assert_true(result)
  }
}

///|
fn cover() -> @moonflactag.Picture {
  {
    kind: 3,
    media_type: "image/png",
    description: "封面",
    width: 1U,
    height: 1U,
    depth: 24U,
    colors: 0U,
    data: b"synthetic PNG",
  }
}

///|
test "replace and remove pictures preserve tags and audio" {
  let doc = @moonflactag.parse(
    fixture([{ kind: 6, data: @moonflactag.encode_picture(cover()), }]),
  )
  let new_picture = { ..cover(), description: "new", data: b"different", }
  let changed = @moonflactag.parse(
    doc.rewrite([], pictures=[new_picture], padding=Compact).bytes,
  )
  assert_eq(changed.pictures(), [new_picture])
  let cleared = @moonflactag.parse(
    changed.rewrite([], pictures=[], padding=Compact).bytes,
  )
  assert_eq(cleared.pictures(), [])
  assert_eq(cleared.audio_bytes(), doc.audio_bytes())
  assert_eq(doc.pictures().length(), 1)
}

///|
test "picture validation duplicate icons and linked images remain opaque" {
  let icon = { ..cover(), kind: 2, }
  let doc = @moonflactag.parse(fixture([]))
  assert_true(
    rejected(fn() raise {
      doc.rewrite([], pictures=[icon, icon], padding=Compact)
    }),
  )
  invalid(
    fixture([
      { kind: 6, data: @moonflactag.encode_picture(icon), },
      { kind: 6, data: @moonflactag.encode_picture(icon), },
    ]),
  )
  for
    p in [
      { ..cover(), kind: 21, },
      { ..cover(), media_type: "图片", },
      { ..cover(), kind: 1, },
    ] {
    assert_true(rejected(fn() raise { @moonflactag.encode_picture(p) }))
  }
  let linked = {
    ..cover(),
    media_type: "-->",
    data: b"https://example.invalid/image",
  }
  assert_eq(
    @moonflactag.decode_picture(@moonflactag.encode_picture(linked)),
    linked,
  )
}

///|
test "preserve offset uses padding and reports unchanged boundary" {
  let doc = @moonflactag.parse(
    fixture([{ kind: 1, data: Bytes::make(128, b'\x00'), }]),
  )
  let r = doc.rewrite([Set("TITLE", "new")])
  assert_eq(r.audio_offset, doc.audio_offset())
  assert_eq(r.old_audio_offset, doc.audio_offset())
  assert_eq(@moonflactag.parse(r.bytes).audio_bytes(), doc.audio_bytes())
  assert_eq(@moonflactag.parse(r.bytes).comments().values("title"), ["new"])
}

///|
test "padding budget too small zero and unrepresentable slack" {
  let base = @moonflactag.parse(fixture([]))
  assert_true(rejected(fn() raise { base.rewrite([Set("TITLE", "long")]) }))
  assert_eq(base.rewrite([]).audio_offset, 42)
  // Compact added comments cost: header4 + vendor4+17 + count4 + entry4+3 = 36.
  let compact = base.rewrite([Set("A", "B")], padding=Compact)
  let cost = compact.audio_offset - 42
  for slack in 1..<=3 {
    let padded = @moonflactag.parse(
      fixture([{ kind: 1, data: Bytes::make(cost + slack - 4, b'\x00'), }]),
    )
    assert_true(rejected(fn() raise { padded.rewrite([Set("A", "B")]) }))
  }
}

///|
test "exact padding compact and multiple padding coalescing" {
  let d = @moonflactag.parse(
    fixture([{ kind: 1, data: b"", }, { kind: 1, data: b"\x00\x00", }]),
  )
  let exact = @moonflactag.parse(d.rewrite([], padding=Exact(17)).bytes)
  assert_eq(exact.audio_offset(), 42 + 4 + 17)
  assert_eq(exact.blocks().filter(b => b.kind == 1).length(), 1)
  assert_eq(
    @moonflactag.parse(d.rewrite([], padding=Compact).bytes).audio_offset(),
    42,
  )
  assert_true(rejected(fn() raise { d.rewrite([], padding=Exact(-1)) }))
  assert_true(rejected(fn() raise { d.rewrite([], padding=Exact(16777216)) }))
}

///|
test "opaque unknown application cuesheet seektable blocks survive" {
  let extras : Array[@moonflactag.Block] = [
    { kind: 125, data: b"opaque", },
    { kind: 2, data: b"TESTpayload", },
    { kind: 5, data: b"opaque-cuesheet", },
    { kind: 3, data: b"", },
  ]
  let d = @moonflactag.parse(fixture(extras))
  let after = @moonflactag.parse(
    d.rewrite([Add("TITLE", "x")], padding=Compact).bytes,
  )
  assert_eq(after.blocks().filter(b => b.kind != 0 && b.kind != 4), extras)
  assert_eq(after.audio_bytes(), d.audio_bytes())
}

///|
test "all metadata truncations reject and header invariants" {
  let c = @moonflactag.encode_comments({
    vendor: "x",
    entries: [{ key: "A", value: "B", }],
  })
  let full = fixture([
    { kind: 4, data: c, },
    { kind: 6, data: @moonflactag.encode_picture(cover()), },
  ])
  let boundary = @moonflactag.parse(full).audio_offset()
  for n in 0..<boundary {
    invalid(full[:n].to_owned())
  }
  invalid(b"fLaC\xff\x00\x00\x00")
  invalid(b"fLaC\x81\x00\x00\x00")
  invalid(fixture([{ kind: 0, data: info_bytes(), }]))
  invalid(fixture([{ kind: 4, data: c, }, { kind: 4, data: c, }]))
  invalid(fixture([{ kind: 1, data: b"\x01", }]))
  invalid(fixture([{ kind: 2, data: b"ABC", }]))
  invalid(fixture([{ kind: 3, data: b"x", }]))
  invalid(b"fLaC\x80\xff\xff\xff")
}

///|
test "metadata budget and block count are enforced before work" {
  let data = fixture([{ kind: 1, data: Bytes::make(100, b'\x00'), }])
  assert_true(
    rejected(fn() raise { @moonflactag.parse(data, max_metadata=42) }),
  )
  assert_true(
    rejected(fn() raise { @moonflactag.parse(data, max_metadata=-1) }),
  )
  let blocks : Array[@moonflactag.Block] = Array::make(4096, {
    kind: 7,
    data: b"",
  })
  invalid(fixture(blocks))
}

///|
test "non target metadata and audio byte identity on no-op" {
  let input = fixture([{ kind: 125, data: b"abc", }])
  assert_eq(@moonflactag.parse(input).rewrite([]).bytes, input)
  assert_eq(@moonflactag.parse(input).rewrite([], padding=Compact).bytes, input)
}
