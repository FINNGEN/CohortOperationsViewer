#
# UI
#

mod_cohortOverlapsPlot_ui <- function(id) {
  ns <- shiny::NS(id)

  htmltools::tagList(
    reactable::reactableOutput(ns("tmp_cohortOverlapstable"))
  )

}


#
# server
#

mod_cohortOverlapsPlot_server <- function(id, analysisResultsHandler) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

    atlasUrl <- shiny::getShinyOption("cohortOperationsConfig")$atlasUrl


    output$tmp_cohortOverlapstable <- reactable::renderReactable({
      cohortOverlapsData <- analysisResultsHandler$tbl('CohortOverlaps_results') |>
        tibble::as_tibble()
      reactable::reactable(cohortOverlapsData)
    })

  })
}
