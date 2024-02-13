
# load test results

pathToZip <- testthat::test_path("testdata", "analysisName_cohortDiagnostics(3).zip")

analysisResultsHandler <- .zipToConnectionHandled(pathToZip)



# run module --------------------------------------------------------------
devtools::load_all(".")

app <- shiny::shinyApp(
  shiny::fluidPage(
    mod_timeCodeWASVisualization_ui("test")
  ),
  function(input,output,session){
    mod_timeCodeWASVisualization_server("test", analysisResultsHandler)
  },
  options = list(launch.browser=TRUE)
)

app
