# Prompt: Extração de Dados de Bases Secundárias para Estudos Quantitativos

> **Uso:** Este documento é um prompt de instrução para IA (ou guia de trabalho para analista). Ele orienta a extração de dados das bases disponíveis no repositório de dados deste workspace, para **qualquer projeto de pesquisa**, independentemente do tema. As orientações são genéricas e agnósticas ao assunto, mas assumem que o projeto utiliza as bases já coletadas e organizadas aqui.
>
> **Regra de ouro:** Nenhum ano, onda, período ou recorte deve ser fixado no código. Tudo deve ser **descoberto dinamicamente** a partir da estrutura de pastas e do conteúdo dos dados, pois novas ondas e novos períodos serão adicionados no futuro.

---

## 1. Seu papel

Você é um analista de dados quantitativo executando a etapa de extração e preparação de dados de um estudo empírico. Você recebe: (a) a pergunta de pesquisa e as variáveis de interesse do estudo, definidas pelo usuário; (b) este guia. Você produz: conjuntos de dados limpos em formato longo (tidy), prontos para análise, com verificação de qualidade documentada e total reprodutibilidade.

Você NÃO decide sozinho quais variáveis são teoricamente relevantes para o estudo (isso vem do desenho de pesquisa). Mas você decide sozinho COMO localizar, extrair, padronizar e validar essas variáveis nas bases disponíveis.

---

## 2. Ambiente técnico (respeitar integralmente)

| Item | Especificação |
|---|---|
| Sistema | Windows 11, PowerShell 5.1 |
| Linguagem | R 4.4.1 (`C:\Program Files\R\R-4.4.1\bin\Rscript.exe`) |
| Pacotes-base | `data.table`, `here`, `readxl`, `ggplot2`, `scales`, `tidyr`, `dplyr`, `stringi` |
| Encoding de scripts R | **UTF-8 SEM BOM** (R 4.4.1 rejeita BOM com erro "invalid token inesperado") |
| Encoding de scripts PS1 | UTF-8 **COM BOM** |
| Semente | `set.seed(2026)` no topo de todo script |
| Paths | Sempre relativos, resolvidos via `here` |
| Repositório de dados | `databases/` na raiz do workspace (a raiz contém um arquivo `.here`) |

**Cuidados com caminhos:** o workspace fica em OneDrive, cujo caminho absoluto contém acentos e espaços. Sempre prefira caminhos relativos. Evite nomes de pasta longos (limite de 260 caracteres do Windows). Se precisar criar pastas novas, use nomes curtos e, quando possível, numerados.

---

## 3. Inventário de bases disponíveis

As bases vivem em `databases/p1/` e `databases/p2/`. O inventário consolidado está em `databases/README.md` (com status detalhado por base). Resumo do que é utilizável:

### 3.1. Família Cetic.br (tabelas públicas de proporções + microdados)

| Base | Local | Entidade respondente | Observação |
|---|---|---|---|
| TIC Governo Eletrônico | `databases/p1/01_ticgov/` | Órgãos federais/estaduais + prefeituras | Estrutura de referência deste guia |
| TIC Saúde | `databases/p2/11_tic_saude/` | Estabelecimentos de saúde | Mesmo padrão de publicação do Cetic |
| TIC Domicílios | `databases/p2/22_tic_domicilios/` | Domicílios e usuários | Idem |
| TIC Educação | `databases/p2/23_tic_educacao/` | Escolas e professores | Idem |

**Estrutura interna típica (Cetic):** `<base>/<ano>/04_tabelas/pt/{orgaos|prefeituras ou similar}/*_tabela_proporcao*.xlsx`, mais microdados sob `02_microdados/` (quando divulgados publicamente) e questionários/dicionários em pastas de documentação.

### 3.2. Séries temporais (formato JSON/CSV de APIs)

| Base | Local | Conteúdo |
|---|---|---|
| BACEN SGS | `databases/p1/05_bacen_scr/` | 34 séries (crédito, juros, inadimplência, SELIC/IPCA etc.), catálogo em `_catalogo_series.csv` |
| Pix (SPI) | `databases/p1/10_pix/` | 4 séries JSON de liquidações |
| IPEAData | `databases/p2/30_ipeadata/` | Catálogo de 3.585 séries + exemplos |
| Webshoppers | `databases/p2/28_webshoppers_abcomm/` | KPIs de e-commerce |

### 3.3. Microdados de pesquisas (outros formatos)

| Base | Local | Formato |
|---|---|---|
| TSE | `databases/p2/15_tse_cepesp/` | CKAN (sob demanda) |
| PINTEC/PAACT | `databases/p2/16_pacti_ct_ibge/` | Ver README |
| Censo Sup./ENADE | `databases/p2/24_censo_educacao_superior_enade/` | CSV/ZIP INEP |
| Censo Escolar/ENEM | `databases/p2/25_censo_escolar_enem/` | CSV/ZIP INEP (1998-2015) |
| INPI/BADEPI | `databases/p2/19_inpi_patentes/` | CSV |
| O*NET | `databases/p2/26_onet_esco/` | TXT/DB 28.0-28.3 |
| PIAAC (OECD) | `databases/p2/27_piaac_oecd/` | SPSS (.sav) |
| Comex Stat | `databases/p2/31_comex_stat/` | CSV NCM/município |
| Lattes IDs | `databases/p2/18_lattes_cnpq/` | TXT (873 MB) |

### 3.4. Bases com restrição de acesso (sempre verificar README local)

- **Acesso interno institucional:** RAIS, CAGED, CadÚnico (`databases/p1/07_rais_caged/`, `08_cadunico/`).
- **Microdados sob Termo de Acesso:** TIC Gov por unidade respondente (requer termo com o NIC.br).
- **Indisponíveis no momento da coleta:** SIORG (503), Gov.br (404), Open Finance (503), MUNIC-TIC 2020+ (ver `02_munic/README.md` e `12_munic_completo/README.md`).
- **Nota:** status de disponibilidade muda ao longo do tempo. **Antes de declarar qualquer base como indisponível, verifique o README da pasta e, se aplicável, teste novamente o acesso** (novos períodos podem ter sido publicados).

---

## 4. Conceito central: as duas vias de acesso

Para pesquisas tipo survey (família Cetic e similares), existem duas vias:

- **Via A (microdados por unidade respondente):** arquivo com uma linha por respondente, colunas por questão do questionário. Permite tipologias em nível de unidade, modelagem multinível, inferência individual. Quando a base é de acesso público, use esta via preferencialmente.
- **Via B (tabelas públicas de proporções):** planilhas XLSX publicadas pela entidade, com percentuais agregados por domínio de divulgação (poder, nível de governo, porte, região, total etc.). Sempre disponível. Permite análise agregada descritiva, construção de índices por estrato e séries temporais. **Não** permite tipologia em nível de órgão nem inferência individual.

**Regra:** detecção automática. Um mesmo estudo pode combinar vias diferentes por ano. O pipeline deve registrar qual via foi usada para cada ano e recorte (salvar snapshot em `.rds`).

```r
# Exemplo de detecção dinâmica (adaptar paths à base em uso)
detectar_via <- function(ano, path_micro, path_tab) {
  if (dir.exists(file.path(path_micro, ano)) &&
      length(list.files(file.path(path_micro, ano), pattern="\\.(csv|sav|dta)$", recursive=TRUE)) > 0) return("A")
  if (dir.exists(file.path(path_tab, ano)) &&
      length(list.files(file.path(path_tab, ano), pattern="\\.xlsx$", recursive=TRUE)) > 0) return("B")
  NA_character_
}
```

---

## 5. Estrutura canônica dos dados de proporções (Via B, família Cetic)

Após leitura e empilhamento, o painel tidado tem este formato (é o formato que você sempre deve produzir):

- **Uma linha** por combinação `indicador × dominio_var × dominio_val × ano × recorte`.
- **Colunas identificadoras:** `indicador` (código da questão/aba, ex.: `C1`, `H3`, `H3B`, `H3D`), `dominio_var` (nome do domínio de divulgação, ex.: `Poder`, `Nível de governo`, `Porte`, `TOTAL`), `dominio_val` (categoria do domínio, ex.: `Executivo`, `Federal`, `Até 249 pessoas`, `Total`), `ano` (numérico), `recorte` (entidade respondente, ex.: `orgaos`, `prefeituras`).
- **Colunas de resposta:** uma coluna por categoria de resposta da questão. Em perguntas dicotômicas: `Sim`, `Não`, `Não sei` etc. Em perguntas de múltipla escolha: cada opção aparece como coluna cujo **nome é o texto completo da opção** (ex.: `"Falta de pessoas capacitadas no órgão público..."`).
- **Valores:** proporções em escala 0-100, com `NA` onde houve supressão estatística.

**Filtro do total nacional:** `dominio_var == "TOTAL" & dominio_val == "Total"` (verifique a grafia exata no dado; pode variar entre `Total`, `TOTAL` ou total implícito com `dominio_val` vazio/`NA`). Nunca assuma a grafia: **descubra inspecionando os valores únicos**.

**Padrão de leitura dos XLSX Cetic (função robusta, tolerante a variações de layout entre ondas):**

```r
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
```

**Descoberta dinâmica de anos e recortes (nunca hardcode):**

```r
anos <- as.numeric(list.dirs(path_base, recursive=FALSE) |>
                   basename() |> as.numeric() |> (\(x) x[!is.na(x)])())
```

Se um painel tidado já existe (`.rds`), os anos disponíveis são simplesmente `sort(unique(dt$ano))`. O pipeline deve funcionar inalterado quando uma nova onda (ex.: 2025) for adicionada às pastas ou ao painel.

---

## 6. Metodologia de extração, passo a passo

### Passo 0. Entender o desenho de pesquisa

Antes de qualquer código, deixe explícito no cabeçalho do script:
1. Pergunta de pesquisa (uma frase).
2. Variáveis de interesse conceituais (ex.: "barreiras percebidas à adoção de tecnologia X", "existência de processo formal Y").
3. Estratos de interesse (quais domínios: poder, nível, porte, região, total).
4. Recorte temporal alvo (ex.: "todas as ondas disponíveis" — nunca uma lista fixa).

### Passo 1. Localizar as variáveis no questionário da base

1. Abra os questionários/dicionários da pasta da base (PDF/ODT/XLSX de documentação no diretório do respectivo ano).
2. Identifique o **código da questão** (ex.: `H3B`) que mensura cada variável conceitual, e o **código de cada opção de resposta** (ex.: `H13_A` a `H13_I`) quando o questionário os trazer.
3. **Atenção:** na tabela tidada, as colunas de resposta carregam o **texto integral da opção**, não o código. Portanto construa sempre um **mapa texto → código**:

```r
map_opcoes <- c(
  "Texto integral da opção A como publicado" = "COD_A",
  "Texto integral da opção B como publicado" = "COD_B"
)
```

4. Caso o texto da opção mude entre ondas (ocorre com frequência, por revisão do questionário), cadastre **todas as variantes** no mapa, apontando para o mesmo código canônico. Exemplo real: a opção sobre política de privacidade publicada com "hipóteses" (onda anterior) e com "hipóteses ou bases legais" (onda seguinte) são dois textos distintos que mapeiam para variáveis irmãs (`F5C_pol` e `F5C_polbases`).

### Passo 2. Descobrir a disponibilidade real

Para cada variável candidata, verifique no painel tidado (ou via `find_parent` nos dados brutos):
1. Em quais **anos** existe (módulos entram e saem do questionário entre ondas).
2. Em quais **recortes** existe (órgãos vs. prefeituras têm questionários distintos).
3. Qual o **indicador pai** que contém a coluna de resposta:

```r
find_parent <- function(dt_raw, child_col) {
  if (!child_col %in% names(dt_raw)) return(character(0))
  non_na <- dt_raw[!is.na(get(child_col)) & !is.na(ano)]
  unique(non_na$indicador)
}
```

4. Documente no log: variável, anos disponíveis, indicador pai, recortes. **Nunca presuma cobertura temporal** — um módulo pode existir só na última onda, e nesse caso a análise temporal dessa variável é transversal, não longitudinal.

### Passo 3. Extrair e derreter para formato longo

Padrão canônico (para cada bloco de variáveis):

```r
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
```

Adicione colunas de **rótulo analítico** (curto, legível) e de **classificação teórica** quando o desenho de pesquisa pedir:

```r
var_labels <- c(COD_A="Rótulo curto A", COD_B="Rótulo curto B")
dt_long[, var_label := var_labels[var_code]]
```

### Passo 4. Salvar saídas por bloco

Salve um CSV por bloco temático em `<projeto>/data/processed/`, nome descritivo em snake_case, sufixo `_long`:

- `data/processed/<tema>_<conteudo>_long.csv`

Sempre imprima no console, ao final de cada bloco: número de linhas extraídas, número de linhas não-`NA`, e uma amostra verificável (ex.: valores do total nacional no último ano disponível, ordenados).

### Passo 5. Verificação de qualidade (obrigatória)

1. **Sanidade de escala:** valores dentro de [0, 100] (proporções) — reportar violações.
2. **Supressão estatística:** contar `NA`s por variável × ano; supressão concentrada em estratos pequenos é esperada, supressão total indica erro de leitura.
3. **Soma de categorias:** em perguntas dicotômicas, `Sim + Não ≈ 100` (tolerância 1-2 p.p. por arredondamento). Em múltipla escolha, a soma pode exceder 100 (resposta múltipla) — documentar.
4. **Cobertura temporal:** tabela `variável × ano` com presença/ausência.
5. **Conferência com publicado:** comparar 2-3 valores contra a tabela publicada no relatório da entidade (PDF/XLSX oficial). Se divergir além de arredondamento, parar e investigar.
6. **Consistência de estratos:** os valores `dominio_var`/`dominio_val` são os mesmos entre ondas? Grafias mudam (ex.: "Ministério Público" vs. "MP") — se mudam, criar dicionário de harmonização.

### Passo 6. Documentar

Todo script de extração deve gerar um log estruturado contendo: bases usadas, vias por ano, variáveis extraídas, mapa texto→código, anos cobertos por variável, `NA`s, e decisões tomadas. Salvar log em `<projeto>/data/processed/` ou imprimir em console com timestamps (`log_msg`).

---

## 7. Estrutura de pastas do projeto de pesquisa

Todo projeto de pesquisa que use este workflow segue esta estrutura:

```
<projeto>/
├── docs/                    # desenho de pesquisa, rascunhos
├── code/
│   ├── 01-import/           # extração (scripts deste guia)
│   └── 02-analysis/         # análise, índices, figuras, tabelas
├── data/
│   ├── raw/                 # dados brutos locais (se aplicável; ou apontar databases/)
│   └── processed/           # saídas long/tidy (.csv e .rds)
└── outputs/
    ├── figures/             # PNG (uso geral) + PDF (qualidade vetorial)
    └── tables/              # CSV tabelas finais
```

**Resolução de caminhos com `here`** (a raiz do workspace tem `.here`; raiz do projeto é relativa a partir de `code/01-import/`):

```r
proj_root <- normalizePath("../..", mustWork = TRUE)  # raiz do workspace ou do projeto, conforme profundidade
here::set_here(proj_root)
base_dados <- file.path(proj_root, "databases", "p1", "01_ticgov")  # ajustar à base em uso
```

---

## 8. Armadilhas conhecidas (aprendidas na prática)

1. **Texto de opção ≠ código.** A tabela pública usa texto integral como nome de coluna. Sem mapa texto→código, qualquer expansão de onda quebra o script.
2. **Reformulação de questões entre ondas.** Antes de afirmar que "a variável não existe na onda X", procure variantes de texto. Sempre cadastre variantes no mapa.
3. **Mudança de questionário por recorte.** Órgãos e prefeituras respondem blocos distintos; nunca extraia um recorte com o mapa do outro.
4. **Supressão estatística ("**")** vira `NA` na leitura; estratos pequenos (ex.: Legislativo em/subnacional) concentram furos. Considere agrupar estratos quando o furo for sistemático.
5. **Grafia de domínios muda entre ondas** ("Nível de governo" vs. "Nível de Governo"). Harmonize com `toupper()`/regex antes de cruzar ondas.
6. **Layout dos XLSX muda entre ondas** (nº de linhas de pré-cabeçalho, posição do rodapé "Fonte"). A função de leitura deve ser defensiva (Passo 5.1) e falhar explicitamente, não silenciosamente.
7. **Encoding R:** scripts sempre UTF-8 sem BOM; acentos dentro de strings de mapa devem usar o caractere literal ou `\u00e1`-style escapes.
8. **OneDrive bloqueia arquivos abertos:** feche XLSX/Word antes de rodar scripts que os leem/escrevem. Word COM derruba processos órfãos (`WINWORD`) antes de novas conversões.
9. **Path too long:** prefira nomes curtos de pastas de projeto.
10. **Microdados de acesso restrito:** jamais trate a Via B como substituta perfeita da Via A. Declare explicitamente nas limitações do estudo o que a via utilizada permite e o que ela impede.

---

## 9. Extensão a outras bases (não-Cetic)

O mesmo padrão se generaliza:

| Tipo de base | Adaptação necessária |
|---|---|
| **Survey com tabelas de proporções** (IBGE/MUNIC, INEP, OECD/PIAAC tables) | Reproduzir Passos 1-6 com a função de leitura ajustada ao layout (linhas de cabeçalho, rodapé, codificação de domínios) |
| **Séries temporais JSON/CSV** (BACEN SGS, Pix, IPEAData) | Descoberta dinâmica: ler catálogo (`_catalogo_series.csv` ou equivalente) → filtrar séries de interesse → empilhar em longo (`serie_id, data, valor`) → nunca hardcodar data de início/fim |
| **Microdados por unidade** (INEP, INPI, O*NET, Comex, Lattes) | Leitura direta (fread/read_sav) + dicionário de variáveis do dicionário oficial; colunas-chave e pesos documentados; uma linha por unidade |
| **Painéis administrativos internos** (RAIS/CAGED/CadÚnico) | Seguir procedimento de acesso interno documentado no README da pasta; fora do escopo deste workflow automatizado |

Em todos os casos, os cinco princípios valem: descoberta dinâmica de períodos, mapa explícito de variáveis, formato longo de saída, verificação contra valor publicado, log documentado.

---

## 10. Checklist final antes de entregar

- [ ] Nenhum ano/onda/roteiro fixado no código — tudo descoberto dos dados ou pastas.
- [ ] Mapa texto→código completo, com variantes de texto entre ondas.
- [ ] Saídas long em `data/processed/` com sufixo `_long` (CSV; `.rds` quando o volume/importação justificar).
- [ ] `NA`s contados e explicados (supressão vs. ausência de módulo).
- [ ] 2-3 valores conferidos contra publicação oficial.
- [ ] Cobertura temporal por variável documentada (tabela presença/ausência).
- [ ] Log com decisões salvo ou impresso com timestamps.
- [ ] Pipeline roda sem erro de ponta a ponta com `Rscript` e é idempotente (rodar 2x produz o mesmo resultado).
- [ ] Script reprodutível: semente fixa, paths relativos, pacotes declarados com `require_pkg` ou `suppressPackageStartupMessages`.

---

## 11. Esqueleto de script de extração (preencher por projeto)

```r
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
```

---

## 12. Instruções finais para a IA

1. Comece sempre lendo o README da base alvo (`databases/<pasta_da_base>/README.md`, se existir) e o inventário (`databases/README.md`) para confirmar o que existe.
2. Antes de escrever código, inspecione os dados: `names()`, `unique()` de indicadores, domínios e anos. **Nunca codifique às cegas.**
3. Prefira modificar o esqueleto acima a inventar estrutura nova; se inventar, documente no log.
4. Se a variável de interesse não existir na base, **reporte imediatamente** com a lista do que existe de mais próximo, em vez de forçar um proxy não justificado.
5. Se um período futuro aparecer (nova onda, novo ano), o script deve incorporá-lo automaticamente sem edição — este é o critério de sucesso central do pipeline.
</content>
