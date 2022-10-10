library(targets)
future::plan(future.callr::callr)
tar_option_set(packages = c("httr", "magick", "reticulate"))
purrr::walk(fs::dir_ls("R"), source)

# background removal
library(reticulate)
use_condaenv("face")
rembg <- import("rembg")
pil <- import("PIL")
new_session <- rembg$session_factory$new_session

list(
  # tar_target(
  #   files_png, {
  #     file_name <- fs::path("working", "face-png", fs::path_file(files_tif)) |>
  #       fs::path_ext_set("png")
  #     image_read(files_tif) |>
  #       image_convert(format = "png") |>
  #       image_write(file_name)
  #     file_name
  #   },
  #   pattern = map(files_tif),
  #   format = "file"
  # ),
  tarchetypes::tar_files_input(
    files_origin_from,
    fs::dir_ls(fs::path("working", "face"), regexp = "from")
  ),
  tarchetypes::tar_files_input(
    files_origin_to,
    fs::dir_ls(fs::path("working", "face"), regexp = "to")
  ),
  tarchetypes::tar_files_input(
    files_origin_novel,
    fs::dir_ls(fs::path("working", "face"), regexp = "novel")
  ),
  tar_target(
    frames,
    (seq_along(files_origin_to) %% 2 + 1) * 10
  ),
  tar_target(
    files_similar,
    morph_from_file(
      fs::path(
        "working", "face-morphed",
        sub("to", "b", fs::path_file(files_origin_to))
      ),
      files_origin_from,
      files_origin_to,
      frames
    ),
    pattern = map(files_origin_from, files_origin_to, frames),
    format = "file"
  ),
  tar_target(
    files_old,
    morph_from_file(
      fs::path(
        "working", "face-morphed",
        sub("to", "a", fs::path_file(files_origin_to))
      ),
      files_origin_from,
      files_origin_to,
      0
    ),
    pattern = map(files_origin_from, files_origin_to),
    format = "file"
  ),
  tar_target(
    files_novel,
    morph_from_file(
      fs::path(
        "working", "face-morphed",
        sub("novel", "n", fs::path_file(files_origin_novel))
      ),
      files_origin_novel,
      files_origin_to[[1]],
      0
    ),
    pattern = map(files_origin_novel),
    format = "file"
  ),
  tar_target(
    files_with_bg,
    c(files_similar, files_old, files_novel)
  ),
  tar_target(
    files_no_bg, {
      out_filename <- fs::path("working", "face-nobg", fs::path_file(files_with_bg))
      img <- pil$Image$open(files_with_bg)
      no_bg <- rembg$remove(img, session = new_session("u2net_human_seg"))
      no_bg$save(out_filename)
      out_filename
    },
    pattern = map(files_with_bg),
    format = "file"
  ),
  tar_target(
    files_stim_face,
    resize_stimuli(files_no_bg, type = "face"),
    pattern = map(files_no_bg),
    format = "file"
  ),

  tar_target(
    file_words,
    "origin/word//words.csv",
    format = "file"
  ),
  tarchetypes::tar_group_size(
    config_words,
    readr::read_csv(
      file_words,
      col_names = c("id", "ver", "word"),
      show_col_types = FALSE
    ),
    size = 1L
  ),
  tar_target(
    file_word_pic,
    generate_word_pic(config_words),
    format = "file",
    pattern = map(config_words)
  ),
  tar_target(
    files_stim_word,
    resize_stimuli(file_word_pic, type = "word"),
    pattern = map(file_word_pic),
    format = "file"
  ),

  tarchetypes::tar_files_input(
    files_origin_object,
    fs::dir_ls("origin/object", regexp = "jpg", recurse = TRUE)
  ),
  tar_target(
    rename_object, {
      file <- fs::path_ext_remove(files_origin_object)
      ver <- stringr::str_sub(file, -1)
      id <- stringr::str_sub(file, end = -2) |>
        as.factor() |>
        as.integer()
      ext <- fs::path_ext(files_origin_object)
      fs::path("origin/object-renamed", sprintf("%03d%s.%s", id, ver, ext))
    }
  ),
  tar_target(
    files_rename_object,
    fs::file_copy(files_origin_object, rename_object, overwrite = TRUE),
    pattern = map(files_origin_object, rename_object),
    format = "file"
  ),
  tar_target(
    files_stim_object,
    resize_stimuli(files_rename_object, type = "object"),
    pattern = map(files_rename_object),
    format = "file"
  ),

  tarchetypes::tar_files_input(
    files_origin_place,
    fs::dir_ls("origin/place", regexp = "jpg", recurse = TRUE)
  ),
  tar_target(
    rename_place, {
      file <- fs::path_ext_remove(files_origin_place)
      ver <- stringr::str_sub(file, -1)
      id <- stringr::str_sub(file, end = -2) |>
        as.factor() |>
        as.integer()
      ext <- fs::path_ext(files_origin_place)
      fs::path("origin/place-renamed", sprintf("%03d%s.%s", id, ver, ext))
    }
  ),
  tar_target(
    files_rename_place,
    fs::file_copy(files_origin_place, rename_place, overwrite = TRUE),
    pattern = map(files_origin_place, rename_place),
    format = "file"
  ),
  tar_target(
    files_stim_place,
    resize_stimuli(files_rename_place, type = "place"),
    pattern = map(files_rename_place),
    format = "file"
  )
)
