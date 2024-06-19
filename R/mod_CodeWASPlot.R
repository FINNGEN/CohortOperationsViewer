#
# UI
#

mod_codeWASPlot_ui <- function(id) {
  ns <- shiny::NS(id)

  htmltools::tagList(
    htmltools::h4("CodeWAS Results"),
    shiny::div(
      style = "margin-top: 10px; margin-bottom: 20px;",
      shiny::textOutput(ns("total_n")),
    ),
    shiny::uiOutput(ns("codeWASFilter")),
    htmltools::hr(style = "margin-top: 10px; margin-bottom: 10px;"),
    DT::dataTableOutput(ns("codeWAStable")),
    htmltools::hr(style = "margin-top: 10px; margin-bottom: 10px;"),
    shiny::downloadButton(ns("downloadCodeWAS"), "Download CodeWAS results", icon = shiny::icon("download"))
  )

}

#
# server
#

mod_codeWASPlot_server <- function(id, analysisResultsHandler) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

    atlasUrl <- shiny::getShinyOption("cohortOperationsConfig")$atlasUrl

    output$total_n <- shiny::renderText({
      shiny::req(r$codeWASData)
      paste("Total N: ")
    })

    # reactive values
    r <- shiny::reactiveValues(
      codeWASData = NULL,
      filteredCodeWASData = NULL
    )

    #
    # render the CodeWAS filters from the data
    #
    output$codeWASFilter <- shiny::renderUI({
      req(r$codeWASData)

      shiny::fluidRow(
        shiny::column(
          width = 2,
            shinyWidgets::pickerInput(
              ns("database"),
              "Database",
              choices = unique(r$codeWASData$database_id),
              selected = unique(r$codeWASData$database_id),
              multiple = FALSE,
              options = list(`actions-box` = TRUE, `selected-text-format` = "count > 3", `count-selected-text` = "{0} databases selected")
            )),
          shiny::column(
            width = 2,
            shinyWidgets::pickerInput(
              ns("domain"),
              "Domain",
              choices = unique(r$codeWASData$domain_id),
              selected = unique(r$codeWASData$domain_id),
              multiple = TRUE,
              options = list(
                `actions-box` = TRUE,
                `selected-text-format` = "count > 3",
                `count-selected-text` = "{0} domains selected"
              )
            )),
          shiny::column(
            width = 2,
            shinyWidgets::pickerInput(
              ns("analysis"),
              "Analysis",
              choices = unique(r$codeWASData$analysis_name),
              selected = unique(r$codeWASData$analysis_name),
              multiple = TRUE,
              options = list(`actions-box` = TRUE, `selected-text-format` = "count > 3", `count-selected-text` = "{0} analyses selected")
            )),
          shiny::column(
            width = 2,
            shinyWidgets::pickerInput(
              ns("model"),
              "Model",
              choices = unique(r$codeWASData$model_type),
              selected = unique(r$codeWASData$model_type),
              multiple = TRUE,
              options = list(`actions-box` = TRUE, `selected-text-format` = "count > 3", `count-selected-text` = "{0} model types selected")
            )),
          shiny::column(
            width = 2,
            shinyWidgets::pickerInput(
              ns("p_value"),
              "p",
              choices = c('-log10(p) (0,5]', '-log10(p) (5,100]', '-log10(p) (100,Inf]'),
              selected = c('-log10(p) (0,5]', '-log10(p) (5,100]', '-log10(p) (100,Inf]'),
              multiple = TRUE,
              options = list(`actions-box` = TRUE, `selected-text-format` = "count > 1", `count-selected-text` = "{0} classes selected")
            )
          )
        )
    })

    #
    # load the CodeWAS data
    #
    shiny::observe({
      r$codeWASData <- analysisResultsHandler$tbl('codewas_results') |>
        dplyr::left_join(analysisResultsHandler$tbl('covariate_ref'), by = c('covariate_id' = 'covariate_id'))  |>
        dplyr::left_join(analysisResultsHandler$tbl('analysis_ref'), by = c('analysis_id' = 'analysis_id')) |>
        dplyr::mutate(odds_ratio = ifelse(is.na(odds_ratio) & model_type != 'linear', exp(beta), odds_ratio)) |>
        dplyr:::select(-c('is_binary', 'missing_means_zero')) |>
        dplyr::mutate(p_log = cut(-log10(p_value),
                                  breaks = c(0, 5, 100, Inf),
                                  labels = c('-log10(p) (0,5]', '-log10(p) (5,100]', '-log10(p) (100,Inf]'))
        ) |>
        tibble::as_tibble()
    })

    #
    # filter the data
    #
    shiny::observe({
      req(r$codeWASData)

      r$filteredCodeWASData <- r$codeWASData |>
        dplyr::filter(
          if (!is.null(input$database)) database_id %in% input$database else FALSE,
          if (!is.null(input$domain)) domain_id %in% input$domain else FALSE,
          if (!is.null(input$analysis)) analysis_name %in% input$analysis else FALSE,
          if (!is.null(input$model)) model_type %in% input$model else FALSE,
          if (!is.null(input$p_value)) p_log %in% input$p_value | is.na(p_log) else FALSE
        )
    })

    #
    # render the CodeWAS table
    #
    output$codeWAStable <- DT::renderDataTable({
      req(r$filteredCodeWASData)
      req(r$filteredCodeWASData  |>  nrow() > 0)

      # https://github.com/rstudio/DT/issues/1127
      # the bug can be worked around by setting shiny.json.digits to a smaller value
      options(shiny.json.digits = 4)

      # this is not returning the url?
      atlasUrl <- shiny::getShinyOption("cohortOperationsConfig")$atlasUrl

      DT::datatable(
        r$filteredCodeWASData |>
          dplyr::mutate(p_value = as.numeric(formatC(p_value, format = "e", digits = 2))) |>
          dplyr::mutate(odds_ratio = as.numeric(formatC(odds_ratio, format = "e", digits = 2))) |>
          dplyr::mutate(beta = as.numeric(formatC(beta, format = "e", digits = 2))) |>
          dplyr::mutate(standard_error = as.numeric(formatC(standard_error, format = "e", digits = 2))) |>
          dplyr::mutate(mean_cases = as.numeric(formatC(mean_cases, format = "e", digits = 2))) |>
          dplyr::mutate(sd_cases = as.numeric(formatC(sd_cases, format = "e", digits = 2))) |>
          dplyr::mutate(mean_controls = as.numeric(formatC(mean_controls, format = "e", digits = 2))) |>
          dplyr::mutate(sd_controls = as.numeric(formatC(sd_controls, format = "e", digits = 2))) |>
          dplyr::mutate(covariate_name_full = as.character(covariate_name)) |>
          dplyr::mutate(covariate_name = stringr::str_trunc(covariate_name, 40)) |>
          dplyr::mutate(
            covariate_id = round(covariate_id/1000),
            covariate_name = purrr::map2_chr(covariate_name, covariate_id, ~paste0('<a href="',atlasUrl,'/#/concept/', .y, '" target="_blank">', .x,'</a>'))
          ) |>
          dplyr::select(
            database_id, domain_id, analysis_name, covariate_name, concept_id,
            n_cases_yes, n_controls_yes, mean_cases, sd_cases, mean_controls, sd_controls,
            p_value, odds_ratio, beta, standard_error, model_type, run_notes,
            covariate_name_full
          ),
        escape = FALSE,
        class = 'display nowrap compact',
        selection = 'single',
        rownames = FALSE,
        colnames = c(
          'Database' = 'database_id',
          'Domain' = 'domain_id',
          'Analysis' = 'analysis_name',
          'Covariate Name' = 'covariate_name',
          'Concept ID' = 'concept_id',
          # 'Cov. ID' = 'covariate_id',
          # 'N tot' = 'n_total',
          'N case' = 'n_cases_yes',
          'N ctrl' = 'n_controls_yes',
          'Mean case' = 'mean_cases',
          'SD case' = 'sd_cases',
          'Mean ctrl' = 'mean_controls',
          'SD ctrl' = 'sd_controls',
          'p' = 'p_value',
          'OR' = 'odds_ratio',
          'Beta' = 'beta',
          'SE' = 'standard_error',
          'Model' = 'model_type',
          # 'ID' = 'analysis_id',
          'Notes' = 'run_notes',
          # 'Binary' = 'is_binary',
          # 'Missing mean zero' = 'missing_means_zero'
          'covariate_name_full' = 'covariate_name_full'
        ),
        options = list(
          # rowCallback to show the full covariate name as a tooltip
          rowCallback = htmlwidgets::JS(
              "function(row, data) {",
              "var full_text = data[13]", # covariate_name_full
              "$('td', row).attr('title', full_text);",
              "}"
          ),
          # change the color of the cells with NA (except for the Notes column)
          createdRow = htmlwidgets::JS(
            "function(row, data, dataIndex) {",
            "  for(var i=0; i<data.length; i++){",
            "    if(data[i] === null && ![5, 6, 12].includes(i)){", # skip Notes-column
            "      $('td:eq('+i+')', row).html('NA')",
            "        .css({'color': 'rgb(226,44,41)', 'font-style': 'italic'});",
            "    }",
            "  }",
            "}"
          ),
          # autoWidth = TRUE,
          # arrange the table by p_value
          order = list(list(7, 'asc')), # p_value
          # scrollX = TRUE,
          columnDefs = list(
            list(width = '70px', targets = c(3, 13)), # covariate_name
            list(width = '45px', targets = c(2)), # concept_id
            list(width = '40px', targets = c(0,1,4,5,6,7, 10, 11)),
            list(width = '50px', targets = c(8, 9)), # p_value, OR
            list(visible = FALSE, targets = c(13))
          ),
          pageLength = 20,
          lengthMenu = c(10, 15, 20, 25, 30)
        )
      ) |> DT::formatStyle('Covariate Name', cursor = 'pointer' )
    })

    #
    # Download the CodeWAS results table as a csv file
    #
    output$downloadCodeWAS <- downloadHandler(
      filename = function() {
        paste(Sys.time(), '_result.csv', sep='')
      },
      content = function(file) {
        write.csv(r$codeWASData, file, row.names = FALSE)
      }
    )

  })
}

















