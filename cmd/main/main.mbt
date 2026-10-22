///|
extern "js" fn arguments() -> FixedArray[String] =
  #|() => process.argv.slice(2)

///|
const Usage : String = "usage:\n  inspect INPUT\n  plan INPUT [OPTIONS]\n  edit INPUT OUTPUT [OPTIONS]\n  extract-cover INPUT OUTPUT [--index=N]\n  batch plan INPUT_DIR [--recursive] [OPTIONS]\n  batch edit INPUT_DIR OUTPUT_DIR [--recursive] [OPTIONS]\nOPTIONS: --set=KEY=VALUE --add=KEY=VALUE --remove=KEY --compact --padding=N\nARTWORK: --picture-kind=N --cover=PNG_OR_JPEG --append-cover=FILE --remove-picture-kind=N --remove-pictures\nLegacy --cover-png=FILE still replaces all pictures. New --cover replaces only its selected kind (default 3).\nOUTPUT must be a new path. plan never writes. --help / --version"

///|
fn[T] with_source(path : String, action : (Source) -> T raise) -> T raise {
  let source = open_source(path)
  defer close_source(source)
  check_io(source_error(source))
  action(source)
}

///|
fn read_metadata(source : Source) -> Bytes raise {
  for ;; {
    let data = source_prefix(source)
    match @flac.metadata_prefix_length(data) {
      Complete(_) => return data
      NeedMore(n) => check_io(read_more(source, n))
    }
  }
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
    .mapi((index, p) => {
      (
        {
          "index": index.to_json(),
          "kind": p.kind.to_json(),
          "media_type": p.media_type.to_json(),
          "description": p.description.to_json(),
          "width": p.width.to_json(),
          "height": p.height.to_json(),
          "depth": p.depth.to_json(),
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
fn process_source(
  input : String,
  output : String?,
  opts : EditOptions,
  create_dirs : Bool,
) -> Json raise {
  with_source(input, source => {
    let doc = @flac.parse(read_metadata(source))
    let plan = if opts.pictures.is_empty() {
      doc.plan(opts.tags, padding=opts.padding)
    } else {
      doc.plan(
        opts.tags,
        pictures=@flac.edit_pictures(doc.pictures(), opts.pictures),
        padding=opts.padding,
      )
    }
    let json = report(
      @flac.parse(plan.metadata),
      source_size(source) - doc.audio_offset().to_double(),
      doc.audio_offset(),
      output is None,
    )
    if output is Some(path) {
      if create_dirs {
        check_io(ensure_parent(path))
      }
      check_io(
        copy_output(source, path, plan.metadata, plan.old_audio_offset, true),
      )
    }
    json
  })
}

///|
fn batch(
  input : String,
  output : String?,
  ops : ArrayView[String],
) -> Unit raise {
  let opts = parse_options(ops, true)
  let scan = scan_directory(input, output.unwrap_or(""), opts.recursive)
  check_io(scan_error(scan))
  let rows : Array[Json] = []
  let mut succeeded = 0
  let mut failed = 0
  for rel in scan_files(scan) {
    let input = scan_path(scan, rel, false)
    let output = output.map(_ => scan_path(scan, rel, true))
    try {
      let result = process_source(input, output, opts, true)
      rows.push({
        "relative": rel.to_json(),
        "input": input.to_json(),
        "output": output.to_json(),
        "status": (if output is None { "planned" } else { "written" }).to_json(),
        "report": result,
      })
      succeeded += 1
    } catch {
      error => {
        rows.push({
          "relative": rel.to_json(),
          "input": input.to_json(),
          "output": output.to_json(),
          "status": "failed",
          "error": error_json(error),
        })
        failed += 1
      }
    }
  }
  let json : Json = {
    "mode": (if output is None { "plan" } else { "edit" }).to_json(),
    "total": rows.length().to_json(),
    "succeeded": succeeded.to_json(),
    "failed": failed.to_json(),
    "skipped_symlinks": scan_skipped(scan).to_json(),
    "results": rows.to_json(),
  }
  println(json.stringify())
  if failed > 0 {
    exit_failure()
  }
}

///|
fn extract(input : String, output : String, index : Int) -> Unit raise {
  with_source(input, source => {
    let pictures = @flac.parse(read_metadata(source)).pictures()
    guard pictures.get(index) is Some(picture) else {
      raise CliFailure(
        "PICTURE_NOT_FOUND", "extract", input, "picture index does not exist",
      )
    }
    check_io(copy_output(source, output, picture.data, 0, false))
    let json : Json = {
      "output": output.to_json(),
      "index": index.to_json(),
      "kind": picture.kind.to_json(),
      "media_type": picture.media_type.to_json(),
      "bytes": picture.data.length().to_json(),
    }
    println(json.stringify())
  })
}

///|
fn run(args : Array[String]) -> Unit raise {
  match args {
    ["--help"] | ["help"] => println(Usage)
    ["--version"] => println("MoonFlacTag 0.3.0")
    ["inspect", input] =>
      with_source(input, source => {
        let doc = @flac.parse(read_metadata(source))
        println(
          report(
            doc,
            source_size(source) - doc.audio_offset().to_double(),
            doc.audio_offset(),
            false,
          ).stringify(),
        )
      })
    ["plan", input, .. ops] =>
      println(
        process_source(input, None, parse_options(ops, false), false).stringify(),
      )
    ["edit", input, output, .. ops] =>
      println(
        process_source(input, Some(output), parse_options(ops, false), false).stringify(),
      )
    ["batch", "plan", input, .. ops] => batch(input, None, ops)
    ["batch", "edit", input, output, .. ops] => batch(input, Some(output), ops)
    ["extract-cover", input, output] => extract(input, output, 0)
    ["extract-cover", input, output, option] => {
      guard option.strip_prefix("--index=") is Some(value) else {
        raise CliFailure("INVALID_ARGUMENT", "options", "", Usage)
      }
      extract(input, output, decimal(value, 4095))
    }
    _ => raise CliFailure("INVALID_ARGUMENT", "options", "", Usage)
  }
}

///|
fn main {
  run(Array::from_iter(arguments().iter())) catch {
    error => emit_failure(error_json(error).stringify())
  }
}
