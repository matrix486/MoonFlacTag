///|
fn png_header() -> Bytes {
  b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x02\x08\x02\x00\x00\x00\x00\x00\x00\x00"
}

///|
fn jpeg_header() -> Bytes {
  b"\xff\xd8\xff\xe0\x00\x04ab\xff\xc0\x00\x11\x08\x00\x02\x00\x03\x03\x01\x11\x00\x02\x11\x00\x03\x11\x00\xff\xd9"
}

///|
test "PNG and JPEG cover headers preserve original payload" {
  let png = @moonflactag.picture_from_image(png_header(), description="front")
  assert_eq(
    (png.media_type, png.width, png.height, png.depth),
    ("image/png", 1U, 2U, 24U),
  )
  assert_eq(png.data, png_header())
  let jpeg = @moonflactag.picture_from_image(
    jpeg_header(),
    kind=4,
    description="back",
  )
  assert_eq(
    (jpeg.kind, jpeg.media_type, jpeg.width, jpeg.height, jpeg.depth),
    (4, "image/jpeg", 3U, 2U, 24U),
  )
  assert_eq(
    @moonflactag.decode_picture(@moonflactag.encode_picture(jpeg)),
    jpeg,
  )
}

///|
test "header truncations bad markers PNG methods and SOF lengths reject" {
  for raw in [png_header(), jpeg_header()] {
    let minimum = if raw.has_prefix(b"\x89PNG") { 33 } else { raw.length() - 2 }
    for n in 0..<minimum {
      assert_true(
        rejected(fn() raise {
          @moonflactag.picture_from_image(raw[:n].to_owned())
        }),
      )
    }
  }
  for
    (index, value) in [
      (16, b'\x80'),
      (24, b'\x07'),
      (25, b'\x05'),
      (26, b'\x01'),
      (27, b'\x01'),
      (28, b'\x02'),
    ] {
    let data = png_header().to_array()
    data[index] = value
    assert_true(
      rejected(fn() raise {
        @moonflactag.picture_from_image(Bytes::from_array(data))
      }),
    )
  }
  for
    bad in [
      b"\xff\xd8\xff\xd9", b"\xff\xd8\xff\xe0\xff\xff", b"\xff\xd8\x00", b"\xff\xd8\xff\xda",
      b"\xff\xd8\xff\xc0\x00\x02",
    ] {
    assert_true(rejected(fn() raise { @moonflactag.picture_from_image(bad) }))
  }
}

///|
test "selective cover replace preserves back cover and duplicate front edits are ordered" {
  let front = @moonflactag.picture_from_image(png_header())
  let back = @moonflactag.picture_from_image(jpeg_header(), kind=4)
  let new_front = { ..front, description: "new front", }
  let original = [front, back]
  let changed = @moonflactag.edit_pictures(original, [
    SetPicture(new_front),
    AddPicture(front),
  ])
  assert_eq(changed, [back, new_front, front])
  assert_eq(original, [front, back])
  let removed = @moonflactag.edit_pictures(changed, [RemovePictureKind(3)])
  assert_eq(removed, [back])
  assert_eq(
    @moonflactag.edit_pictures(changed, [ClearPictures, AddPicture(front)]),
    [front],
  )
  assert_true(
    rejected(fn() raise {
      @moonflactag.edit_pictures(original, [RemovePictureKind(21)])
    }),
  )
}

///|
test "artwork edits integrate with rewrite while retaining compressed suffix" {
  let front = @moonflactag.picture_from_image(png_header())
  let back = @moonflactag.picture_from_image(jpeg_header(), kind=4)
  let doc = @moonflactag.parse(
    fixture([{ kind: 6, data: @moonflactag.encode_picture(back), }]),
  )
  let pics = @moonflactag.edit_pictures(doc.pictures(), [SetPicture(front)])
  let after = @moonflactag.parse(
    doc.rewrite([], pictures=pics, padding=Compact).bytes,
  )
  assert_eq(after.pictures(), [back, front])
  assert_eq(after.audio_bytes(), doc.audio_bytes())
}

///|
test "incremental metadata requirements are exact and exclude audio" {
  let source = fixture([
    { kind: 125, data: b"application-like", },
    { kind: 1, data: Bytes::make(128, b'\x00'), },
  ])
  let boundary = @moonflactag.parse(source).audio_offset()
  for n in 0..<boundary {
    match @moonflactag.metadata_prefix_length(source[:n].to_owned()) {
      NeedMore(required) => assert_true(required > n && required <= boundary)
      Complete(_) => fail("prefix completed before metadata boundary")
    }
  }
  assert_eq(@moonflactag.metadata_prefix_length(source), Complete(boundary))
  let prefix = source[:boundary].to_owned()
  assert_eq(
    @moonflactag.plan_metadata(prefix, [], padding=Compact).old_audio_offset,
    boundary,
  )
}

///|
test "prefix framer rejects excessive lengths forbidden kinds and block floods" {
  for
    bad in [
      b"nope", b"fLaC\xff\x00\x00\x00", b"fLaC\x81\x00\x00\x00", b"fLaC\x80\xff\xff\xff",
    ] {
    assert_true(
      rejected(fn() raise { @moonflactag.metadata_prefix_length(bad) }),
    )
  }
  let flood = fixture(Array::make(4096, { kind: 7, data: b"", }))
  assert_true(
    rejected(fn() raise { @moonflactag.metadata_prefix_length(flood) }),
  )
}

///|
test "deterministic malformed corpus returns typed errors or a stable valid plan" {
  let seed = fixture([
    {
      kind: 4,
      data: @moonflactag.encode_comments({
        vendor: "fixture",
        entries: [{ key: "TITLE", value: "声音🌙", }],
      }),
    },
  ])
  for n in 0..<512 {
    let data = seed.to_array()
    let index = (n * 37 + 11) % data.length()
    data[index] = ((n * 73 + 19) % 256).to_byte()
    try {
      let doc = @moonflactag.parse(Bytes::from_array(data))
      let bytes = doc.rewrite([], padding=Compact).bytes
      assert_eq(@moonflactag.parse(bytes).audio_bytes(), doc.audio_bytes())
    } catch {
      @moonflactag.Invalid(_, _) | @moonflactag.Limit(_) => ()
      error => raise error
    }
  }
}
