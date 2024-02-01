#' The application User-Interface
#'
#' @param request Internal parameter for `{shiny}`.
#'     DO NOT REMOVE.
#' @import shiny
#' @noRd
app_ui <- function(request) {



  shiny::tagList(
    shinyjs::useShinyjs(),
    shinyjs::hidden(
      shiny::actionButton("add", "Add UI")
    ),
    shiny::div(
      id = "placeholder",
      shinydashboard::dashboardPage(
        # TITLE
        shinydashboard::dashboardHeader(title = "CO Viewer"),
        ## SIDEBAR
        shinydashboard::dashboardSidebar( ),
        ## BODY
        shinydashboard::dashboardBody()
      )
    )
  )
}
