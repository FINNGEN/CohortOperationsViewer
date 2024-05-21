#
# UI
#

mod_cohortDemographicsPlot_ui <- function(id) {
  ns <- shiny::NS(id)

  htmltools::tagList(
    reactable::reactableOutput(ns("tmp_cohortDemographicstable"))
  )

}


#
# server
#

mod_cohortDemographicsPlot_server <- function(id, analysisResultsHandler) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns



    output$tmp_cohortDemographicstable <- reactable::renderReactable({
      cohortDemographicsData <- analysisResultsHandler$tbl('demographics_counts') |>
        tibble::as_tibble()
      reactable::reactable(cohortDemographicsData)
    })

  })
}
