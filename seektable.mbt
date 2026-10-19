///|
// Compare fixed-width big-endian sample numbers without narrowing unsigned u64.
fn validate_seektable(data : Bytes) -> Unit raise FlacError {
  let placeholder = Bytes::make(8, b'\xff')
  let mut previous : Bytes? = None
  for i = 0; i < data.length(); i = i + 18 {
    let sample = data[i:i + 8].to_owned()
    if previous is Some(before) {
      guard sample > before || (sample == placeholder && before == placeholder) else {
        raise Invalid(
          i, "SEEKTABLE samples must be sorted and unique; placeholders last",
        )
      }
    }
    previous = Some(sample)
  }
}
