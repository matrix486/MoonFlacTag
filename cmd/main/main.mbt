///|
extern "js" fn arguments() -> FixedArray[String] =
  #|() => process.argv.slice(2)

///|
extern "js" fn failure(message : String) -> Unit =
  #|(message) => { console.error(JSON.stringify({error:message})); process.exitCode = 1; }

///|
const Usage : String = "usage: inspect INPUT | plan INPUT [OPTIONS] | edit INPUT OUTPUT [OPTIONS]\nOPTIONS: --set=KEY=VALUE --add=KEY=VALUE --remove=KEY --cover-png=FILE --remove-pictures --compact --padding=N\nOUTPUT must be a new path. plan performs no writes. --help / --version"

///|
fn[T] with_source(path : String, action : (Source) -> T raise) -> T raise {
  let source = open_source(path)
  defer close_source(source)
  let error = source_error(source)
  if !error.is_empty() {
    fail("read: \{error}")
  }
  action(source)
}

///|
fn report(
  doc : @flac.Document,
  audio_size : Double,
  old_offset : Int,
  preview : Bool,
) -> Json raise {
  let info = doc.stream_info()
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
  {
    "stream": {
      "sample_rate": info.sample_rate.to_json(),
      "channels": info.channels.to_json(),
      "bits_per_sample": info.bits_per_sample.to_json(),
      "total_samples": info.total_samples.to_json(),
      "md5": @hex.encode(info.md5).to_json(),
    },
    "comments": doc.comments().to_json(),
    "pictures": pictures.to_json(),
    "audio_offset": doc.audio_offset().to_json(),
    "old_audio_offset": old_offset.to_json(),
    "metadata_delta": (doc.audio_offset() - old_offset).to_json(),
    "audio_bytes": audio_size.to_json(),
    "output_bytes": (audio_size + doc.audio_offset().to_double()).to_json(),
    "block_types": doc.blocks().map(b => b.kind).to_json(),
    "preview": preview.to_json(),
  }
}

///|
fn padding_count(value : StringView) -> Int raise {
  guard !value.is_empty() else { fail("--padding requires 0..16777215") }
  let mut result = 0
  for c in value {
    guard c >= '0' && c <= '9' else {
      fail("--padding requires decimal digits")
    }
    let digit = c.to_int() - 48
    guard result <= (16777215 - digit) / 10 else {
      fail("--padding exceeds 16777215")
    }
    result = result * 10 + digit
  }
  result
}

///|
fn edit_source(
  input : String,
  output : String?,
  ops : ArrayView[String],
) -> Unit raise {
  let edits : Array[@flac.TagEdit] = []
  let mut pictures : Array[@flac.Picture]? = None
  let mut padding : @flac.Padding = PreserveOffset
  for op in ops {
    if op == "--compact" {
      padding = Compact
    } else if op == "--remove-pictures" {
      pictures = Some([])
    } else if op.strip_prefix("--padding=") is Some(value) {
      padding = Exact(padding_count(value))
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
      let data = with_source(path.to_owned(), source => {
        guard source_size(source) <= 16777215.0 else {
          fail("cover exceeds metadata block limit")
        }
        let data = source_prefix(source)
        guard data.has_prefix(b"\x89PNG\r\n\x1a\n") else {
          fail("--cover-png requires a PNG signature")
        }
        data
      })
      pictures = Some([
        {
          kind: 3,
          media_type: "image/png",
          description: "Front cover",
          width: 0U,
          height: 0U,
          depth: 0U,
          colors: 0U,
          data,
        },
      ])
    } else {
      fail("unknown option: \{op}")
    }
  }
  with_source(input, source => {
    let doc = @flac.parse(source_prefix(source))
    let plan = doc.plan(edits, pictures?, padding~)
    let json = report(
      @flac.parse(plan.metadata),
      source_size(source) - doc.audio_offset().to_double(),
      doc.audio_offset(),
      output is None,
    )
    if output is Some(path) {
      let error = copy_output(
        source,
        path,
        plan.metadata,
        plan.old_audio_offset,
      )
      if !error.is_empty() {
        fail("write: \{error}")
      }
    }
    println(json.stringify())
  })
}

///|
fn run(args : Array[String]) -> Unit raise {
  match args {
    ["--help"] | ["help"] => println(Usage)
    ["--version"] => println("MoonFlacTag 0.2.0")
    ["inspect", input] =>
      with_source(input, source => {
        let doc = @flac.parse(source_prefix(source))
        println(
          report(
            doc,
            source_size(source) - doc.audio_offset().to_double(),
            doc.audio_offset(),
            false,
          ).stringify(),
        )
      })
    ["plan", input, .. ops] => edit_source(input, None, ops)
    ["edit", input, output, .. ops] => edit_source(input, Some(output), ops)
    _ => fail(Usage)
  }
}

///|
fn main {
  run(Array::from_iter(arguments().iter())) catch {
    error => failure(error.to_string())
  }
}
