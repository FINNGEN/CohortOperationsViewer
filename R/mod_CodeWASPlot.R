#
# UI
#

mod_codeWASPlot_ui <- function(id) {
  ns <- shiny::NS(id)

  htmltools::tagList(
    reactable::reactableOutput(ns("tmp_codeWAStable"))
  )

}


#
# server
#

mod_codeWASPlot_server <- function(id, analysisResultsHandler) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

    atlasUrl <- shiny::getShinyOption("cohortOperationsConfig")$atlasUrl


    output$tmp_codeWAStable <- reactable::renderReactable({
      codeWASData <- analysisResultsHandler$tbl('codewas_results') |>
        dplyr::left_join(analysisResultsHandler$tbl('covariate_ref'), by = c('covariate_id' = 'covariate_id'))  |>
        dplyr::left_join(analysisResultsHandler$tbl('analysis_ref'), by = c('analysis_id' = 'analysis_id')) |>
        tibble::as_tibble()
      reactable::reactable(codeWASData)
    })

  })
}

















