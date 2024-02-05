#' The application server-side
#'
#' @param input,output,session Internal parameters for {shiny}.
#'     DO NOT REMOVE.
#' @import shiny
#' @noRd
app_server <- function(input, output, session) {

  # reactive values, starting with "r_"
  r <- shiny::reactiveValues(
    pathToResultsFolder = NULL,
    analysisSettings = NULL,
    analysisResults = NULL
  )


  # Retrieve path from the URL and copy them to r$pathToResultsZip
  shiny::observe({
    query <- shiny::parseQueryString(session$clientData$url_search)
    value <- query[['pathToResultsZip']]
    if (!is.null(value)) {
      r$pathToResultsZip <- value
    }
  })

  # if r$pathToResultsZip was not given by the URL, then show a modal to ask for it
  shiny::observe({
    # r$pathToResultsZip

    if (is.null(r$pathToResultsZip)) {

      shiny::showModal(shiny::modalDialog(
        title = "No results loaded",
        footer = NULL,
        easyClose = FALSE,
        #
        "Please load an results first.",
        shiny::fileInput("loadedFile", "Choose a zip file with an analysis resutls", accept = c(".zip"))
      ))

    }
  })

  # load results and unzip to r$pathToResultsZip
  shiny::observeEvent(input$loadedFile, {

    analysisSettings <- NULL
    tempFolder <- NULL

    # make sure the file is a zip
    if(!grepl(".zip$", input$loadedFile$name)){
      shinyWidgets::sendSweetAlert(
        session = session,
        title = "Error",
        text = "The file is not a zip",
        type = "error"
      )
      shinyjs::reset("loadedFile")
      return()
    }

    # create temp file with current dattime
    tempFolder <- paste0(tempfile(), "_", format(Sys.time(), "%Y%m%d_%H%M%S"))
    dir.create(tempFolder)

    # unzip results to temp folder
    unzip(input$loadedFile$datapath, exdir = tempFolder)

    # make sure there is a file "analysisSettings.yalm"
    if(is.character(checkmate::checkFileExists(file.path(tempFolder, "analysisSettings.yaml")))){
      shinyWidgets::sendSweetAlert(
        session = session,
        title = "Error",
        text = "analysisSettings.yml not found in the zip file",
        type = "error"
      )
      shinyjs::reset("loadedFile")
      return()
    }
    analysisSettings <- yaml::read_yaml(file.path(tempFolder, "analysisSettings.yaml"))

    # make sure the yaml file has field "analysisType"
    if(is.character(checkmate::checkCharacter(analysisSettings$analysisType))){
      shinyWidgets::sendSweetAlert(
        session = session,
        title = "Error",
        text = "analysisSettings.yml does not have field 'analysisType'",
        type = "error"
      )
      shinyjs::reset("loadedFile")
      return()
    }


    # copy results
    r$analysisSettings <- analysisSettings
    r$pathToResultsFolder <- tempFolder

  })

  ## based on analysis type, validate the contents of the zip file
  shiny::observe({
    shiny::req(r$pathToResultsFolder)
    shiny::req(r$analysisSettings)

    analysisResults <- NULL

    #
    # cohortDiagnostics
    #
    if(r$analysisSettings$analysisType == "cohortDiagnostics"){

      # make sure there is a file "analysisResults.sqlite"
      if(is.character(checkmate::checkFileExists(file.path(r$pathToResultsFolder, "analysisResults.sqlite")))){
        shinyWidgets::sendSweetAlert(
          session = session,
          title = "Error",
          text = "analysisResults.sqlite not found in the zip file",
          type = "error"
        )
        shinyjs::reset("loadedFile")
        return()
      }else{
        # copy results
        analysisResults <- .analysisResultsFromCohortDiagnosticsSqlitePath(file.path(r$pathToResultsFolder, "analysisResults.sqlite"))
      }

    }


    #
    # timeCodeWAS
    #
    if(r$analysisSettings$analysisType == "timeCodeWAS"){

    }

    #
    # none
    #
    if(is.null(analysisResults)){
      shinyWidgets::sendSweetAlert(
        session = session,
        title = "Error",
        text = paste0("There is not analysis visualisation for the selected analysis type: ", r$analysisSettings$analysisType),
        type = "error"
      )
      shinyjs::reset("loadedFile")
      return()
    }

    r$analysisResults <- analysisResults

  } )


  ## based on r$analysisResults, load module ui
  shiny::observe({
    shiny::req(r$analysisSettings)
    shiny::req(r$analysisResults)
browser()
    #
    # cohortDiagnostics
    #
    if(r$analysisSettings$analysisType == "cohortDiagnostics"){
      ui <- mod_cohortDiagnosticsVisualization_ui("cohortDiagnosticsVisualization", r$analysisResults)
    }

    #
    # timeCodeWAS
    #
    if(r$analysisSettings$analysisType == "timeCodeWAS"){

    }

    # close modal
    shiny::removeModal()

    # load module ui
    shiny::removeUI(
      selector = "#divToBeReplaced",
      immediate = TRUE
    )
    shiny::insertUI(
      selector = "#hidenButton",
      where = "afterEnd",
      ui = ui
    )

    # trigger button on flushed
    shiny::onFlushed(function (){
      shinyjs::runjs('$(".wrapper").css("height", "auto");')
      shinyjs::runjs('$(".shiny-spinner-placeholder").hide();')
      shinyjs::runjs('$(".load-container.shiny-spinner-hidden.load1").hide();')
      shinyjs::runjs('$("#hidenButton").click();')
    })

  })



  # when the button is licked after flushed, load the module server, based on the analysis type
  shiny::observeEvent(input$hidenButton,{
    shiny::req(r$analysisSettings)
    shiny::req(r$analysisResults)

    #
    # cohortDiagnostics
    #
    if(r$analysisSettings$analysisType == "cohortDiagnostics"){
      mod_cohortDiagnosticsVisualization_server("cohortDiagnosticsVisualization", r$analysisResults)
    }

    #
    # timeCodeWAS
    #
    if(r$analysisSettings$analysisType == "timeCodeWAS"){

    }
  })



}



.analysisResultsFromCohortDiagnosticsSqlitePath <- function(cohortDiagnosticsSqlitePath) {

  checkmate::assertFile(cohortDiagnosticsSqlitePath)

  connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = "sqlite", server = cohortDiagnosticsSqlitePath)

  shinySettings <- list(
    connectionDetails = connectionDetails,
    resultsDatabaseSchema = c("main"),
    vocabularyDatabaseSchema = c("main"),
    aboutText = NULL,
    tablePrefix = "",
    cohortTableName = "cohort",
    databaseTableName = "database",
    enableAnnotation = TRUE,
    enableAuthorization = FALSE
  )

  connectionHandler <- ResultModelManager::PooledConnectionHandler$new(shinySettings$connectionDetails)

  resultDatabaseSettings <- list(
    schema = shinySettings$resultsDatabaseSchema,
    vocabularyDatabaseSchema = shinySettings$vocabularyDatabaseSchema,
    cdTablePrefix = shinySettings$tablePrefix,
    cgTable = shinySettings$cohortTableName,
    databaseTable = shinySettings$databaseTableName
  )

  dataSource <-
    OhdsiShinyModules::createCdDatabaseDataSource(connectionHandler = connectionHandler,
                                                  resultDatabaseSettings = resultDatabaseSettings)


  analysisResults <- list(
    connectionHandler = connectionHandler,
    dataSource = dataSource,
    resultDatabaseSettings = shinySettings
  )

  return(analysisResults)

}


