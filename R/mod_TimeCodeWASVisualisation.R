#
# UI
#

mod_timeCodeWASVisualization_ui <- function(id) {
  ns <- shiny::NS(id)

  htmltools::tagList(
    shinyjs::useShinyjs(),
    shiny::fluidRow(
      # these must be in sync with server initialization
      shiny::column(3,
                    shiny::h5("Observation type"),
                    shinyWidgets::awesomeCheckbox(ns("condition_occurrence"), label = "Condition occurrence", value = TRUE),
                    shinyWidgets::awesomeCheckbox(ns("drug_exposure"), label = "Drug exposure", value = TRUE),
                    shinyWidgets::awesomeCheckbox(ns("measurement"), label = "Measurement", value = FALSE),
                    shinyWidgets::awesomeCheckbox(ns("procedure_occurrence"), label = "Procedure occurrence", value = FALSE),
                    shinyWidgets::awesomeCheckbox(ns("observation"), label = "Observation", value = FALSE),
      ),
      shiny::column(3, # c("-log10(p) [0,50]", "-log10(p) (50,100]", "-log10(p) (100,200]", "-log10(p) (200,Inf]")
                    shiny::h5("p-value groups"),
                    shinyWidgets::awesomeCheckbox(ns("group_1"), label = "-log10(p) [0,50]", value = FALSE),
                    shinyWidgets::awesomeCheckbox(ns("group_5"), label = "-log10(p) (50,100]", value = FALSE),
                    shinyWidgets::awesomeCheckbox(ns("group_10"), label = "-log10(p) (100,200]", value = TRUE),
                    shinyWidgets::awesomeCheckbox(ns("group_20"), label = "-log10(p) (200,Inf]", value = TRUE),
      ),
      shiny::column(3,
                    shinyWidgets::awesomeCheckbox(ns("show_labels"), label = "Show labels"),
                    shiny::hr(style = "margin-bottom: 0px;"),
                    shiny::sliderInput(ns("cases_per"), label="Filter cases% <",
                                       min = 0, max = 100, post  = " %", width = "200px",
                                       value = 50
                    ),
      ),
      shiny::column(3,
                    shiny::actionButton(ns("redraw"), label = "Update CodeWAS"),
                    shiny::hr(style = "margin-bottom: 20px;"),
                    shiny::actionButton(ns("unselect"), label = "Unselect"),
      )
    ),
    shiny::hr(style = "margin-bottom: 20px;"),
    shinycustomloader::withLoader(
      ggiraph::girafeOutput(ns("codeWASplot"), width = "100%", height = "100%"),
      type = "html",
      loader = "dnaspin",
    ),
    shiny::hr(style = "margin-bottom: 20px;"),
  )

}


#
# server
#

mod_timeCodeWASVisualization_server <- function(id, analysisResultsHandler) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

    studyResults  <- .analysisResultsHandler_to_studyResults(analysisResultsHandler)

    # fixed values
    time_periods = .get_time_periods(studyResults)
    gg_data_saved = .studyResults_to_gg_data(studyResults)


    # reactive values
    r <- shiny::reactiveValues(
      domains = c("condition_occurrence", "drug_exposure"),
      p_groups = c(10, 20),
      show_labels = FALSE,
      show_labels_cases_per = 50,
      #
      gg_data = NULL,
      #
      line_to_plot = NULL
    )

    #
    # copies input values to reactive values when redraw button is pressed
    #
    shiny::observeEvent(input$redraw, {

      domains <- c()
      if(input$condition_occurrence == TRUE) domains <- c("condition_occurrence")
      if(input$drug_exposure == TRUE) domains <- c(domains, "drug_exposure")
      if(input$measurement == TRUE) domains <- c(domains, "measurement")
      if(input$procedure_occurrence == TRUE) domains <- c(domains, "procedure_occurrence")
      if(input$observation == TRUE) domains <- c(domains, "observation")

      p_groups <- c()
      if(input$group_1 == TRUE) p_groups <- c(1)
      if(input$group_5 == TRUE) p_groups <- c(p_groups, 5)
      if(input$group_10 == TRUE) p_groups <- c(p_groups, 10)
      if(input$group_20 == TRUE) p_groups <- c(p_groups, 20)

      # update values
      r$domains <- domains
      r$p_groups <- p_groups
      r$show_labels <- input$show_labels
      r$show_labels_cases_per <- input$cases_per

    })


    #
    # updates r$gg_data with when r$domains or r$p_groups changes
    #
    shiny::observe( {
      shiny::req(r$domains)
      shiny::req(r$p_groups)

      # filter data
      gg_data <- gg_data_saved |>
        dplyr::filter(domain %in% r$domains) |>
        dplyr::filter(p_group_size %in% r$p_groups)

      # update gg_data
      r$gg_data <- gg_data
    })


    #
    # updates ggirafe plot when r$gg_data or r$show_labels or r$show_labels_cases_per changes
    #
    output$codeWASplot <- ggiraph::renderGirafe({

      shiny::req(r$gg_data)
      r$show_label
      shiny::req(r$show_labels_cases_per)
      r$selection

      gg_girafe <- .gg_data_to_gg_girafe(
        gg_data = r$gg_data,
        show_labels =  r$show_labels,
        show_labels_cases_per =  r$show_labels_cases_per,
        selection = r$line_to_plot)

      return(gg_girafe)
      # reploting this triggers codeWASplot_selected
    })

    #
    # triggered when points selected by click or by lasso
    # when plot is redrawn this is also triggered
    # this block captures the new selected points and the updates r$selected
    #
    shiny::observeEvent(input$codeWASplot_selected, {
      # clean selection value take only last selected
      selected_rows <- input$codeWASplot_selected
      selected_rows <- selected_rows[selected_rows != ""]

      # ignore selected rows that are currently plot as a line
      selected_rows  <- setdiff(selected_rows, r$line_to_plot$data_id)

      # continue if there is a new selection
      shiny::req(selected_rows)



      line_to_plot <- NULL
      if(length(selected_rows) > 1){
        # we have a marquee selection with n > 1
        df_lasso <- r$gg_data |>
          dplyr::filter(data_id %in% selected_rows) |>
          dplyr::mutate(up_in = ifelse(up_in == 1, "Case", "Ctrl")) |>
          dplyr::mutate(cases_per = scales::percent(cases_per, accuracy = 0.01)) |>
          dplyr::mutate(controls_per = scales::percent(controls_per, accuracy = 0.01)) |>
          dplyr::mutate(p = formatC(p, format = "e", digits = 2)) |>
          dplyr::select(name, up_in, n_cases_yes, n_controls_yes, cases_per, controls_per, GROUP, p)
        # show table
        shiny::showModal(
          shiny::modalDialog(
            DT::renderDataTable({
              DT::datatable(
                df_lasso,
                colnames = c(
                  # 'Covariate ID' = 'code',
                  'Covariate name' = 'name',
                  'Type' = 'up_in',
                  'Cases n' = 'n_cases_yes',
                  'Ctrls n' = 'n_controls_yes',
                  'Cases %' = 'cases_per',
                  'Ctrls %' = 'controls_per',
                  'Group' = 'GROUP',
                  'p' = 'p'
                )
              )
            }),
            size = "l",
            easyClose = FALSE,
            title = paste0("Entries (", nrow(df_lasso), ")"),
            footer = shiny::modalButton("Close"),
            options = list(
              autowidth = TRUE
            )
          )
        )
      } else {
        # single point selected, either by click or marquee
        selected_rows_clean <- stringr::str_remove_all(selected_rows, "@.*")
        line_to_plot <- r$gg_data |>
          dplyr::filter(code %in% selected_rows_clean) |>
          dplyr::arrange(code, time_period) |>
          dplyr::mutate(position = match(time_period, time_periods)) |>
          dplyr::mutate(name = ifelse(!is.na(position), paste0("panel-1-", position), "NA")) |>
          dplyr::select(code, domain, name, cases_per, controls_per, data_id)
      }

      # update reactive values
      r$line_to_plot <- line_to_plot


    }, ignoreInit = TRUE)


    #
    # unselect ####
    #
    shiny::observeEvent(input$unselect, {
      # remove the previous selection
      session$sendCustomMessage(type = ns('codeWASplot_set'), message = character(0))
      r$line_to_plot <- NULL
    }, ignoreInit = TRUE)


  })
}


.label_editor <- function(s){
  s <- stringr::str_remove(s, "from ")
  s <- stringr::str_replace(s, "to", " / ")
}

.get_time_periods <- function(studyResult){

  # get time_periods
  l <- unique(studyResult$timeRange)
  l_split <- lapply(l, function(x) {stringr::str_split(x, " ", simplify = TRUE)})
  time_periods <- as.data.frame(do.call(rbind, l_split)) |>
    dplyr::arrange(as.numeric(V2)) |>
    dplyr::mutate(period = paste(V1,V2,V3,V4)) |>
    dplyr::pull(period)

  return(time_periods)
}


.studyResults_to_gg_data <- function(studyResult){

  time_periods <- .get_time_periods(studyResult)

  studyResult <- studyResult |>
    dplyr::transmute(
      code = covariateId,
      time_period = factor(timeRange, levels = time_periods, labels = time_periods),
      name = covariateName,
      OR=OR,
      p=p,
      up_in=up_in,
      cases_per = n_cases_yes/n_cases,
      controls_per = n_controls_yes/n_controls,
      n_cases_yes = n_cases_yes,
      n_controls_yes = n_controls_yes
    ) |>
    tidyr::separate(name, c("domain", "name"), sep = ":", extra = "merge") |>
    dplyr::mutate(name = stringr::str_remove(name, "^[:blank:]")) |>
    dplyr::mutate(p = dplyr::if_else(p==0, 10^-323, p))

  gg_data <- studyResult |>
    dplyr::filter(p<0.00001) |>
    dplyr::arrange(time_period, name) |>
    dplyr::mutate_if(is.character, stringr::str_replace_na, "") |>
    dplyr::mutate(
      GROUP = time_period,
      label = stringr::str_c(code),
      label = stringr::str_remove(label, "[:blank:]+$"),
      label = stringr::str_c(domain, " : ", name,
                             "\n-log10(p)=", scales::number(-log10(p), accuracy = 0.1) ,
                             "\n log10(OR) = ", scales::number(log10(OR), accuracy = 0.1),
                             "\n cases:", n_cases_yes, " (", scales::percent(cases_per, accuracy = 0.01), ")",
                             "\n controls:", n_controls_yes, " (", scales::percent(controls_per, accuracy = 0.01), ")"
      ),
      link = paste0("https://atlas.app.finngen.fi/#/concept/", stringr::str_sub(code, 1, -4)),
      up_in = factor(domain) |> as.integer() |> as.character(),
      id = dplyr::row_number(),
      p_group = cut(-log10(p),
                    breaks = c(-1, 50, 100, 200, Inf ),
                    labels = c("-log10(p) [0,50]", "-log10(p) (50,100]", "-log10(p) (100,200]", "-log10(p) (200,Inf]"),
                    ordered_result = TRUE
      ),
      p_group_size = dplyr::case_when(
        as.integer(p_group)==1 ~ 1L,
        as.integer(p_group)==2 ~ 5L,
        as.integer(p_group)==3 ~ 10L,
        as.integer(p_group)==4 ~ 20L,
      ),
      log10_OR = dplyr::case_when(
        log10(OR) == -Inf ~ -2.5,
        log10(OR) == Inf ~ 5,
        TRUE ~ log10(OR) ,
      ),
      data_id = paste0(code, "@", as.character(time_period)),
      data_id_class = code
    )

  return(gg_data)
}

.gg_data_to_gg_girafe <- function(
    gg_data,
    show_labels, show_labels_cases_per,
    selection
){

  #
  # adjust the label area according to facet width
  facet_max_x <- max( gg_data$controls_per, 0.03, na.rm = TRUE)
  facet_max_y <- max( gg_data$cases_per, 0.03, na.rm = TRUE)
  #
  #
  gg_fig <- ggplot2::ggplot(
    data = dplyr::arrange( gg_data, log10_OR),
    ggplot2::aes(
      y = cases_per, #log10_OR, # cases_per-controls_per,#log10_OR,# -log10(p), cases_per-controls_per,#
      x = controls_per, #-log10(p), # 1, # id, #log10_OR,
      color = "darkgray",
      fill = domain,
      tooltip = label,
      # size = ordered(p_group), # log10_OR
      data_id = data_id
      # onclick = paste0('window.open("', link , '")')
    ), alpha = 0.75)+
    ggplot2::geom_segment(
      ggplot2::aes(x = 0, y = 0,
                   xend = ifelse(facet_max_x > facet_max_y, facet_max_y, facet_max_x),
                   yend = ifelse(facet_max_x > facet_max_y, facet_max_y, facet_max_x)
      ),
      color = "red", alpha = 0.5, linewidth = 0.2, linetype = "dashed") +
    ggplot2::geom_segment(
      ggplot2::aes(x = 0, y = 0, xend = facet_max_x, yend = 0),
      color = "black", alpha = 0.5, linewidth = 0.2, linetype = "dashed") +
    ggplot2::geom_segment(
      ggplot2::aes(x = 0, y = 0, xend = 0, yend = facet_max_y),
      color = "black", alpha = 0.5, linewidth = 0.2, linetype = "dashed") +
    ggiraph::geom_point_interactive(
      ggplot2::aes(size = p_group), show.legend=T, shape = 21) + #, position = position_dodge(width = 12))+
    ggplot2::scale_size_manual(
      values = c(
        "-log10(p) [0,50]" = 1,
        "-log10(p) (50,100]" = 1.5,
        "-log10(p) (100,200]" = 2,
        "-log10(p) (200,Inf]" = 3
      )
    ) +
    {if(show_labels)
      #
      ggrepel::geom_text_repel(
        data =  gg_data |>
          dplyr::filter(cases_per >  show_labels_cases_per/100),
        ggplot2::aes(label = stringr::str_wrap(stringr::str_trunc(name, 30), 15)),
        max.overlaps = Inf,
        size = 3,
        hjust = 0.1,
        xlim = c(facet_max_x / 4, NA),
        box.padding = 0.8
      )} +
    ggplot2::scale_x_continuous(
      breaks = c(0, 0.05, seq(0.1, 0.8, 0.1)),
      labels = c(0, 5, seq(10, 80, 10)),
      limits = c(-0.02 * facet_max_x, facet_max_x)
    ) +
    ggplot2::scale_y_continuous(
      breaks = c(0, 0.05, seq(0.1, 0.8, 0.1)),
      labels = c(0, 5, seq(10, 80, 10)),
      limits = c(-0.02 * facet_max_y, facet_max_y)
    ) +
    # ggplot2::coord_fixed() +
    ggplot2::facet_grid(
      .~GROUP, drop = FALSE, scales = "fixed",
      labeller = ggplot2::labeller(GROUP = .label_editor)
    )+
    ggplot2::theme_minimal()+
    ggplot2::theme(
      legend.key.height = grid::unit(5, "mm"),
      legend.key.width = grid::unit(10, "mm"),
      legend.position = "bottom",
      legend.direction = "vertical",
      strip.text.x = ggplot2::element_text(size = 10)
    ) +
    ggplot2::scale_color_manual(values = c("darkgray")) +
    ggplot2::scale_fill_manual(values = c(
      "condition_occurrence" = "khaki",
      "drug_exposure" = "lightblue2",
      "measurement" = "palegreen",
      "procedure_occurrence" = "plum1",
      "observation" = "gray"),
      labels = c(
        "condition_occurrence" = "Condition occurrence",
        "drug_exposure" = "Drug exposure",
        "measurement" ="Measurement",
        "observation" = "Observation"
      )
    ) +
    ggplot2::guides(color = "none", fill = ggplot2::guide_legend(override.aes = list(size = 5))) +
    ggplot2::labs(size = "p value group", fill = "Domain", x = "\nControls %", y = "Cases %")

  selected_items <- ""

  if(!is.null(selection) && length(unique(selection$code)) == 1){
    # one point selected -> draw a line connecting the same code in each facet
    gb <- ggplot2::ggplot_build(gg_fig)
    g <- ggplot2::ggplot_gtable(gb)
    # remove domains not in the current data
    selection <-  selection |>
      dplyr::filter(domain %in%  gg_data$domain)
    # check if we have lines to draw
    if(nrow(selection) > 1){
      z_val = 0
      ranges <- gb$layout$panel_params
      data2npc <- function(x, range) scales::rescale(c(range, x), c(0,1))[-c(1,2)]
      x_range <-  ranges[[1]][["x.range"]]
      y_range <- ranges[[1]][["y.range"]]

      selection <- dplyr::inner_join(selection, g$layout, by = "name") |>
        dplyr::mutate(controls_per = data2npc(controls_per, x_range)) |>
        dplyr::mutate(cases_per = data2npc(cases_per, y_range))
      selection$z <- 1
      selection$clip <- "off"

      # move to the beginning of selection
      g <- gtable::gtable_add_grob(
        g, grid::moveToGrob(selection[1,]$controls_per, selection[1,]$cases_per),
        t = selection[1,]$t, selection[1,]$l, z = z_val)
      # draw the lines
      for(i in 2:nrow(selection)){
        if(is.na(selection[i,]$t) || is.na(selection[i,]$l))
          next
        g <- gtable::gtable_add_grob(
          g, grid::lineToGrob(selection[i,]$controls_per, selection[i,]$cases_per, gp = grid::gpar(col = "red", alpha = 0.3, lwd = 2.5)),
          t = selection[i,]$t, selection[i,]$l, z = z_val)
      }

      # turn clip off to see the line across panels
      g$layout$clip <- "off"
    }

    if(!is.null(selection)){
      selected_items <- as.character(unique(selection$code))
      # extend selection to same code in all facets
      selected_items <- gg_data |>
        dplyr::filter(code == selected_items) |>
        dplyr::pull(data_id)
      skip_selection <- TRUE
    } else {
      selected_items <- ""
    }

    gg_plot <- ggplotify::as.ggplot(g)
  } else {
    gg_plot <- gg_fig
  }

  gg_girafe <- ggiraph::girafe(ggobj = gg_plot, width_svg = 15)
  gg_girafe <- ggiraph::girafe_options(gg_girafe,
                                       ggiraph::opts_sizing(rescale = TRUE, width = 1.0),
                                       ggiraph::opts_hover(
                                         css = "fill-opacity:1;fill:red;stroke:black;",
                                         reactive = FALSE
                                       ),
                                       ggiraph::opts_selection(
                                         type = c("multiple"),
                                         only_shiny = TRUE,
                                         selected = selected_items
                                       )

  )
  return(gg_girafe)
}



.analysisResultsHandler_to_studyResults <- function(analysisResultsHandler){

  studyResults  <- analysisResultsHandler$tbl("temporal_covariate_timecodewas")  |>
    dplyr::left_join(
      analysisResultsHandler$tbl("temporal_time_ref") |>
        dplyr::select(time_id, start_day,end_day),
      by = "time_id"
    ) |>
    dplyr::left_join(
      analysisResultsHandler$tbl("temporal_covariate_ref") ,
      by = "covariate_id"
    )|>
    dplyr::left_join(
      analysisResultsHandler$tbl("temporal_analysis_ref") ,
      by = "analysis_id"
    )  |>
    dplyr::mutate(
      up_in = dplyr::if_else(odds_ratio>1, "Case", "Ctrl"),
      n_cases = n_cases_yes + n_cases_no,
      n_controls = n_controls_yes + n_controls_no
    ) |>
    dplyr::select(
      covariate_id, time_id, n_cases_yes, n_controls_yes, n_cases, n_controls, n_cases_no, n_controls_no, start_day,end_day,
      covariate_name, p_value, odds_ratio, up_in
    ) |>
    dplyr::collect()

  studyResults <- studyResults|>
    dplyr::mutate(time_range = paste0("from ", as.integer(start_day)," to ", as.integer(end_day)))|>

    dplyr::rename(
      covariateId = covariate_id,
      timeId = time_id,
      timeRange = time_range,
      covariateName = covariate_name,
      p = p_value,
      OR = odds_ratio
    )


  return(studyResults)
}





























