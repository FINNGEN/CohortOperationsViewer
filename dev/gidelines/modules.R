#
# UI
#

mod_XXX_ui <- function(id) {
  ns <- shiny::NS(id)

  htmltools::tagList(
    # UI use functions, (eg. shinyjs::useShinyjs() )
    # UI logic
  )

}


#
# server
# - for the paramers passed to mod_XXX_server reactive parameters starting with "r_"
#

mod_XXX_server <- function(id, r_parameter_1, r_parameter_2, ...,  parameter_1, parameter_2, ...) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns


    # fixed values

    # reactive values, starting with "r_"

    # reactive blocs, shiny::observe, shiny::observeEvent, etc

    #
    # shiny::observe or output <- aaaa::renderOutput
    #
    shiny::observe({
      # list of reactive values that act as inputs for this block
      # - shiny::req(r_value$x or input$x)   : r_value_x triggers block if value exists and not be NULL and be true to continue execution
      # - r_value$y  : r_value_y triggers block if any change value can be null or false
      # - value_z <-shiny::isolate(r_value$z or input$z) : changes in r_value_z do not trigger this block

      # code block

      # list of reactive values that act as outputs for this block
      # - r_value$w or output$w <- value_w : r_value_w is updated with value_w and triggers block dependent on it


    })


    #
    # shiny::observeEvent
    #
    shiny::observeEvent(r_value$x or input$x, {
      # observeEvent only changes with r_value_x or input$x, so we don need to specify the other inputs

      # code block

      # list of reactive values that act as outputs for this block
      # - r_value$w or output$w <- value_w : r_value_w is updated with value_w and triggers block dependent on it
    })

    #
    # shiny::observe or output <- aaaa::renderOutput
    #
    output$x <- aaaa::renderOutput({
      # list of reactive values that act as inputs for this block
      # - shiny::req(r_value$x or input$x)   : r_value_x triggers block if value exists and not be NULL and be true to continue execution
      # - r_value$y  : r_value_y triggers block if any change value can be null or false
      # - value_z <-shiny::isolate(r_value$z or input$z) : changes in r_value_z do not trigger this block

      # code block

      # dont need a list only output$x changes
      return(value_x)

    })
  })
}

# helper functions,  start with "."

.helper_fn_1<- function(x, ...){
  # code block
}

.helper_fn_2<- function(x, ...){
  # code block
}
