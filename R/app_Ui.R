#' The application User-Interface
#'
#' @param request Internal parameter for `{shiny}`.
#'     DO NOT REMOVE.
#' @import shiny
#' @noRd
app_ui <- function(request) {
  shiny::tagList(

    # Your application UI logic
    shinydashboard::dashboardPage(

      # TITLE
      shinydashboard::dashboardHeader(title = "Cohort Operations Viewer"),

      ## SIDEBAR
      shinydashboard::dashboardSidebar(
        shinydashboard::sidebarMenu(
          # download current analysis
          shiny::downloadButton("downloadAnalysis", "Download current analysis")
        )
      ),

      ## BODY
      shinydashboard::dashboardBody(
        # cohorts table
        shinydashboard::box(
          title = "Cohorts",
          status = "primary",
          solidHeader = TRUE,
          width = 6,
          shiny::dataTableOutput("cohortsTable")
        ),
        # study settings
        shinydashboard::box(
          title = "Study Settings",
          status = "primary",
          solidHeader = TRUE,
          width = 6,
          shiny::verbatimTextOutput("studySettings_text")
        ),
        # restults
        shinydashboard::box(
          title = "Results",
          status = "primary",
          solidHeader = TRUE,
          width = 12,
          shiny::uiOutput("results_uiOutput")
        )
      )
    )
  )
}
