#
# UI
#

mod_cohortDemographicsPlot_ui <- function(id) {
  ns <- shiny::NS(id)

  shiny::tagList(
    shiny::uiOutput(ns("CDPlot_ui")),
    shiny::plotOutput(ns("demographicsPlot"), height = "700px")
  )
}


#
# server
#

mod_cohortDemographicsPlot_server <- function(id, analysisResultsHandler) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

    cohortDemographicsData <- shiny::reactive({

      analysisResultsHandler$tbl('demographics_counts') |>
        tibble::as_tibble()
    })

    #
    # data to be plotted
    #
    ggplotData <- shiny::reactive({
      shiny::req(cohortDemographicsData())
      shiny::req(input$stratify_by)
      shiny::req(input$database_id)
      shiny::req(input$cohort_id)
      shiny::req(input$gender)
      shiny::req(input$reference_year)

      # add cohort_id to grouping_vars
      grouping_vars <- c(input$stratify_by, "cohort_id")

      cohortDemographicsData() |>
        dplyr::mutate(
          age_group = forcats::fct_reorder(
            age_group, as.numeric(stringr::str_extract(age_group, "\\d+")))
        ) |>
        # filters
        dplyr::filter(database_id %in% input$database_id) |>
        dplyr::filter(cohort_id %in% input$cohort_id) |>
        dplyr::filter(gender %in% input$gender) |>
        dplyr::filter(reference_year == input$reference_year) |>
        dplyr::group_by(across(grouping_vars)) |>
        dplyr::summarise(count = sum(count)) |>
        dplyr::ungroup()
    })

    output$CDPlot_ui <- shiny::renderUI({
      shiny::req(cohortDemographicsData())

      cdd <- cohortDemographicsData()

      shiny::fluidPage(
        column(
          3,
          shiny::tagList(
            shinyWidgets::pickerInput(
              ns("database_id"), "Select database",
              choices = unique(cdd$database_id), unique(cdd$database_id),
              selected = dplyr::first(unique(cdd$database_id)), multiple = FALSE
            ),
            shinyWidgets::pickerInput(
              ns("cohort_id"), "Select cohorts", choices = NULL, selected = NULL, multiple = TRUE),
          )),
        column(
          3,
          shiny::tagList(
            shinyWidgets::pickerInput(
              ns("reference_year"), "Show patient counts for", choices = unique(cdd$reference_year), selected = "cohort_start_date", multiple = FALSE),
            shinyWidgets::pickerInput(
              ns("gender"), "Gender", choices = unique(cdd$gender), selected = unique(cdd$gender), multiple = TRUE),
          )),
        column(
          3,
          shiny::tagList(
            shinyWidgets::pickerInput(
              ns("stratify_by"), "Stratify by",
              choices = c("age_group", "gender", "calendar_year"),
              selected = c("age_group", "gender", "calendar_year"), multiple = TRUE),
            shiny::div(
              shiny::checkboxInput(ns("show_count"), "Show patient counts", value = FALSE),
              style="margin-top: 15px; margin-bottom: -15px;"
            ),
            shiny::div(
              shiny::checkboxInput(ns("same_scale"), "Use same y-scale across cohorts", value = TRUE),
              style="margin-top: -15px; margin-bottom: -15px;"
            ),
          )
        ),
        column(
          3,
          shiny::tagList(
            shiny::fluidRow(
              shiny::div(style = "height:25px"),
              shiny::actionButton(ns("table_all"), label = "Show data as a table"),
              shiny::div(style = "height:10px"),
              shiny::downloadButton(ns("download_actionButton"), "Download"),
              shiny::div(style = "height:5px"),
            ),
          )
        )
      )

    })

    #
    # Update cohort_id picker based on database_id
    #
    shiny::observeEvent(input$database_id, {
      shiny::req(cohortDemographicsData())
      shiny::req(input$database_id)

      cohorts_in_database <- cohortDemographicsData() |>
        dplyr::filter(database_id %in% input$database_id) |>
        dplyr::distinct(cohort_id) |>
        dplyr::pull(cohort_id)

      shinyWidgets::updatePickerInput(session, "cohort_id", choices = cohorts_in_database, selected = cohorts_in_database)
    }, ignoreInit = FALSE)

    #
    # helper function to build the plot
    #
    build_plot <- function(x, y, fill, rows, cols, title, x_label, y_label){
      x <- ggplot2::sym(x)
      y <- ggplot2::sym(y)
      fill <- if(fill != "") ggplot2::sym(fill)
      text_angle <- if(x == "calendar_year") 45 else 0
      gg_plot <- ggplotData() |>
        ggplot2::ggplot(ggplot2::aes(x = !!x, y = !!y, fill = !!fill)) +
        ggplot2::geom_col(position = "dodge", width = 0.8) +
        {if(input$show_count)
          ggplot2::geom_text(ggplot2::aes(label = count), vjust = -0.7, position = ggplot2::position_dodge(width = .8))
        } +
        ggplot2::facet_grid(eval(ggplot2::expr(!!ggplot2::ensym(rows) ~ !!ggplot2::ensym(cols))), scales = ifelse(input$same_scale, "fixed", "free_y")) +
        {if(x == "calendar_year")
          ggplot2::scale_x_continuous(breaks = function(x) unique(floor(pretty(seq(min(x), (max(x) + 1) * 1.1)))))
        } +
        ggplot2::coord_cartesian(clip = "off") +
        ggplot2::expand_limits(y = max(ggplotData()$count) * 1.1) +
        ggplot2::theme_minimal(base_size = 13) +
        ggplot2::theme(
          axis.text.x = ggplot2::element_text(size = 12, angle = text_angle, hjust = 1),
          strip.background = ggplot2::element_rect(fill="white"),
          strip.text = ggplot2::element_text(colour = 'black')
        ) +
        {if("gender" %in% input$stratify_by)
          ggplot2::scale_fill_manual(values = c("Female" = "red", "Male" = "blue", "Other" = "grey"))
        } +
        ggplot2::labs(title = title, x = x_label, y = y_label)
      return(gg_plot)
    }

    #
    # Plot demographics
    #
    output$demographicsPlot <- shiny::renderPlot({
      shiny::req(shiny::isTruthy(cohortDemographicsData()))
      shiny::req(ggplotData())

      # ggplot absolutely requires data to be present
      if(nrow(ggplotData()) == 0) return(NULL)

      if(identical(c("age_group", "gender", "calendar_year"), input$stratify_by)){
        gg_plot <- build_plot(
          x = "calendar_year", y = "count", fill = "gender",
          rows = "cohort_id", cols = "age_group",
          title = "Cohort Demographics", x_label = "Calendar time by age group", y_label = "Count")
      } else if(identical(c("age_group", "gender"), input$stratify_by)) {
        gg_plot <- build_plot(
          x = "age_group", y = "count", fill = "gender",
          rows = "cohort_id", cols = ".",
          title = "Cohort Demographics", x_label = "Age group", y_label = "Count")
      } else if(identical(c("age_group", "calendar_year"), input$stratify_by)) {
        gg_plot <- build_plot(
          x = "calendar_year", y = "count", fill = "",
          rows = "cohort_id", cols = "age_group",
          title = "Cohort Demographics", x_label = "Calendar time by age group", y_label = "Count")
      } else if(identical(c("gender", "calendar_year"), input$stratify_by)) {
        gg_plot <- build_plot(
          x = "calendar_year", y = "count", fill = "gender",
          rows = "cohort_id", cols = "gender",
          title = "Cohort Demographics", x_label = "Calendar time by gender", y_label = "Count")
      } else if(identical(c("age_group"), input$stratify_by)) {
        gg_plot <- build_plot(
          x = "age_group", y = "count", fill = "",
          rows = "cohort_id", cols = ".",
          title = "Cohort Demographics", x_label = "Age group", y_label = "Count")
      } else if(identical(c("gender"), input$stratify_by)) {
        gg_plot <- build_plot(
          x = "gender", y = "count", fill = "gender",
          rows = "cohort_id", cols = ".",
          title = "Cohort Demographics", x_label = "Gender", y_label = "Count")
      } else if(identical(c("calendar_year"), input$stratify_by)) {
        gg_plot <- build_plot(
          x = "calendar_year", y = "count", fill = "",
          rows = "cohort_id", cols = ".",
          title = "Cohort Demographics", x_label = "Calendar time", y_label = "Count")
      } else {
        return(NULL)
      }

      return(gg_plot)
    })

    #
    # show all points as a table
    #
    shiny::observeEvent(input$table_all, {
      shiny::req(ggplotData())

      # show table
      shiny::showModal(
        shiny::modalDialog(
          DT::renderDataTable({
            ggplotData() |>
              DT::datatable(
                # colnames = c(
                #   'Covariate name' = 'name',
                #   'Type' = 'up_in',
                #   'OR' = 'OR',
                #   'Cases n' = 'n_cases_yes',
                #   'Ctrls n' = 'n_controls_yes',
                #   'Cases %' = 'cases_per',
                #   'Ctrls %' = 'controls_per',
                #   'Group' = 'GROUP',
                #   'p' = 'p'
                # ),
                escape = FALSE
              )
          }),
          size = "l",
          easyClose = FALSE,
          title = "Demographics data table",
          footer = shiny::modalButton("Close"),
          options = list(
            autowidth = TRUE
          )
        )
      )
    }, ignoreInit = TRUE)

    #
    # download demographics table
    #
    output$download_actionButton <- shiny::downloadHandler(
      filename = function(){"demographics.csv"},
      content = function(fname){
        readr::write_csv(ggplotData(), fname)
        return(fname)
      }
    )

  })
}


