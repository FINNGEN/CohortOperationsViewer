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
    sqliteDbPath = NULL
  )


  # Retrieve parameters from the URL and copy them to r$sqliteDbPath
  shiny::observe({
    query <- shiny::parseQueryString(session$clientData$url_search)
    value <- query[['sqliteDbPath']]
    if (!is.null(value)) {
      r$sqliteDbPath <- value
    }
  })

  # if results is null show modal
   shiny::observe({
     # r$results

    if (is.null(r$sqliteDbPath)) {

      shiny::showModal(shiny::modalDialog(
        title = "No results loaded",
        footer = NULL,
        easyClose = FALSE,
        #
        "Please load an results first.",
        shiny::fileInput("loadedFile", "Choose sqlite to upload", accept = c(".sqlite"))
      ))

    }else{
      browser()
         # render visualization for timeCodeWAS
        if (TRUE) {
          sqliteDbPath <- r$sqliteDbPath

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


          # source file ui.R inside inst package CohortDiagnostics
          newui <- source(system.file("shiny", "DiagnosticsExplorer", "ui.R", package = "CohortDiagnostics"), local = TRUE)

        }
        # render visualization for timeCodeWAS
        # if (r$results$studyType == "timeCodeWAS") {
        #   # studyResults <- r$results$results
        #   # mod_timeCodeWASVisualization_server("timeCodeWASVisualization", studyResults)
        #   # mod_timeCodeWASVisualization_ui("timeCodeWASVisualization")
        # }



        shiny::removeUI(
          selector = "#placeholder",
          immediate = TRUE
        )
browser()
        shiny::insertUI(
          selector = "#add",
          where = "afterEnd",
          ui = newui$value
        )


        shiny::onFlushed(function (){
          shinyjs::runjs('$(".wrapper").css("height", "auto");')
          shinyjs::runjs('$(".shiny-spinner-placeholder").hide();')
          shinyjs::runjs('$(".load-container.shiny-spinner-hidden.load1").hide();')
          shinyjs::runjs('$("#add").click();')
        })
      }

     })

   shiny::observeEvent(input$add,{
     # if (!is.null(r$pass)) {

       sqliteDbPath <- r$sqliteDbPath

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


       OhdsiShinyModules::cohortDiagnosticsServer(
         id = "DiagnosticsExplorer",
         connectionHandler = connectionHandler,
         dataSource = dataSource,
         resultDatabaseSettings = shinySettings
       )
     # }
   })

  # load results
  shiny::observeEvent(input$loadedFile, {

    # TODO check file is has valid contents
    ## is a zip file
    shiny::validate(
      shiny::need(tools::file_ext(input$loadedFile$datapath) == "sqlite", "Please select a zip file")
    )

    # load results
    results <-  list(
      studyType= "cohortDiagnostics",
      sqliteDbPath = input$loadedFile$datapath
    )

    # copy results to reactive values
    r$results <- results

    # close modal
    shiny::removeModal()


  })


}
