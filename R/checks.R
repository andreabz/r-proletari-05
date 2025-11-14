# R/checks.R
# ==============================================================================
# CONTROLLO LA LUNGHEZZA DEGLI HEADER ----
# ==============================================================================

#' Controlla che tutti gli header abbiano la stessa lunghezza
#'
#' @param headers list di vettori header
#'
#' @return NULL (emette warnings se incongruenze)
validate_header_lengths <- function(headers) {
  lens <- sapply(headers, length)
  if (length(unique(lens)) != 1) {
    warning(
      "Header con lunghezze non coerenti: ",
      paste(names(headers), lens, sep = "=", collapse = ", "),
      "\nLa pipeline tenterà comunque di proseguire."
    )
  }
}

# ==============================================================================
# CONTROLLO LA PRESENZA DI COLONNE MANCANTI ----
# ==============================================================================

#' Controlla che l'header abbia tutte le colonne con il nome atteso
#'
#' @param dt data.table contenente l'header
#' @param expected vettore con i nomi attesi nell'header
#'
#' @return NULL (emette warnings se incongruenze)
validate_expected_columns <- function(dt, expected) {
  if (!all(expected %in% names(dt))) {
    warning(
      "Colonne mancanti nell’header: ",
      paste(setdiff(expected, names(dt)), collapse = ", ")
    )
  }
}

# ==============================================================================
# CONTROLLO LA PRESENZA DI DATI ----
# ==============================================================================

#' Controlla che siano presenti i dati
#'
#' @param dt data.table contenente i dati
#'
#' @return NULL (emette warnings se incongruenze)
validate_raw_values <- function(dt) {
  if (nrow(dt) == 0) {
    warning("Nessun valore grezzo trovato (raw_values = empty).")
  }
  
  if (all(sapply(dt, function(x) all(is.na(x))))) {
    warning("Tutte le colonne di raw_values sono completamente vuote.")
  }
}

# ==============================================================================
# CONTROLLO SUL NUMERO DELLE COLONNE DEI DATI E DELL'HEADER ----
# ==============================================================================

#' Controlla header e valori condividano lo stesso numero di colonne
#'
#' @param header data.table dell'header
#' @param values data.table dei valori
#'
#' @return NULL (emette warnings se incongruenze)
validate_alignment <- function(header, values) {
  if (ncol(values) != length(header)) {
    warning(
      "Incoerenza tra numero colonne header (", length(header),
      ") e raw_values (", ncol(values), ")."
    )
  }
}
