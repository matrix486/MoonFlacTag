///|
fn make_plan(
  doc : @flac.Document,
  opts : EditOptions,
) -> @flac.RewritePlan raise {
  let pictures = if opts.pictures.is_empty() {
    None
  } else {
    Some(@flac.edit_pictures(doc.pictures(), opts.pictures))
  }
  match opts.padding {
    Some(padding) => doc.plan(opts.tags, pictures?, padding~)
    None =>
      doc.plan(opts.tags, pictures?, padding=PreserveOffset) catch {
        NoSpace(_) => doc.plan(opts.tags, pictures?, padding=Compact)
        error => raise error
      }
  }
}

///|
fn should_skip(output : String, enabled : Bool) -> Bool raise {
  if !enabled {
    return false
  }
  let state = existing_destination(output)
  if state == "file" {
    return true
  }
  check_io(state)
  false
}

///|
fn run_with_report(args : Array[String]) -> Unit raise {
  let filtered : Array[String] = []
  let mut destination : String? = None
  for arg in args {
    if arg.strip_prefix("--report=") is Some(value) {
      guard destination is None && !value.is_empty() else {
        raise CliFailure(
          "INVALID_ARGUMENT", "report", "", "use --report=FILE.json once",
        )
      }
      destination = Some(value.to_owned())
    } else {
      filtered.push(arg)
    }
  }
  if destination is Some(file) {
    check_io(prepare_report(file))
  }
  let result = run(filtered)
  if destination is Some(file) {
    guard result.strip_prefix("{") is Some(_) else {
      raise CliFailure(
        "INVALID_ARGUMENT", "report", file, "--report requires a JSON command",
      )
    }
  }
  println(result)
  if destination is Some(file) {
    check_io(save_report(file, result + "\n"))
  }
}
