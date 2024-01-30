
# load test results

path <- testthat::test_path("testdata", "test_TimeCodeWAS.zip")
tempDir <- tempdir()
unzip(path, exdir = tempDir)
studyResults <- readr::read_csv(file.path(tempDir, "cohortOperationsStudy", "results.csv"))


# run module --------------------------------------------------------------
devtools::load_all(".")

app <- shiny::shinyApp(
  shiny::fluidPage(
    mod_timeCodeWASVisualization_ui("test")
  ),
  function(input,output,session){
    mod_timeCodeWASVisualization_server("test", studyResults)
  },
  options = list(launch.browser=TRUE)
)

app
