#' The application User-Interface
#'
#' @param request Internal parameter for `{shiny}`.
#'     DO NOT REMOVE.
#' @import shiny
#' @noRd
app_ui <- function(request) {
  shiny::tagList(
    shinyjs::useShinyjs(),
    # hidden button triggered when the new module-ui is flushed to call the module-server
    # also serves as reference to insert the new module-ui under it
    shinyjs::hidden(
      shiny::actionButton("hidenButton", "hidenButton")
    ),
    # this is replace when a new ui us loaded
    shiny::div(
      id = "divToBeReplaced",
      shinydashboard::dashboardPage(
        # TITLE
        shinydashboard::dashboardHeader(title = "CO Viewer"),
        ## SIDEBAR
        shinydashboard::dashboardSidebar(
          shinydashboard::sidebarMenu(
            shinydashboard::menuItem("About", tabName = "about", icon = shiny::icon("info"))
          )
        ),
        ## BODY
        shinydashboard::dashboardBody(
          shinydashboard::tabItems(
            shinydashboard::tabItem(
              tabName = "about",
              shinydashboard::box(
                  title = "About",
                  shiny::uiOutput("about"),
                  width = 12
              )
            )
          )
        )
      )
    )
  )

}
