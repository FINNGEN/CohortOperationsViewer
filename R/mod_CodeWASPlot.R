#
# UI
#

mod_codeWASPlot_ui <- function(id) {
  ns <- shiny::NS(id)

  htmltools::tagList(
    htmltools::h4("CodeWAS Results"),
    shiny::div(
      style = "margin-top: 10px; margin-bottom: 20px;",
      # shiny::tags$em("CodeWAS results are displayed below. The table is sorted by p-value in ascending order."),
      shiny::textOutput(ns("total_n")),

    ),
    DT::dataTableOutput(ns("codeWAStable")),
    shiny::downloadButton(ns("downloadCodeWAS"), "Download CodeWAS results", icon = icon("download"))
  )

}

#
# server
#

mod_codeWASPlot_server <- function(id, analysisResultsHandler) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

    atlasUrl <- shiny::getShinyOption("cohortOperationsConfig")$atlasUrl

    output$total_n <- shiny::renderText({
      shiny::req(r$codeWASData)
      paste("Total N: ", dplyr::first(r$codeWASData$n_total))
    })

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

    # reactive values
    r <- shiny::reactiveValues(
      codeWASData = NULL
    )

    shiny::observe({
      r$codeWASData <- analysisResultsHandler$tbl('codewas_results') |>
        dplyr::left_join(analysisResultsHandler$tbl('covariate_ref'), by = c('covariate_id' = 'covariate_id'))  |>
        dplyr::left_join(analysisResultsHandler$tbl('analysis_ref'), by = c('analysis_id' = 'analysis_id')) |>
        dplyr::mutate(odds_ratio = ifelse(is.na(odds_ratio), exp(beta), odds_ratio)) |>
        dplyr:::select(-c('is_binary', 'missing_means_zero')) |>
        tibble::as_tibble()
    })

    output$codeWAStable <- DT::renderDataTable({
      req(r$codeWASData)

      # https://github.com/rstudio/DT/issues/1127
      # the bug can be worked around by setting shiny.json.digits to a smaller value
      options(shiny.json.digits = 4)

      DT::datatable(
        r$codeWASData |>
          dplyr::mutate(p_value = as.numeric(formatC(p_value, format = "e", digits = 2))) |>
          dplyr::mutate(odds_ratio = as.numeric(formatC(odds_ratio, format = "e", digits = 2))) |>
          dplyr::mutate(beta = as.numeric(formatC(beta, format = "e", digits = 2))) |>
          dplyr::mutate(standard_error = as.numeric(formatC(standard_error, format = "e", digits = 2))) |>
          dplyr::select(-n_total),
        colnames = c(
          'Database' = 'database_id',
          'Domain' = 'domain_id',
          'Analysis' = 'analysis_name',
          'Name' = 'covariate_name',
          'Concept ID' = 'concept_id',
          'Cov. ID' = 'covariate_id',
          # 'N tot' = 'n_total',
          'N case' = 'n_cases',
          'N ctrl' = 'n_controls',
          'p' = 'p_value',
          'OR' = 'odds_ratio',
          'Beta' = 'beta',
          'SE' = 'standard_error',
          'Model' = 'model_type',
          'Notes' = 'run_notes',
          'Analysis ID' = 'analysis_id',
          # 'Binary' = 'is_binary',
          # 'Missing mean zero' = 'missing_means_zero'
        ),
        filter = list(position = 'top', clear = FALSE),
        options = list(
          rowCallback = htmlwidgets::JS(rowCallback),
          autoWidth = TRUE,
          order = list(list(5, 'asc')), # p_value
          scrollX = TRUE,
          columnDefs = list(
            list(width = '45px', targets = c(1:4,7,8,9,10,12,13)),
            list(width = '50px', targets = c(5, 6)) # p_value, OR
          ),
          pageLength = 10,
          lengthMenu = c(10, 15, 20, 25, 50)
        )
      )
    })

    output$downloadCodeWAS <- downloadHandler(
      filename = function() {
        paste(Sys.time(), '_result.csv', sep='')
      },
      content = function(file) {
        write.csv(r$codeWASData, file, row.names = FALSE)
      }
    )

  })
}

















