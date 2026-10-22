///|
priv struct EditOptions {
  tags : Array[@flac.TagEdit]
  pictures : Array[@flac.PictureEdit]
  padding : @flac.Padding?
  recursive : Bool
  skip_existing : Bool
  progress : Bool
}

///|
fn decimal(value : StringView, max : Int) -> Int raise CliError {
  guard !value.is_empty() else {
    raise CliFailure(
      "INVALID_ARGUMENT", "options", "", "expected decimal digits",
    )
  }
  let mut result = 0
  for c in value {
    guard c >= '0' && c <= '9' else {
      raise CliFailure(
        "INVALID_ARGUMENT", "options", "", "expected decimal digits",
      )
    }
    let digit = c.to_int() - 48
    guard result <= (max - digit) / 10 && digit <= max else {
      raise CliFailure(
        "INVALID_ARGUMENT",
        "options",
        "",
        "number exceeds allowed maximum \{max}",
      )
    }
    result = result * 10 + digit
  }
  result
}

///|
fn load_picture(path : String, kind : Int) -> @flac.Picture raise {
  with_source(path, source => {
    guard source_size(source) <= 16777215.0 else {
      raise CliFailure(
        "IMAGE_LIMIT", "read", path, "cover exceeds metadata block limit",
      )
    }
    check_io(read_more(source, source_size(source).to_int()))
    @flac.picture_from_image(source_prefix(source), kind~, description="Cover")
  })
}

///|
fn parse_options(
  ops : ArrayView[String],
  allow_recursive : Bool,
  allow_skip? : Bool = false,
) -> EditOptions raise {
  let tags : Array[@flac.TagEdit] = []
  let pictures : Array[@flac.PictureEdit] = []
  let mut padding : @flac.Padding? = None
  let mut kind = 3
  let mut recursive = false
  let mut skip_existing = false
  let mut progress = false
  for op in ops {
    if op == "--compact" {
      padding = Some(Compact)
    } else if op == "--preserve-offset" {
      padding = Some(PreserveOffset)
    } else if op == "--auto-padding" {
      padding = None
    } else if op == "--skip-existing" && allow_skip {
      skip_existing = true
    } else if op == "--progress" && allow_recursive {
      progress = true
    } else if op == "--recursive" && allow_recursive {
      recursive = true
    } else if op.strip_prefix("--padding=") is Some(value) {
      padding = Some(Exact(decimal(value, 16777215)))
    } else if op.strip_prefix("--picture-kind=") is Some(value) {
      kind = decimal(value, 20)
    } else if op == "--remove-pictures" {
      pictures.push(ClearPictures)
    } else if op.strip_prefix("--remove-picture-kind=") is Some(value) {
      pictures.push(RemovePictureKind(decimal(value, 20)))
    } else if op.strip_prefix("--set=") is Some(field) {
      guard field.split_once("=") is Some((key, value)) else {
        raise CliFailure(
          "INVALID_ARGUMENT", "options", "", "--set=KEY=VALUE required",
        )
      }
      tags.push(Set(key.to_owned(), value.to_owned()))
    } else if op.strip_prefix("--add=") is Some(field) {
      guard field.split_once("=") is Some((key, value)) else {
        raise CliFailure(
          "INVALID_ARGUMENT", "options", "", "--add=KEY=VALUE required",
        )
      }
      tags.push(Add(key.to_owned(), value.to_owned()))
    } else if op.strip_prefix("--remove=") is Some(key) {
      tags.push(Remove(key.to_owned()))
    } else if op.strip_prefix("--cover=") is Some(path) {
      pictures.push(SetPicture(load_picture(path.to_owned(), kind)))
    } else if op.strip_prefix("--append-cover=") is Some(path) {
      pictures.push(AddPicture(load_picture(path.to_owned(), kind)))
    } else if op.strip_prefix("--cover-png=") is Some(path) {
      let picture = load_picture(path.to_owned(), 3)
      guard picture.media_type == "image/png" else {
        raise CliFailure(
          "INVALID_ARGUMENT",
          "options",
          path.to_owned(),
          "--cover-png requires PNG",
        )
      }
      pictures.push(ClearPictures)
      pictures.push(AddPicture(picture))
    } else {
      raise CliFailure(
        "INVALID_ARGUMENT",
        "options",
        "",
        "unknown option: \{op}",
      )
    }
  }
  { tags, pictures, padding, recursive, skip_existing, progress, }
}
