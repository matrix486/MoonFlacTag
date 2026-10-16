///|
extern "js" fn arguments() -> FixedArray[String] =
  #|() => process.argv.slice(2)

///|
extern "js" fn read_file(path : String) -> Bytes =
  #|(path) => { const fs = require('node:fs'); if (fs.statSync(path).size > 268435456) throw new Error('input exceeds 256 MiB'); return new Uint8Array(fs.readFileSync(path)); }

///|
extern "js" fn write_file(path : String, data : Bytes) -> Unit =
  #|(path, data) => require('node:fs').writeFileSync(path, data, {flag:'wx'})

///|
extern "js" fn failure(message : String) -> Unit =
  #|(message) => { console.error(message); process.exitCode = 1; }

///|
fn report(doc : @flac.Document) -> Unit raise {
  let info = doc.stream_info()
  let comments = doc.comments()
  let pictures = doc
    .pictures()
    .map(p => {
      (
        {
          "kind": p.kind.to_json(),
          "media_type": p.media_type.to_json(),
          "description": p.description.to_json(),
          "width": p.width.to_json(),
          "height": p.height.to_json(),
          "bytes": p.data.length().to_json(),
        } : Json)
    })
  let json : Json = {
    "stream": info.to_json(),
    "comments": comments.to_json(),
    "pictures": pictures.to_json(),
    "audio_offset": doc.audio_offset().to_json(),
    "audio_bytes": doc.audio_bytes().length().to_json(),
    "block_types": doc.blocks().map(b => b.kind).to_json(),
  }
  println(json.stringify())
}

///|
fn run(args : Array[String]) -> Unit raise {
  match args {
    ["inspect", input] => report(@flac.parse(read_file(input)))
    ["edit", input, output, .. ops] => {
      let edits : Array[@flac.TagEdit] = []
      let mut pictures : Array[@flac.Picture]? = None
      let mut padding : @flac.Padding = PreserveOffset
      for op in ops {
        if op == "--compact" {
          padding = Compact
        } else if op == "--remove-pictures" {
          pictures = Some([])
        } else if op.strip_prefix("--set=") is Some(field) {
          guard field.split_once("=") is Some((key, value)) else {
            fail("--set=KEY=VALUE required")
          }
          edits.push(Set(key.to_owned(), value.to_owned()))
        } else if op.strip_prefix("--add=") is Some(field) {
          guard field.split_once("=") is Some((key, value)) else {
            fail("--add=KEY=VALUE required")
          }
          edits.push(Add(key.to_owned(), value.to_owned()))
        } else if op.strip_prefix("--remove=") is Some(key) {
          edits.push(Remove(key.to_owned()))
        } else if op.strip_prefix("--cover-png=") is Some(path) {
          pictures = Some([
            {
              kind: 3,
              media_type: "image/png",
              description: "Front cover",
              width: 0U,
              height: 0U,
              depth: 0U,
              colors: 0U,
              data: read_file(path.to_owned()),
            },
          ])
        } else {
          fail("unknown option: \{op}")
        }
      }
      let doc = @flac.parse(read_file(input))
      let result = match pictures {
        Some(images) => doc.rewrite(edits, pictures=images, padding~)
        None => doc.rewrite(edits, padding~)
      }
      write_file(output, result.bytes)
      report(@flac.parse(result.bytes))
    }
    _ =>
      fail(
        "usage: inspect FILE | edit INPUT OUTPUT [--set=KEY=VALUE] [--add=KEY=VALUE] [--remove=KEY] [--cover-png=FILE] [--remove-pictures] [--compact]",
      )
  }
}

///|
fn main {
  run(Array::from_iter(arguments().iter())) catch {
    error => failure(error.to_string())
  }
}
