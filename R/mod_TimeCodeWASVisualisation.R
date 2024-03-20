#
# UI
#

mod_timeCodeWASVisualization_ui <- function(id) {
  ns <- shiny::NS(id)

  headerContent <- tags$li(
    class = "dropdown",
    style = "margin-top: 8px !important; margin-right : 5px !important"
  )

  header <-
    shinydashboard::dashboardHeader(title = "TimeCodeWAS", headerContent)

  sidebarMenu <-
    shinydashboard::sidebarMenu(
      id = ns("tabs"),
      shinydashboard::menuItem(text = "About", tabName = "about", icon = shiny::icon("code")),
      shinydashboard::menuItem(text = "Cohort Definition", tabName = "cohortDefinition", icon = shiny::icon("code")),
      shinydashboard::menuItem(text = "TimeCodeWas", tabName = "timeCodeWAS", icon = shiny::icon("table"))#,
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
      HTML("aboutText")
    ),
    shinydashboard::tabItem(
      tabName = "cohortDefinition",
      OhdsiShinyModules::cohortDefinitionsView(ns("cohortDefinitions"))
    ),
    shinydashboard::tabItem(
      tabName = "timeCodeWAS",
      mod_timeCodeWASPlot_ui(ns("timeCodeWAS"))
    )
  )

  # body
  body <- shinydashboard::dashboardBody(
    bodyTabItems
  )

  # main
  ui <- shinydashboard::dashboardPage(
    tags$head(tags$style(HTML(
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

mod_timeCodeWASVisualization_server <- function(id, connectionHandler, resultDatabaseSettings) {



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


    mod_timeCodeWASPlot_server("timeCodeWAS", connectionHandler)


  })


}


































