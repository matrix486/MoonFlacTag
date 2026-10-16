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
