///|
priv suberror CliError {
  CliFailure(String, String, String, String)
} derive(Debug)

///|
priv struct HostError {
  code : String
  operation : String
  path : String
  message : String
} derive(FromJson)

///|
fn check_io(raw : String) -> Unit raise {
  if raw.is_empty() {
    return
  }
  let detail : HostError = @json.from_json(@json.parse(raw))
  raise CliFailure(detail.code, detail.operation, detail.path, detail.message)
}

///|
fn diagnostic(
  code : String,
  message : String,
  operation : String,
  path : String,
  offset : Int?,
) -> Json {
  {
    "code": code.to_json(),
    "error": message.to_json(),
    "message": message.to_json(),
    "operation": operation.to_json(),
    "path": path.to_json(),
    "offset": offset.to_json(),
  }
}

///|
fn error_json(error : Error) -> Json {
  match error {
    CliFailure(code, op, path, message) =>
      diagnostic(code, message, op, path, None)
    @flac.Invalid(offset, message) =>
      diagnostic("FLAC_INVALID", message, "metadata", "", Some(offset))
    @flac.Limit(message) =>
      diagnostic("METADATA_LIMIT", message, "metadata", "", None)
    @flac.NoSpace(slack) =>
      diagnostic(
        "PADDING_NO_SPACE",
        "cannot preserve offset; remaining bytes=\{slack}",
        "plan",
        "",
        None,
      )
    _ => diagnostic("INTERNAL_ERROR", error.to_string(), "internal", "", None)
  }
}

///|
extern "js" fn emit_failure(json : String) -> Unit =
  #|(json) => { console.error(json); process.exitCode = 1; }
