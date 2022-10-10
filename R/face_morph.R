# configuration for morphing
api_url <- "https://api.facemorph.me/"
encode_face <- function(file) {
  ep_enc <- "api/encodeimage"
  response <- POST(
    fs::path(api_url, ep_enc),
    body = list(
      tryalign = TRUE,
      usrimg = upload_file(file)
    ),
    encode = "multipart"
  )
  guid <- content(response)$guid
  return(guid)
}
morph_frame_from_guid <- function(from, to, frame, total_frames = 100){
  ep_frame <- "api/morphframe"
  response <- GET(
    fs::path(api_url, ep_frame),
    query = list(
      from_guid = from,
      to_guid = to,
      num_frames = total_frames,
      frame_num = frame,
      linear = TRUE
    )
  )
  return(response$content)
}
morph_from_file <- function(output, from, to, frame, total_frames = 100) {
  guid_from <- encode_face(from)
  guid_to <- encode_face(to)
  img <- morph_frame_from_guid(guid_from, guid_to, frame, total_frames)
  writeBin(img, output)
  output
}
