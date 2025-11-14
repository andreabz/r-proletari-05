# R\get_clean_values.R
library(data.table)
library(readxl)
library(stringr)
source("R/checks.R")

# ==============================================================================
# 1. LETTURA HEADER DI RIGA (generica) ----
# ==============================================================================

#' Legge una riga di intestazione da Excel e la normalizza
#'
#' @param path path del file Excel
#' @param sheet foglio da leggere
#' @param skip numero di righe da saltare
#' @param label etichetta da assegnare alla prima colonna (es. "sample_id")
#'
#' @return character vector contenente la riga estratta e pulita
read_header_row <- function(path, sheet,
                            skip = 1,
                            label = "sample_id") {
  r <- readxl::read_excel(
    path = path,
    sheet = sheet,
    skip = skip,
    n_max = 0,
    .name_repair = "minimal"
  ) |> names()
  
  r <- stringr::str_replace(r, "\\.\\.\\.\\d", NA_character_)
  y <- r[-1]
  y <- y[!is.na(y)]
  c(label, y)
}

# ==============================================================================
# 2. LETTURA DATA IN FORMATO IBRIDO ----
# ==============================================================================

#' Estrae la riga delle date di campionamento gestendo formati diversi
#' 
#' @param path path del file Excel
#' @param sheet foglio da leggere
#' @param skip numero di righe da saltare
#' @param label etichetta da assegnare alla prima colonna (es. "sampling_date")
#'
#' @description Le date possono essere numeri Excel o stringhe dd/mm/YYYY.
#'
#' @return character vector con label + date convertite
read_sampling_date <- function(path, sheet,
                               skip = 3,
                               label = "sampling_date") {
  x <- suppressMessages(
    readxl::read_excel(
      path = path,
      sheet = sheet,
      skip = skip,
      n_max = 0,
      col_types = "date",
      na = c("", "-", "_"),
      .name_repair = "minimal"
    )
  ) |> names()

  
  date_num <- suppressWarnings(as.numeric(x) |> as.Date(origin = "1899-12-30"))
  date_ita <- suppressWarnings(as.Date(x, format = "%d/%m/%Y"))
  date_final <- ifelse(is.na(date_num), date_ita, date_num) |> as.Date()
  
  # Scarta prime due colonne come nella funzione originale
  y <- date_final[-c(1, 2)]
  c(label, "", y)
}

# ==============================================================================
# 3. LETTURA VALORI GREZZI ----
# ==============================================================================

#' Legge i valori grezzi dal file (da riga 6 in poi)
#' 
#' @param path path del file Excel
#' @param sheet foglio da leggere
#' @param skip numero di righe da saltare
#'
#' @return data.table con le colonne originali
read_raw_values <- function(path, sheet,
                            skip = 5) {
  readxl::read_excel(
    path = path,
    sheet = sheet,
    skip = 5,
    na = c("", "-", "_", "*")
  ) |> data.table::data.table()
}

# ==============================================================================
# 4. CREAZIONE HEADER COMPLETO ----
# ==============================================================================
#' Combina gli header in un'unica struttura table
#'
#' @param ... vettori di header (sample_id, sampling_point, date, laboratorio)
#' @param n numero colonne totali
#'
#' @return data.table dei metadati (uno per colonna)
build_header_table <- function(n, ...) {
  headers <- rbind(...)
  dt <- data.table::data.table(headers)
  names(dt) <- c(
    "parameter",
    "unit",
    "site_limit",
    "national_limit",
    paste0("X_", 5:n)
  )
  dt
}

# ==============================================================================
# 5. MELT HEADER E VALORI ----
# ==============================================================================

#' Trasforma gli header in formato long e wide
#'
#' @param header_table data.table header
#' @param n numero colonne
#'
#' @return header riorganizzato per merge
melt_headers <- function(header_table, n) {
  variable_cols <- paste0("X_", 5:n)
  
  data.table::melt(header_table, measure.vars = variable_cols) |>
    dcast(variable ~ parameter)
}

#' Melt dei valori grezzi
#'
#' @return data.table long
melt_values <- function(raw_values, n) {
  raw_values[!is.na(unit)] |>
    data.table::melt(measure.vars = 5:n)
}

# ==============================================================================
# 6. MERGE METADATI + VALORI ----
# ==============================================================================

#' Unisce header e valori in un'unica tabella
#'
#' @return data.table unificato preliminare
merge_header_values <- function(headers_melt, raw_values_melt) {
  merge.data.table(
    headers_melt,
    raw_values_melt,
    by = "variable"
  )
}

# ==============================================================================
# 7. NORMALIZZAZIONE E CALCOLI FINALI ----
# ==============================================================================

#' Normalizza valori, limiti, <LoQ e calcola colonne derivate
#'
#' @param dt data.table unito
#' @param sheet nome foglio (usato per area)
#'
#' @return data.table pulito e completo
normalize_values <- function(dt, sheet) {
  dt <- dt[
    , `:=`(
      sampling_date = as.numeric(sampling_date) |> as.Date(),
      
      # limite unico
      limit = ifelse(
        is.na(site_limit) & is.na(national_limit),
        NA,
        ifelse(!is.na(national_limit), national_limit, site_limit)
      ),
      
      # tipologia limite
      limit_type = ifelse(
        is.na(site_limit) & is.na(national_limit),
        NA,
        ifelse(!is.na(national_limit), "dlgs_152_06", "local")
      ),
      
      value_txt = value,
      value = NULL,
      site_limit = NULL,
      national_limit = NULL
    )
  ][!is.na(sampling_date)]
  
  dt[, `:=`(
    parameter = tolower(parameter),
    below_loq = stringr::str_starts(trimws(value_txt), "<"),
    limit = sub(",", ".", x = limit) |> as.numeric(),
    value = sub("<", "", value_txt) |>
      sub(",", ".", x = _) |>
      as.numeric(),
    value_txt = NULL,
    area = sheet
  )][,
     above_limit := value > limit
  ][,
    .(
      sample_id,
      sampling_date,
      sampling_point,
      area,
      laboratory_name,
      parameter,
      unit,
      limit_type,
      limit,
      below_loq,
      value,
      above_limit
    )
  ]
}

# ==============================================================================
# FUNZIONE PRINCIPALE (ORCHESTRATORE) ----
# ==============================================================================

#' Estrae e normalizza un dataset ordinato da file Excel disordinati
#'
#' @param path path del file Excel
#' @param sheet foglio da leggere
#'
#' @return data.table normalizzato

get_clean_values <- function(path, sheet) {
  stopifnot(is.character(path))
  stopifnot(is.character(sheet))
  stopifnot(file.exists(path))
  
  # header separati
  raw_samples <- read_header_row(path, sheet, skip = 1, label = "sample_id")
  raw_points  <- read_header_row(path, sheet, skip = 2, label = "sampling_point")
  raw_date    <- read_sampling_date(path, sheet, skip = 3, label = "sampling_date")
  raw_labname <- read_header_row(path, sheet, skip = 4, label = "laboratory_name")
  
  # controllo la lunghezza degli header prima di unirli
  validate_header_lengths(list(
    sample_id       = raw_samples,
    sampling_point  = raw_points,
    sampling_date   = raw_date,
    laboratory_name = raw_labname
  ))
  
  n <- length(raw_samples)
  
  raw_values <- read_raw_values(path, sheet)
  
  header_table <- build_header_table(
    n,
    raw_samples, raw_points, raw_date, raw_labname
  )
  
  # controllo che l'heaader abbia tutte le colonne specificate
  validate_expected_columns(
    header_table,
    expected = c("parameter","unit","site_limit","national_limit")
  )
  
  # controllo la presenza di dati
  validate_raw_values(raw_values)
  
  # controllo il numero di colonne di header e valori
  validate_alignment(header_table, raw_values)
  
  # allineamento colnames ai valori
  names(raw_values) <- names(header_table)
  
  headers_melt     <- melt_headers(header_table, n)
  raw_values_melt  <- melt_values(raw_values, n)
  
  raw_dataset <- merge_header_values(headers_melt, raw_values_melt)
  
  normalize_values(raw_dataset, sheet)
}

# ==============================================================================
# RIPETIZIONE SULLE SCHEDE DI UN FOGLIO EXCEL ----
# ==============================================================================
#' Importa e pulisce tutti i fogli di un file Excel
#'
#' @description
#' `process_excel_file()` applica la funzione `get_clean_values()` 
#' a tutti i fogli (sheet) contenuti in un file Excel.  
#' È utile quando un singolo file contiene più aree, zone, o insiemi di dati 
#' strutturati in modo simile, ognuno su un foglio diverso.
#'
#' La funzione:
#' * individua tutti i fogli presenti nel file;
#' * applica `get_clean_values()` a ciascuno di essi;
#' * combina i risultati in un'unica `data.table`.
#'
#' @details
#' La funzione assume che **ogni foglio del file Excel** abbia la struttura
#' compatibile con `get_clean_values()`.  
#' Se uno o più fogli presentano formati imprevisti o non pulibili, la funzione
#' potrà generare errori.  
#'
#' Per mantenere il tracciamento dell’importazione, la funzione produce un
#' messaggio a console che indica quale file e quale foglio si stanno elaborando.
#'
#' @param file character. Percorso completo al file Excel da elaborare.
#'
#' @returns
#' Una `data.table` contenente i dati puliti provenienti da **tutti** i fogli del
#' file.  
#' Se i fogli hanno strutture identiche (come previsto), le colonne combaciano; 
#' in caso contrario, `rbindlist(fill = TRUE)` riempie automaticamente le colonne
#' mancanti con `NA`.
#'
#' @seealso
#' * [`get_clean_values()`] per la funzione di pulizia di un singolo foglio.  
#' * [`excel_sheets()`][readxl::excel_sheets] per individuare gli sheet di un file.  
#' * [`rbindlist()`][data.table::rbindlist] per combinare più tabelle.
#'
#' @examples
#' \dontrun{
#' # Esempio: importare e pulire tutti i fogli di "dati.xlsx"
#' dati <- process_excel_file("path/dati.xlsx")
#' }
#'
process_excel_file <- function(file) {
  stopifnot(is.character(file))
  stopifnot(file.exists(file))
  
  sheets <- readxl::excel_sheets(file)
  
  data.table::rbindlist(
    lapply(sheets, function(sh) {
      message("Importo: ", basename(file), " — sheet: ", sh)
      get_clean_values(path = file, sheet = sh)
    }),
    fill = TRUE
  )
}