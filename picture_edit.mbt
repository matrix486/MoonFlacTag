///|
/// Select and reorder pictures without touching unrelated kinds or input arrays.
/// Serialization and full payload limits are checked by plan/encode_picture.
pub fn edit_pictures(
  pictures : Array[Picture],
  edits : Array[PictureEdit],
) -> Array[Picture] raise FlacError {
  let mut result = pictures.copy()
  for edit in edits {
    match edit {
      SetPicture(picture) => {
        validate_picture(picture)
        result = result.filter(p => p.kind != picture.kind)
        result.push(picture)
      }
      AddPicture(picture) => {
        validate_picture(picture)
        result.push(picture)
      }
      RemovePictureKind(kind) => {
        guard kind >= 0 && kind <= 20 else {
          raise Invalid(0, "reserved picture type")
        }
        result = result.filter(p => p.kind != kind)
      }
      ClearPictures => result = []
    }
    guard result.length() <= MaxBlocks else { raise Limit("too many pictures") }
  }
  let mut icon1 = false
  let mut icon2 = false
  for picture in result {
    validate_picture(picture)
    if picture.kind == 1 {
      guard !icon1 else { raise Invalid(0, "duplicate type 1 icon") }
      icon1 = true
    }
    if picture.kind == 2 {
      guard !icon2 else { raise Invalid(0, "duplicate type 2 icon") }
      icon2 = true
    }
  }
  result
}
