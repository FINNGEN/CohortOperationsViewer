#' Run the Shiny Application
#'
#' @param ... arguments to pass to golem_opts.
#' See `?golem::get_golem_options` for more details.
#' @inheritParams shiny::shinyApp
#'
#' @export
#' @importFrom shiny shinyApp
#' @importFrom golem with_golem_options
run_app <- function(...) {

  # set up configuration
  # checkmate::assertFileExists(pathToCohortOperationsConfigYalm, extension = "yml")
  # configurationList <- yaml::read_yaml(pathToCohortOperationsConfigYalm)
  # checkmate::assertList(configurationList, names = "named")

  # set options
 options(shiny.maxRequestSize = 314572800)

  # set up logger
  # logger <- setup_ModalWithLog()

    app  <- shiny::shinyApp(
        ui = app_ui,
        server = app_server,
        ...
      )

    # setup shiny options
    # app$appOptions$configurationList  <- configurationList
    # app$appOptions$logger  <- logger

    return(app)
}
