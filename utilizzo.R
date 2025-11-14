source("R/get_clean_values.R")

# path alla cartella
dir_path <- "data"

# lista dei file Excel nella cartella
files <- list.files(
  path = dir_path,
  pattern = "\\.xlsx$",
  full.names = TRUE
)

# applicazione su tutti i file
all_data <- rbindlist(
  lapply(files, process_excel_file),
  fill = TRUE
)

# risultato finale
all_data