
# load test results
devtools::load_all(".")

pathToZip <- testthat::test_path("testdata", "cohortDemographics", "eunomia_asthmaVSasthmaControls_cohortDemographics.zip")
pathToZip <- testthat::test_path("testdata", "cohortDemographics", "eunomia_colecixubVSmatchedALL_cohortDemographics.zip")

analysisResultsHandler <- .zipToConnectionHandled(pathToZip)

# viewer configuration
shinySettings <- list(
  resultsDatabaseSchema = c("main"),
  vocabularyDatabaseSchema = c("main"),
  aboutText = NULL,
  tablePrefix = "",
  cohortTableName = "cohort",
  databaseTableName = "database",
  enableAnnotation = TRUE,
  enableAuthorization = FALSE
)

resultDatabaseSettings <- list(
  schema = shinySettings$resultsDatabaseSchema,
  vocabularyDatabaseSchema = shinySettings$vocabularyDatabaseSchema,
  cdTablePrefix = shinySettings$tablePrefix,
  cgTable = shinySettings$cohortTableName,
  databaseTable = shinySettings$databaseTableName
)



# run module --------------------------------------------------------------
devtools::load_all(".")

app <- shiny::shinyApp(
  shiny::fluidPage(
    mod_cohortDemographicsVisualization_ui("test")
  ),
  function(input,output,session){
    mod_cohortDemographicsVisualization_server("test", analysisResultsHandler, resultDatabaseSettings)
  },
  options = list(launch.browser=TRUE)
)

app
