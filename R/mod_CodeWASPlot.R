#
# UI
#

mod_codeWASPlot_ui <- function(id) {
  ns <- shiny::NS(id)

  htmltools::tagList(
    DT::dataTableOutput(ns("codeWAStable")),
  )

}

#
# server
#

mod_codeWASPlot_server <- function(id, analysisResultsHandler) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

    atlasUrl <- shiny::getShinyOption("cohortOperationsConfig")$atlasUrl

    rowCallback <- c(
      "function(row, data){",
      "  for(var i=0; i<data.length; i++){",
      "    if(data[i] === null){",
      "      $('td:eq('+i+')', row).html('NA')",
      "        .css({'color': 'rgb(226,44,41)', 'font-style': 'italic'});",
      "    }",
      "  }",
      "}"
    )

    output$codeWAStable <- DT::renderDataTable({

      # https://github.com/rstudio/DT/issues/1127
      # the bug can be worked around by setting shiny.json.digits to a smaller value
      options(shiny.json.digits = 4)

      codeWASData <- analysisResultsHandler$tbl('codewas_results') |>
        dplyr::left_join(analysisResultsHandler$tbl('covariate_ref'), by = c('covariate_id' = 'covariate_id'))  |>
        dplyr::left_join(analysisResultsHandler$tbl('analysis_ref'), by = c('analysis_id' = 'analysis_id')) |>
        dplyr:::select(-c('is_binary', 'missing_means_zero')) |>
        dplyr::arrange(p_value) |>
        tibble::as_tibble()

      DT::datatable(
        codeWASData |>
          dplyr::mutate(p_value = as.numeric(formatC(p_value, format = "e", digits = 2))) |>
          dplyr::mutate(odds_ratio = as.numeric(formatC(odds_ratio, format = "e", digits = 2))) |>
          dplyr::mutate(beta = as.numeric(formatC(beta, format = "e", digits = 2))) |>
          dplyr::mutate(standard_error = as.numeric(formatC(standard_error, format = "e", digits = 2))),
        colnames = c(
          'DB id' = 'database_id',
          'Cov. ID' = 'covariate_id',
          'N tot' = 'n_total',
          'N case' = 'n_cases',
          'N ctrl' = 'n_controls',
          'p' = 'p_value',
          'OR' = 'odds_ratio',
          'Beta' = 'beta',
          'SE' = 'standard_error',
          'Model' = 'model_type',
          'Notes' = 'run_notes',
          'Cov. name' = 'covariate_name',
          'Analysis ID' = 'analysis_id',
          'Concept ID' = 'concept_id',
          'Analysis name' = 'analysis_name',
          'Domain' = 'domain_id' #,
          # 'Binary' = 'is_binary',
          # 'Missing mean zero' = 'missing_means_zero'
        ),
        filter = list(position = 'top', clear = FALSE),
        options = list(
          rowCallback = htmlwidgets::JS(rowCallback),
          autoWidth = TRUE,
          order = list(list(6, 'asc')),
          scrollX = TRUE,
          columnDefs = list(
            list(width = '45px', targets = c(1:5,7,8,9,10,13,14)),
            list(width = '50px', targets = c(6))
          ),
          pageLength = 10,
          lengthMenu = c(10, 15, 20, 25, 50)
        )
      )
    })

    output$codeWASPlot <- shiny::renderPlot({
      codeWASData <- analysisResultsHandler$tbl('codewas_results') |>
        dplyr::left_join(analysisResultsHandler$tbl('covariate_ref'), by = c('covariate_id' = 'covariate_id'))  |>
        dplyr::left_join(analysisResultsHandler$tbl('analysis_ref'), by = c('analysis_id' = 'analysis_id')) |>
        dplyr:::select(-c('is_binary', 'missing_means_zero')) |>
        dplyr::arrange(p_value, covariate_name, analysis_name) |>
        dplyr::select(p_value, covariate_name, analysis_name) |>
        tibble::as_tibble()

      codeWASData <- codeWASData |>
        dplyr::mutate(analysis_num = as.numeric(base::factor(analysis_name))) |>
        dplyr::mutate(covariate_name = as.numeric(base::factor(covariate_name))) |>
        tidyr::drop_na()
    })


  })
}

















