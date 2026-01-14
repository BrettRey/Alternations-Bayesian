#!/usr/bin/env Rscript

# Download and extract the Open ANC (GrAF) archive.

suppressPackageStartupMessages({
  library(yaml)
})

cfg <- yaml::read_yaml("analysis/config.yml")
raw_dir <- cfg$paths$raw_oanc_dir
url <- cfg$oanc$download_url
archive_name <- cfg$oanc$archive_name
archive_path <- file.path(raw_dir, archive_name)
extract_dir <- file.path(raw_dir, "OANC-GrAF")

if (!dir.exists(raw_dir)) {
  dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
}

if (dir.exists(extract_dir)) {
  message("Already extracted: ", extract_dir)
  quit(status = 0)
}

if (!file.exists(archive_path)) {
  message("Downloading OANC (this is ~660MB)...")
  status <- system2(
    "curl",
    c("-L", "--fail", "--insecure", "-C", "-", "-o", archive_path, url)
  )
  if (!is.null(status) && status != 0) {
    stop("Download failed. Check your network connection and URL.")
  }
} else {
  message("Archive already exists: ", archive_path)
}

message("Extracting archive...")
status <- system2("tar", c("-xzf", archive_path, "-C", raw_dir))
if (!is.null(status) && status != 0) {
  stop("Extraction failed. Ensure 'tar' is available.")
}

message("Download and extraction complete.")
