///|
/// All parse/edit failures are recoverable; offsets are local to the parsed block.
pub(all) suberror FlacError {
  Invalid(Int, String)
  Limit(String)
  NoSpace(Int)
} derive(Debug)

///|
pub(all) struct Block {
  kind : Int
  data : Bytes
} derive(Debug, Eq)

///|
pub(all) struct StreamInfo {
  sample_rate : Int
  channels : Int
  bits_per_sample : Int
  total_samples : Int64
  md5 : Bytes
} derive(Debug, Eq, ToJson)

///|
pub(all) struct Comment {
  key : String
  value : String
} derive(Debug, Eq, ToJson)

///|
pub(all) struct Comments {
  vendor : String
  entries : Array[Comment]
} derive(Debug, Eq, ToJson)

///|
pub(all) struct Picture {
  kind : Int
  media_type : String
  description : String
  width : UInt
  height : UInt
  depth : UInt
  colors : UInt
  data : Bytes
} derive(Debug, Eq)

///|
/// Set replaces all case-insensitive occurrences; Add appends; Remove removes all.
pub(all) enum TagEdit {
  Set(String, String)
  Add(String, String)
  Remove(String)
} derive(Debug, Eq)

///|
pub(all) enum Padding {
  Compact
  Exact(Int)
  PreserveOffset
} derive(Debug, Eq)

///|
/// Parsed documents own private block arrays. Accessors return fresh arrays.
pub struct Document {
  priv blocks : Array[Block]
  priv audio : Bytes
  priv offset : Int
} derive(Debug)

///|
pub(all) struct RewriteResult {
  bytes : Bytes
  old_audio_offset : Int
  audio_offset : Int
} derive(Debug)

///|
/// The replacement prefix only; copy the source suffix from old_audio_offset.
/// This value does not contain audio bytes and is suitable for streaming hosts.
pub(all) struct RewritePlan {
  metadata : Bytes
  old_audio_offset : Int
  audio_offset : Int
} derive(Debug)

///|
/// Ordered artwork edits; SetPicture replaces its kind while preserving other kinds.
pub(all) enum PictureEdit {
  SetPicture(Picture)
  AddPicture(Picture)
  RemovePictureKind(Int)
  ClearPictures
} derive(Debug, Eq)

///|
/// Exact byte requirement for incremental metadata prefix readers.
pub(all) enum PrefixStatus {
  NeedMore(Int)
  Complete(Int)
} derive(Debug, Eq)
