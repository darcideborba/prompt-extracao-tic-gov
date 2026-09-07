# Codigo extraido verbatim do prompt Prompt_EXTRACAO_DADOS_TIC_Gov.md
# Trechos na ordem em que aparecem no documento (deteccao de via, parser, esqueleto).

# Exemplo de detecção dinâmica (adaptar paths à base em uso)
detectar_via <- function(ano, path_micro, path_tab) {
  if (dir.exists(file.path(path_micro, ano)) &&
      length(list.files(file.path(path_micro, ano), pattern="\\.(csv|sav|dta)$", recursive=TRUE)) > 0) return("A")
  if (dir.exists(file.path(path_tab, ano)) &&
      length(list.files(file.path(path_tab, ano), pattern="\\.xlsx$", recursive=TRUE)) > 0) return("B")
  NA_character_
}


# ---- bloco seguinte ----

ler_aba <- function(arq, aba) {
  df <- tryCatch(readxl::read_excel(arq, sheet=aba, .name_repair="minimal",
                                   na=c("", "-", "**", "NA")),
                 error=function(e) NULL)
  if (is.null(df) || ncol(df) < 4) return(NULL)
  nomes_resp <- as.character(unlist(df[2, ]))          # linha 2 = categorias
  nomes_resp[is.na(nomes_resp)] <- paste0("v", which(is.na(nomes_resp)))
  nomes_resp <- make.unique(nomes_resp)
  names(df) <- nomes_resp
  df <- df[-c(1:3), , drop=FALSE]                       # remove pré-cabeçalho
  dom1 <- names(df)[1]; dom2 <- names(df)[2]
  df <- df[!is.na(df[[dom1]]) & df[[dom1]] != "", , drop=FALSE]
  fonte_idx <- grep("^Fonte", df[[dom1]])               # remove rodapé
  if (length(fonte_idx)) df <- df[1:(fonte_idx[1]-1), , drop=FALSE]
  if (nrow(df) == 0) return(NULL)
  df$dominio_var <- df[[dom1]]; df$dominio_val <- df[[dom2]]
  df$indicador <- aba
  resp_cols <- names(df)[3:(which(names(df)=="dominio_var")-1)]
  for (rc in resp_cols) df[[rc]] <- suppressWarnings(as.numeric(df[[rc]]))
  as.data.table(df[, c("indicador","dominio_var","dominio_val", resp_cols),
                   drop=FALSE])
}


# ---- bloco seguinte ----

anos <- as.numeric(list.dirs(path_base, recursive=FALSE) |>
                   basename() |> as.numeric() |> (\(x) x[!is.na(x)])())


# ---- bloco seguinte ----

map_opcoes <- c(
  "Texto integral da opção A como publicado" = "COD_A",
  "Texto integral da opção B como publicado" = "COD_B"
)


# ---- bloco seguinte ----

find_parent <- function(dt_raw, child_col) {
  if (!child_col %in% names(dt_raw)) return(character(0))
  non_na <- dt_raw[!is.na(get(child_col)) & !is.na(ano)]
  unique(non_na$indicador)
}


# ---- bloco seguinte ----

dt_ind <- dt[recorte=="orgaos" & !is.na(ano) & indicador==CODIGO_QUESTAO,
             .(indicador, dominio_var, dominio_val, ano)]
for (texto in names(map_opcoes)) {
  cod <- map_opcoes[texto]
  if (texto %in% names(dt))
    dt_ind[, (cod) := dt[indicador==CODIGO_QUESTAO, get(texto)]]
}
dt_long <- melt(dt_ind,
  id.vars = c("indicador","dominio_var","dominio_val","ano"),
  measure.vars = intersect(unname(map_opcoes), names(dt_ind)),
  variable.name = "var_code", value.name = "proporcao",
  variable.factor = FALSE)
dt_long[, proporcao := as.numeric(proporcao)]


# ---- bloco seguinte ----

var_labels <- c(COD_A="Rótulo curto A", COD_B="Rótulo curto B")
dt_long[, var_label := var_labels[var_code]]


# ---- bloco seguinte ----

proj_root <- normalizePath("../..", mustWork = TRUE)  # raiz do workspace ou do projeto, conforme profundidade
here::set_here(proj_root)
base_dados <- file.path(proj_root, "databases", "p1", "01_ticgov")  # ajustar à base em uso


# ---- bloco seguinte ----

# ============================================================================
# 0X_extract_<tema>_data.R
# Extração de <variáveis do estudo> de <base> para <projeto>
# Entradas: <path da base ou painel tidado>
# Saídas:   data/processed/<tema>_<bloco>_long.csv
# ============================================================================
suppressPackageStartupMessages({
  library(data.table); library(here)
})
set.seed(2026)

# --- Setup -------------------------------------------------------------------
proj_root <- normalizePath("../..", mustWork = TRUE)
here::set_here(proj_root)
data_dir <- file.path(proj_root, "<projeto>", "data", "processed")
dir.create(data_dir, recursive = TRUE, showWarnings = FALSE)

# --- 1. Carregar painel tidado (ou construir a partir dos XLSX, ver seção 5) --
src <- file.path(proj_root, "<caminho_do_painel_tidy>.rds")
dt <- as.data.table(readRDS(src))

# --- 2. Descoberta dinâmica --------------------------------------------------
anos_disp <- sort(unique(dt[!is.na(ano), ano]))
recortes_disp <- unique(dt$recorte)
# indicadores_disponiveis <- unique(dt$indicador)

# --- 3. Mapa texto -> codigo (com variantes entre ondas) ----------------------
map_opcoes <- c(
  "texto da opção (variante onda 1)" = "COD_A",
  "texto da opção (variante onda 2)" = "COD_A",
  "texto da opção B" = "COD_B"
)
var_labels <- c(COD_A="Rótulo curto A", COD_B="Rótulo curto B")

# --- 4. Extrair bloco ---------------------------------------------------------
# (padrão melt da seção 6, Passo 3)

# --- 5. QA e log --------------------------------------------------------------
# contagens, amostras, checagens da seção 6, Passo 5

# --- 6. Salvar ----------------------------------------------------------------
# fwrite(dt_long, file.path(data_dir, "<tema>_<bloco>_long.csv"))

cat("Concluido: 0X_extract_<tema>_data.R\n")
