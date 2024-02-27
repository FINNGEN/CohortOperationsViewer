#' The application server-side
#'
#' @param input,output,session Internal parameters for {shiny}.
#'     DO NOT REMOVE.
#' @import shiny
#' @noRd
app_server <- function(input, output, session) {

  # reactive values, starting with "r_"
  r <- shiny::reactiveValues(
    pathToResultsZip = NULL,
    analysisSettings = NULL,
    analysisResultsHandlerHandler = NULL
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

    r$pathToResultsZip <- input$loadedFile$datapath

  })

  shiny::observeEvent(r$pathToResultsZip, {

    analysisSettings <- NULL

    # create temp file with current dattime
    tempFolderTime <- paste0(tempfile(), "_", format(Sys.time(), "%Y%m%d_%H%M%S"))
    dir.create(tempFolderTime)

    # make sure there is a file "analysisSettings.yalm"
    if( !("analysisSettings.yaml" %in% zip::zip_list(r$pathToResultsZip)$filename )){
      shinyWidgets::sendSweetAlert(
        session = session,
        title = "Error",
        text = "analysisSettings.yml not found in the zip file",
        type = "error"
      )
      shinyjs::reset("loadedFile")
      return()
    }
    zip::unzip(r$pathToResultsZip, exdir = tempFolderTime, files = "analysisSettings.yaml")
    analysisSettings <- yaml::read_yaml(file.path(tempFolderTime, "analysisSettings.yaml"))

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

  })

  ## based on analysis type, validate the contents of the zip file
  shiny::observe({
    shiny::req(r$pathToResultsZip)
    shiny::req(r$analysisSettings)

    analysisResultsHandler <- NULL

    sweetAlert_spinner(paste0("Loading ", r$analysisSettings$analysisType, " analysis results..."))

    #
    # cohortDiagnostics
    #
    if(r$analysisSettings$analysisType == "cohortDiagnostics"){
      analysisResultsHandler <- .zipToCohortDiagnosticsData(r$pathToResultsZip)
    }

    #
    # timeCodeWAS
    #
    if(r$analysisSettings$analysisType == "timeCodeWAS"){
      analysisResultsHandler <- .zipToConnectionHandled(r$pathToResultsZip)
    }

    #
    # none
    #
    if(is.null(analysisResultsHandler)){
      shinyWidgets::sendSweetAlert(
        session = session,
        title = "Error",
        text = paste0("There is not analysis visualisation for the selected analysis type: ", r$analysisSettings$analysisType),
        type = "error"
      )
      shinyjs::reset("loadedFile")
      return()
    }

    remove_sweetAlert_spinner()

    r$analysisResultsHandler <- analysisResultsHandler

  } )


  ## based on r$analysisResultsHandler, load module ui
  shiny::observe({
    shiny::req(r$analysisSettings)
    shiny::req(r$analysisResultsHandler)

    #
    # cohortDiagnostics
    #
    if(r$analysisSettings$analysisType == "cohortDiagnostics"){
      ui <- mod_cohortDiagnosticsVisualization_ui("cohortDiagnosticsVisualization", r$analysisResultsHandler)
    }

    #
    # timeCodeWAS
    #
    if(r$analysisSettings$analysisType == "timeCodeWAS"){
     ui <- mod_timeCodeWASVisualization_ui("timeCodeWASVisualization")
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



  # when the button is clicked after flushed, load the module server, based on the analysis type
  shiny::observeEvent(input$hidenButton,{
    shiny::req(r$analysisSettings)
    shiny::req(r$analysisResultsHandler)

    #
    # cohortDiagnostics
    #
    if(r$analysisSettings$analysisType == "cohortDiagnostics"){
      mod_cohortDiagnosticsVisualization_server("cohortDiagnosticsVisualization", r$analysisResultsHandler)
    }

    #
    # timeCodeWAS
    #
    if(r$analysisSettings$analysisType == "timeCodeWAS"){
      mod_timeCodeWASVisualization_server("timeCodeWASVisualization", r$analysisResultsHandler)
    }
  })


  output$about <- shiny::renderUI({
    # load news from shinyoption pathtomd

    shiny::div(
      shiny::markdown(readLines(shiny::getShinyOption("pathToNews"))),
      shiny::br(),
      shiny::p(shiny::getShinyOption("gitInfo"))
    )

  })



}



.zipToCohortDiagnosticsData <- function(pathToResultsZip) {

  tempFolderTime <-  paste0(tempfile(), "_", format(Sys.time(), "%Y%m%d_%H%M%S"))
  dir.create(tempFolderTime)

  sqliteDbPath <- file.path(tempFolderTime, "analysisResults.sqlite")

  # if there is a file "analysisResults.sqlite" in the zip, then use it
  if("analysisResults.sqlite" %in% zip::zip_list(pathToResultsZip)$filename){
    zip::unzip(pathToResultsZip, exdir = tempFolderTime, files = "analysisResults.sqlite")
  }else{
    CohortDiagnostics::createMergedResultsFile(
      dataFolder = pathToResultsZip  |> dirname(),
      sqliteDbPath = sqliteDbPath,
      overwrite = TRUE
    )
  }

  connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = "sqlite", server = sqliteDbPath)

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


  analysisResultsHandler <- list(
    connectionHandler = connectionHandler,
    dataSource = dataSource,
    resultDatabaseSettings = shinySettings
  )

  return(analysisResultsHandler)

}


.zipToConnectionHandled <- function(pathToResultsZip) {

  tempFolderTime <-  paste0(tempfile(), "_", format(Sys.time(), "%Y%m%d_%H%M%S"))
  dir.create(tempFolderTime)
  sqliteDbPath <- file.path(tempFolderTime, "analysisResults.sqlite")

  # if there is a file "analysisResults.sqlite" in the zip, then use it
  if("analysisResults.sqlite" %in% zip::zip_list(pathToResultsZip)$filename){
    zip::unzip(pathToResultsZip, exdir = tempFolderTime, files = "analysisResults.sqlite")
  }else{
    ResultModelManager::unzipResults(
      zipFile = pathToResultsZip,
      resultsFolder = tempFolderTime
    )

    HadesExtras::csvFilesToSqlite(
      dataFolder = tempFolderTime,
      sqliteDbPath = sqliteDbPath,
      overwrite = TRUE
    )
  }

  analysisResultsHandler  <- ResultModelManager::ConnectionHandler$new(
    connectionDetails = DatabaseConnector::createConnectionDetails(
      dbms = "sqlite",
      server = sqliteDbPath
    )
  )

  return(analysisResultsHandler)
}


