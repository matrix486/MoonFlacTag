# 可执行 API 示例

下面的音频后缀是 synthetic bytes，仅用于说明编辑事务，不是可解码的音频。

```mbt check
///|
test "documented editing workflow" {
  let info = b"\x00\x10\x00\x10\x00\x00\x00\x00\x00\x00\x0a\xc4\x42\xf0\x00\x00\xac\x44" +
    Bytes::make(16, b'\x00')
  let input = b"fLaC\x80\x00\x00\x22" + info + b"synthetic-audio"
  let doc = @moonflactag.parse(input)
  let result = doc.rewrite(
    [Set("TITLE", "月亮"), Add("ARTIST", "A"), Add("artist", "B")],
    padding=Compact,
  )
  let edited = @moonflactag.parse(result.bytes)
  assert_eq(edited.comments().values("ARTIST"), ["A", "B"])
  assert_eq(edited.comments().values("title"), ["月亮"])
  assert_eq(edited.audio_bytes(), doc.audio_bytes())
  assert_eq(doc.comments().entries.length(), 0)
}
```

流式宿主只需提供到最后元数据块为止的精确前缀，并按计划复制原文件音频后缀。

图片可以按类型编辑，保留其他封面；下面使用合成 payload 演示选择语义，不将其当作真实图片。

```mbt check
///|
test "documented selective artwork editing" {
  let front : @moonflactag.Picture = {
    kind: 3,
    media_type: "image/png",
    description: "front",
    width: 0U,
    height: 0U,
    depth: 0U,
    colors: 0U,
    data: b"synthetic",
  }
  let back = { ..front, kind: 4, description: "back", }
  let replacement = { ..front, description: "new", }
  let result = @moonflactag.edit_pictures([front, back], [
    SetPicture(replacement),
  ])
  assert_eq(result, [back, replacement])
}
```

```mbt check
///|
test "documented streaming prefix plan" {
  let info = b"\x00\x10\x00\x10\x00\x00\x00\x00\x00\x00\x0a\xc4\x42\xf0\x00\x00\xac\x44" +
    Bytes::make(16, b'\x00')
  let prefix = b"fLaC\x80\x00\x00\x22" + info
  let plan = @moonflactag.plan_metadata(
    prefix,
    [Set("TITLE", "stream")],
    padding=Compact,
  )
  assert_eq(plan.old_audio_offset, prefix.length())
  assert_eq(plan.metadata.length(), plan.audio_offset)
  assert_eq(@moonflactag.parse(plan.metadata).comments().values("title"), [
    "stream",
  ])
}
```
