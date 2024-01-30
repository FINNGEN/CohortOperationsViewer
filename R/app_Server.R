#' The application server-side
#'
#' @param input,output,session Internal parameters for {shiny}.
#'     DO NOT REMOVE.
#' @import shiny
#' @noRd
app_server <- function(input, output, session) {
  # Your application server logic

  # get settings loaded from file
  # configurationList <- shiny::getShinyOption("configurationList")


  r <- shiny::reactiveValues(
    analysis = NULL
  )

  # if analysis is null show modal
  shiny::observe({
    if (is.null(r$analysis)) {
      shiny::showModal(shiny::modalDialog(
        title = "No analysis loaded",
        footer = NULL,
        easyClose = FALSE,
        #
        "Please load an analysis first.",
        shiny::fileInput("loadedFile", "Choose file to upload", accept = c(".zip"))
      ))
    }else{
      output$cohortsTable <- shiny::renderDataTable({
        r$analysis$cohortsSummary
      })
      output$studySettings_text <- shiny::renderText({
        yaml::as.yaml(r$analysis$studySettings)
      })
      output$results_uiOutput <- shiny::renderUI({
        # render visualization for timeCodeWAS
        if (r$analysis$studySettings$studyType == "timeCodeWAS") {
          studyResults <- r$analysis$results
          mod_timeCodeWASVisualization_server("timeCodeWASVisualization", studyResults)
          mod_timeCodeWASVisualization_ui("timeCodeWASVisualization")
        }
      })
    }
  })

  # load analysis
  shiny::observeEvent(input$loadedFile, {

    # TODO check file is has valid contents
    ## is a zip file
    shiny::validate(
      shiny::need(tools::file_ext(input$loadedFile$datapath) == "zip", "Please select a zip file")
    )
    ## contains analysis.rds

    # unzip file
    tempDir <- tempdir()
    unzip(input$loadedFile$datapath, exdir = tempDir)

    # load analysis
    analysis <-  list(
      cohortsSummary = readr::read_csv(file.path(tempDir, "cohortOperationsStudy", "cohortsSummary.csv")),
      studySettings = yaml::read_yaml(file.path(tempDir,"cohortOperationsStudy",  "studySettings.yaml")),
      results = readr::read_csv(file.path(tempDir, "cohortOperationsStudy", "results.csv"))
    )

    # copy analysis to reactive values
    r$analysis <- analysis

    # close modal
    shiny::removeModal()


  })


}
