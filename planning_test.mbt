///|
test "metadata-only plan equals full rewrite without copying audio" {
  let source = fixture([
    { kind: 1, data: Bytes::make(128, b'\x00'), },
    { kind: 125, data: b"opaque", },
  ])
  let doc = @moonflactag.parse(source)
  let prefix = source[:doc.audio_offset()].to_owned()
  let edits : Array[@moonflactag.TagEdit] = [Set("TITLE", "preview")]
  let plan = @moonflactag.plan_metadata(prefix, edits)
  assert_eq(plan.metadata.length(), plan.audio_offset)
  assert_eq(plan.old_audio_offset, doc.audio_offset())
  assert_eq(plan.metadata + doc.audio_bytes(), doc.rewrite(edits).bytes)
  assert_eq(@moonflactag.parse(plan.metadata).audio_bytes(), b"")
  assert_true(
    rejected(fn() raise { @moonflactag.plan_metadata(source, edits) }),
  )
  let replaced = @moonflactag.plan_metadata(
    prefix,
    [],
    pictures=[cover()],
    padding=Compact,
  )
  assert_eq(@moonflactag.parse(replaced.metadata).pictures(), [cover()])
}

///|
test "deterministic edit matrix preserves unknown blocks audio and plan boundaries" {
  for n in 0..<80 {
    let audio = Bytes::make(n * 13, (n % 256).to_byte())
    let unknown : @moonflactag.Block = {
      kind: 126,
      data: Bytes::make(n, b'\xab'),
    }
    let source = fixture(
      [unknown, { kind: 1, data: Bytes::make(128, b'\x00'), }],
      audio~,
    )
    let doc = @moonflactag.parse(source)
    let edits : Array[@moonflactag.TagEdit] = [
      Add("artist", "one"),
      Add("ARTIST", "two"),
      Set("TITLE", "声音\{n}🌙"),
      Remove("absent"),
    ]
    let padding : @moonflactag.Padding = if n % 2 == 0 {
      PreserveOffset
    } else {
      Exact(n)
    }
    let plan = doc.plan(edits, padding~)
    let result = doc.rewrite(edits, padding~)
    let after = @moonflactag.parse(result.bytes)
    assert_eq(result.bytes, plan.metadata + audio)
    assert_eq(after.audio_bytes(), audio)
    assert_eq(after.audio_offset(), plan.audio_offset)
    assert_eq(after.comments().values("Artist"), ["one", "two"])
    assert_true(after.blocks().contains(unknown))
    assert_eq(doc.comments().entries.length(), 0)
    if n % 2 == 0 {
      assert_eq(after.audio_offset(), doc.audio_offset())
    }
  }
}

///|
test "seektable unsigned ordering placeholders and singleton blocks" {
  let zero = Bytes::make(18, b'\x00')
  let high = b"\x80\x00\x00\x00\x00\x00\x00\x00" + Bytes::make(10, b'\x00')
  let placeholder = Bytes::make(8, b'\xff') + Bytes::make(10, b'\x00')
  let table = zero + high + placeholder + placeholder
  let doc = @moonflactag.parse(fixture([{ kind: 3, data: table, }]))
  assert_eq(doc.blocks()[1].data, table)
  for invalid_table in [zero + zero, high + zero, placeholder + high] {
    invalid(fixture([{ kind: 3, data: invalid_table, }]))
  }
  invalid(fixture([{ kind: 3, data: b"", }, { kind: 3, data: b"", }]))
  invalid(
    fixture([{ kind: 5, data: b"opaque", }, { kind: 5, data: b"opaque", }]),
  )
}

///|
test "36-bit sample count retains upper bits" {
  let data = info_bytes().to_array()
  for i in 13..<18 {
    data[i] = b'\xff'
  }
  let input = b"fLaC\x80\x00\x00\x22" + Bytes::from_array(data)
  assert_eq(@moonflactag.parse(input).stream_info().total_samples, 68719476735L)
}

///|
test "24-bit payload limits and rewritten block count cannot overflow" {
  let too_large = Bytes::make(16777216, b'\x00')
  assert_true(rejected(fn() raise { @moonflactag.decode_picture(too_large) }))
  assert_true(
    rejected(fn() raise {
      @moonflactag.encode_picture({ ..cover(), data: too_large, })
    }),
  )
  let doc = @moonflactag.parse(fixture([]))
  assert_true(
    rejected(fn() raise {
      doc.plan([], pictures=Array::make(4096, cover()), padding=Compact)
    }),
  )
  let full = @moonflactag.parse(
    fixture(Array::make(4095, { kind: 7, data: b"", })),
  )
  assert_true(
    rejected(fn() raise { full.plan([Add("A", "B")], padding=Compact) }),
  )
}

///|
test "invalid UTF8 sequences never become replacement characters" {
  for
    bad in [
      b"\xc0\x80", b"\xed\xa0\x80", b"\xf4\x90\x80\x80", b"\x80", b"\xe2\x82",
    ] {
    let prefix = [bad.length().to_byte(), b'\x00', b'\x00', b'\x00']
    let data = Bytes::from_array(prefix) + bad + b"\x00\x00\x00\x00"
    assert_true(rejected(fn() raise { @moonflactag.decode_comments(data) }))
  }
}
