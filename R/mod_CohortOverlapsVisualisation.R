#
# UI
#

mod_cohortOverlapsVisualization_ui <- function(id) {
  ns <- shiny::NS(id)

  headerContent <- shiny::tags$li(
    class = "dropdown",
    style = "margin-top: 8px !important; margin-right : 5px !important"
  )

  header <-
    shinydashboard::dashboardHeader(title = "cohortOverlaps", headerContent)

  sidebarMenu <-
    shinydashboard::sidebarMenu(
      id = ns("tabs"),
      shinydashboard::menuItem(text = "About", tabName = "about", icon = shiny::icon("code")),
      shinydashboard::menuItem(text = "Cohort Definition", tabName = "cohortDefinition", icon = shiny::icon("code")),
      shinydashboard::menuItem(text = "cohortOverlaps", tabName = "cohortOverlaps", icon = shiny::icon("table"))#,
      #shinydashboard::menuItem(text = "Meta data", tabName = "databaseInformation", icon = shiny::icon("gear", verify_fa = FALSE))
    )

  # Side bar code
  sidebar <-
    shinydashboard::dashboardSidebar(sidebarMenu,
                                     width = NULL,
                                     collapsed = FALSE
    )

  bodyTabItems <- shinydashboard::tabItems(
    shinydashboard::tabItem(
      tabName = "about",
      htmltools::HTML("aboutText")
    ),
    shinydashboard::tabItem(
      tabName = "cohortDefinition",
      OhdsiShinyModules::cohortDefinitionsView(ns("cohortDefinitions"))
    ),
    shinydashboard::tabItem(
      tabName = "cohortOverlaps",
      mod_cohortOverlapsPlot_ui(ns("cohortOverlaps"))
    )
  )

  # body
  body <- shinydashboard::dashboardBody(
    bodyTabItems
  )

  # main
  ui <- shinydashboard::dashboardPage(
    shiny::tags$head(shiny::tags$style(htmltools::HTML(
      "
        th, td {
          padding-right: 10px;
        }

      "
    ))),
    header = header,
    sidebar = sidebar,
    body = body
  )

  return(ui)

}


#
# server
#

mod_cohortOverlapsVisualization_server <- function(id, connectionHandler, resultDatabaseSettings) {

  #TEMP cd is trying to migrtate a table that dont exist
  #insert it

  connection <- connectionHandler$getConnection()
  temporal_time_ref  <- tibble::tibble(
    time_id = 1:10,
    time_value = 1:10
  )
  DatabaseConnector::dbCreateTable(
    connection,  "temporal_time_ref", temporal_time_ref, temporary = FALSE
  )

  dataSource <-
    OhdsiShinyModules::createCdDatabaseDataSource(connectionHandler = connectionHandler,
                                                  resultDatabaseSettings = resultDatabaseSettings)







  shiny::moduleServer(id, function(input, output, session) {

    cohortDefinitions <- shiny::reactive({
      OhdsiShinyModules:::getCohortTable(dataSource) |> dplyr::arrange(.data$cohortId)
    })

    OhdsiShinyModules:::cohortDefinitionsModule(
      id = "cohortDefinitions",
      dataSource,
      cohortDefinitions = cohortDefinitions
    )


    mod_cohortOverlapsPlot_server("cohortOverlaps", connectionHandler)


  })


}


































