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
    pathToResultsFolder = NULL,
    analisysSettings = NULL,
    analisysResults = NULL
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
        shiny::fileInput("loadedFile", "Choose sqlite to upload", accept = c(".sqlite"))
      ))

    }
  })

  # load results and copy path to r$pathToResultsZip
  shiny::observeEvent(input$loadedFile, {

    ## is a zip file
    shiny::validate(
      shiny::need(tools::file_ext(input$loadedFile$datapath) == "zip", "Please select a zip file")
    )

    # copy results to reactive values
    r$pathToResultsZip <- input$loadedFile$datapath

    # close modal
    shiny::removeModal()

  })

  ## check contents of the zip file and find the analysis type
  shiny::observe({
    shiny::req(r$pathToResultsZip)

    analisysSettings <- NULL

    # create temp file with current dattime
    tempFolder <- paste0(tempfile(), "_", format(Sys.time(), "%Y%m%d_%H%M%S"))
    dir.create(tempFolder)

    # unzip results to temp folder
    unzip(r$pathToResultsZip, exdir = tempFolder)

    # make sure there is a file "analisysSettings.yalm"
    if(!checkmate::checkFileExists(file.path(tempFolder, "analisysSettings.yml"))){
      shinyWidgets::sendSweetAlert(
        session = session,
        title = "Error",
        text = "analisysSettings.yml not found in the zip file",
        type = "error"
      )
    }else{
      # read yalm file
      analisysSettings <- yaml::read_yaml(file.path(tempFolder, "analisysSettings.yml"))

      # make sure the yaml file has field "analysisType"
      if(!checkmate::checkCharacter(analisysSettings$analysisType)){
        shinyWidgets::sendSweetAlert(
          session = session,
          title = "Error",
          text = "analisysSettings.yml does not have field 'analysisType'",
          type = "error"
        )
      }
    }



    # copy results
    r$analisysSettings <- analisysSettings
    r$pathToResultsFolder <- tempFolder

  })

  ## based on analysis type, validate the contents of the zip file
  shiny::observe({
    shiny::req(r$pathToResultsZip)
    shiny::req(r$analisysSettings)

    analisysResults <- NULL

    #
    # cohortDiagnostics
    #
    if(r$analisysSettings$analysisType == "cohortDiagnostics"){

      # make sure there is a file "analisysResults.sqlite"
      if(!checkmate::checkFileExists(file.path(r$pathToResultsFolder, "analisysResults.sqlite"))){
        shinyWidgets::sendSweetAlert(
          session = session,
          title = "Error",
          text = "analisysResults.sqlite not found in the zip file",
          type = "error"
        )
      }else{
        # copy results
        analisysResults <- .dataSourceFromCohortDiagnosticsSqlitePath(file.path(r$pathToResultsFolder, "analisysResults.sqlite"))
      }

    }


    #
    # timeCodeWAS
    #
    if(r$analisysSettings$analysisType == "timeCodeWAS"){

    }

    #
    # none
    #
    if(is.null(analisysResults)){
      shinyWidgets::sendSweetAlert(
        session = session,
        title = "Error",
        text = "There is not analysis visualisation for the selected analysis type",
        type = "error"
      )
    }

    r$analisysSettings <- analisysResults

  } )


  ## based on r$analysisResults, load module ui
  shiny::observe({
    shiny::req(r$analisysSettings)
    shiny::req(r$analisysResults)

    #
    # cohortDiagnostics
    #
    if(r$analisysSettings$analysisType == "cohortDiagnostics"){
      ui <- mod_cohortDiagnosticsVisualization_ui("cohortDiagnosticsVisualization", r$analisysResults)
    }

    #
    # timeCodeWAS
    #
    if(r$analisysSettings$analysisType == "timeCodeWAS"){

    }

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
    shiny::req(r$analisysSettings)
    shiny::req(r$analisysResults)

    #
    # cohortDiagnostics
    #
    if(r$analisysSettings$analysisType == "cohortDiagnostics"){
      mod_cohortDiagnosticsVisualization_server("cohortDiagnosticsVisualization", r$analisysResults)
    }

    #
    # timeCodeWAS
    #
    if(r$analisysSettings$analysisType == "timeCodeWAS"){

    }
  })



}
