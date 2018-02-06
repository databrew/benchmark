# Libraries
library(tidyverse)
library(radarchart)
library(shinyWidgets)
library(extrafont)
loadfonts()
# library(ggradar) # devtools::install_github('ricardo-bion/ggradar')
# library(d3radarR) # devtools::install_github("timelyportfolio/d3radarR")

source('gg_radar.R')


# Create a dictionary of tab names / numbers
tab_names_full <- c('Instructions',
               'Strategy and Execution',
               'Organization and Governance',
               'Partnerships',
               'Products',
               'Marketing',
               'Distribution and Channels',
               'Risk Management',
               'IT and MIS',
               'Operations and Customer Service',
               'Responsible Finance',
               'Graphs',
               'About')
tab_names <- tolower(gsub(' ', '_', tab_names_full))
tab_dict <- data_frame(number = 1:length(tab_names),
                       name = tab_names,
                       full_name = tab_names_full)
n_tabs <- nrow(tab_dict)
# So as to avoid flooding the ui, create dictionaries with text
# Create main dictionary for associating competencies with tabs
competency_dict <- readr::read_csv('dictionaries/competency_dict.csv')
competency_dict$tab_name <- tolower(gsub(' ', '_', competency_dict$tab_name))
tab_names <- unique(competency_dict$tab_name)
competency_dict$combined_name <- paste0(competency_dict$tab_name, '_', competency_dict$competency)

# Create dictionary for placing text
ui_dict <- read_csv('dictionaries/ui_dict.csv')


# Define function to get the appropriate text from the ui dict
get_ui_text <- function(item_name){
  out <- ui_dict %>%
    filter(name == item_name) %>%
    .$text
  if(length(out) == 0){
    out <- paste0('No text yet has been filled out for ', item_name, ' in the ui_dict.')
  }
  return(out)
}

# Define function for keeping an eye on inputs, so that they don't get reset when the ui gets re-rendered
create_input_list <- function(){

  a <- paste0("input_list <- reactiveValues();\n")
  inputs <- paste0(ui_dict$name, '_slider')
  b <- rep(NA, length(inputs))
  for(i in 1:length(inputs)){
    this_input <- inputs[i]
    v <- parse_number(this_input)
    v <- 0
    b[i] <- paste0("input_list[['", this_input, "']] <- ", v, ";\n")
  }
  # Observe any changes and register them
  z <- rep(NA, length(inputs))
  for(i in 1:length(inputs)){
    this_input <- inputs[i]
    this_event <- paste0('input$', this_input)
    # # Observe buttons rather than sliders
    # this_observation <- gsub('_slider', '_submit', this_event)
    # Observe sliders rather than buttons
    this_observation <- this_event
    z[i] <- 
      paste0("observeEvent(",this_observation,", { ;
 input_list[['", this_input, "']] <- ", this_event,"
    });\n")
  }
  paste0(a,
         paste0(b,
         z, collapse = ''),
         collapse = '')
}

# Define function for creating a 1-5 slider for a given item
create_slider <- function(item_name,
                          ip){
  list_name <- paste0(item_name, '_slider')
  ip <- reactiveValuesToList(ip)
  ip <- unlist(ip)
  if(list_name %in% names(ip)){
    val <- ip[names(ip) == list_name]
  } else {
    message('PROBLEM')
    message(' this is list name: ', list_name)
    message('it is not in names of ip: ')
    print(sort(names(ip)))
    val <- 3
  }


  sliderInput(paste0(item_name, '_slider'),
              'Score',
              min = 0, 
              max = 5,
              value = val)
}

# Define function for creating a submit button to follow each slider
create_submit <- function(item_name, show_icon = FALSE){
  if(show_icon){
    icon("check", "fa-3x")
  } else {
    icon('exclamation-circle', 'fa-3x')
  }
}

# Define function for generating code for the server-sides reactivity flow
generate_reactivity <- function(tab_name = 'strategy_and_execution',
                                competencies = c('vision',
                                                 'strategy_formulation',
                                                 'management_committment',
                                                 'execution_capability')){
  
  out <- rep(NA, length(competencies))
  for(i in 1:length(competencies)){
    out[i] <- 
      paste0('
             
             # Create reactive values
             submissions$', tab_name, '_', competencies[i], '_1_submit <- FALSE;
             submissions$', tab_name, '_', competencies[i], '_2_submit <- FALSE;
             submissions$', tab_name, '_', competencies[i], '_3_submit <- FALSE;
             
             # Observe submissions
             observeEvent(input$', tab_name, '_', competencies[i], '_1_slider,{message("OBSERVED");
                if(input$', tab_name, '_', competencies[i], '_1_slider > 0){
                  submissions$', tab_name, '_', competencies[i], '_1_submit <- TRUE
                }
              })
             observeEvent(input$', tab_name, '_', competencies[i], '_2_slider,{message("OBSERVED");
                if(input$', tab_name, '_', competencies[i], '_2_slider > 0){
                  submissions$', tab_name, '_', competencies[i], '_2_submit <- TRUE
                }
              })
              observeEvent(input$', tab_name, '_', competencies[i], '_3_slider,{message("OBSERVED");
                if(input$', tab_name, '_', competencies[i], '_3_slider > 0){
                  submissions$', tab_name, '_', competencies[i], '_3_submit <- TRUE
                }
              })
             
             # Reactives saying whether the entire competency has been submitted
             ', tab_name, '_', competencies[i], '_submitted <- reactive({
             submissions$', tab_name, '_', competencies[i], '_1_submit &
             submissions$', tab_name, '_', competencies[i], '_2_submit &
             submissions$', tab_name, '_', competencies[i], '_3_submit
             })
             ')
  }
  paste0(out, collapse = '\n')
}



# Define function for generating ui inputs
generate_ui <- function(tab_name = 'strategy_and_execution',
                        competencies = c('vision',
                                         'strategy_formulation',
                                         'management_committment',
                                         'execution_capability')){
  full_name <- simple_cap(gsub('_', ' ', tab_name))
  full_name <- convert_capitalization(full_name)
  n_competencies <- length(competencies)
  
  # Start of page
  a <- 
    paste0("
           h1('", full_name, "'),
    fluidRow(p('", full_name, " is divided into ", n_competencies, " competencies')),
           ")
  
  # Each box
  b <- rep(NA, n_competencies)
  for(i in 1:n_competencies){
    this_competency <- competencies[i]
    this_title <- convert_capitalization(simple_cap(gsub('_', ' ', this_competency)))
    competency_done <- paste0(tab_name, "_", this_competency, "_submitted()")
    b[i] <- paste0("\ntabPanel(paste0('", this_title, 
                   "'),",
# "', ifelse(", competency_done, ", ' (Completed)', '')), 

        "fluidPage(br()\n,box(title = paste0('", this_title, "', ifelse(", competency_done, ", ' (Completed)', '')),        width = 12,
        solidHeader = TRUE,
        collapsible = TRUE,
        collapsed = FALSE,
                   ",
        # collapsed = ", competency_done, ",
        "column(4,
               p(get_ui_text('", tab_name, "_", this_competency, "_1')),
               create_slider('", tab_name, "_", this_competency, "_1', ip = input_list),
               create_submit('", tab_name, "_", this_competency, "_1', 
                             show_icon = submissions$", tab_name, "_", this_competency, "_1_submit)),
        column(4,
               p(get_ui_text('", tab_name, "_", this_competency, "_2')),
               create_slider('", tab_name, "_", this_competency, "_2', ip = input_list),
               create_submit('", tab_name, "_", this_competency, "_2',
                             show_icon = submissions$", tab_name, "_", this_competency, "_2_submit)),
        column(4,
               p(get_ui_text('", tab_name, "_", this_competency, "_3')),
               create_slider('", tab_name, "_", this_competency, "_3', ip = input_list),
               create_submit('", tab_name, "_", this_competency, "_3',
                             show_icon = submissions$", tab_name, "_", this_competency, "_3_submit))
    )))")
  }
  b <- paste0(b, collapse = ',')
  b <- paste0('fluidPage(tabsetPanel(', b, ',id = "sub_tab", selected = sub_tab_selected()))', collapse = '')
  
  out <- 
    paste0("output$",tab_name, "_ui <- ",
           "renderUI({",
           "fluidPage(",
          a,
          b,
          ")})")
  return(out)
}


simple_cap <- function(x) {
  s <- strsplit(x, " ")[[1]]
  paste(toupper(substring(s, 1,1)), substring(s, 2),
        sep="", collapse=" ")
}
simple_cap <- Vectorize(simple_cap)

# Define function for radar charts
make_radar_data <- function(ip){
  require(radarchart)

  ip <- reactiveValuesToList(ip)
  ip <- unlist(ip)

  combined_names <- competency_dict$combined_name

  # Get values for each of the combined names
  vals_df <-
    expand.grid(combined_name = combined_names,
                key = 1:3)
  # Get broken down names from dict
  vals_df <- left_join(vals_df,
                       competency_dict,
                       by = 'combined_name')
  vals_df$value <- NA
  vals_df$value_name <- paste0(vals_df$combined_name, '_', vals_df$key, '_slider')
  for(i in 1:nrow(vals_df)){
    the_name <- vals_df$value_name[[i]]
    the_value <- ip[names(ip) == the_name]
    the_value <- as.numeric(the_value)
    vals_df$value[i] <- the_value
  }
  
  # Get the "score" of the competency quote in question
  vals_df$score <- parse_number(vals_df$value_name)
  vals_df$score <- ifelse(vals_df$score == 1, 1,
                          ifelse(vals_df$score == 2, 3,
                                 ifelse(vals_df$score == 3, 5,
                                        vals_df$score)))
  # Group by competency and get weighted score
  out <- vals_df %>%
    group_by(tab_name, competency) %>%
    summarise(value = weighted.mean(x = score, w = value, na.rm = TRUE)) %>%
    ungroup
  
  # Get in format for charting
  out$labs <- simple_cap(gsub('_', ' ', out$competency))
  out$labs <- convert_capitalization(out$labs)
  out$scores <- out$value
  
  # Return 
  return(out)
}

# Define function for converting certain string for case-specific capitalization
convert_capitalization <- function(x){
  x <- gsub('It ', 'IT ', x)
  x <- gsub('Mis', 'MIS', x)
  x <- gsub('techs', 'Techs', x)
  x <- gsub('Hr ', 'HR ', x)
  return(x)
}

# Define function for making radar chart
make_radar_chart <- function(data,
                             tn = 'organization_and_governance',
                             label_size = 11,
                             height = NULL,
                             gg = FALSE){
  # Subset to the tab in question
  data <- data %>%
    filter(tab_name == tn)
  scores <- list(
    'This Bank' = data$scores,
    'Best Practice' = rep(5, nrow(data))
  )
  labs <- data$labs
  if(gg){
    pd <- data %>%
      dplyr::select(labs, scores) %>%
      mutate(group = 'This bank') %>%
      mutate(scores = ifelse(is.na(scores), 0, scores))
    benchmark <- pd %>%
      mutate(scores = 5,
             group = 'Benchmark')
    pd <- bind_rows(pd, benchmark) %>% mutate(scores = scores)
    pd <- pd %>% spread(key = labs, value = scores)
    # pd$group <- gsub(' ', '\n', pd$group)
    names(pd) <- gsub(' ', '\n', names(pd))
    ggradar(plot.data = pd,
            axis.label.size = 3,
            grid.max = 5,
            gridline.max.colour = NA,
            gridline.mid.colour = NA,
            gridline.min.colour = NA,
            group.point.size = 2,
            grid.label.size = 0,
            centre.y = 0,
            group.colours = c('lightblue', 'darkorange'),
            group.line.width = 1,
            line_alpha = 0.8,
            legend.text.size = 10)
    
    
  } else {
    chartJSRadar(scores = scores, labs = labs, maxScale = 5,
                 height = height,
                 scaleStepWidth = 1,
                 scaleStartValue = 1,
                 responsive = TRUE,
                 labelSize = label_size,
                 showLegend = TRUE,
                 addDots = TRUE,
                 showToolTipLabel = TRUE,
                 colMatrix = t(matrix(c(col2rgb('darkorange'), col2rgb('lightblue')), nrow = 2, byrow = TRUE)))
  }
  
}


# Define function for generating all the radar charts in the server
generate_radar_server <- function(tab_name = 'organization_and_governance'){
  paste0("output$", tab_name, "_chart <- renderChartJSRadar({
    data <- radar_data()
    make_radar_chart(data,
                     tn = '", tab_name, "')
  })")
}


#' Prettify a table for HTML documents
#'
#' Create a data table object from a dataframe with optional aesthetic improvements. Userful for inclusion in .Rmd files being knitted to HTML
#' @param the_table The dataframe to be prettified
#' @param remove_underscores_columns Whether to remove underscores in column names and replace them with spaces
#' @param cap_columns Whether to capitalize the first letter of the names of columns
#' @param cap_characters Whether to capitalize the first letter of elements of character vectors
#' @param comma_numbers Whether to include a comma between every three digits of numeric columns
#' @param date_format The format for printing date columns
#' @param round_digits How many digits to round numberic columns to
#' @param remove_row_names Whether to remove row names
#' @param remove_line_breaks Whether to remove line breaks from the elements of columns
#' @param nrows The number of rows to show
#' @param download_options Whether to show options for downloading the table
#' @param no_scroll Boolean. If TRUE, no horizontal scrolling.
#' @return A data table ready for inclusion into an HTML context (shiny / rmd)
#' @importFrom Hmisc capitalize
#' @importFrom DT datatable
#' @importFrom scales comma
#' @export

prettify <- function (the_table, remove_underscores_columns = TRUE, cap_columns = TRUE,
                      cap_characters = TRUE, comma_numbers = TRUE, date_format = "%B %d, %Y",
                      round_digits = 2, remove_row_names = TRUE, remove_line_breaks = TRUE,
                      data_table = TRUE, nrows = 5, download_options = FALSE, no_scroll = TRUE){
  column_names <- names(the_table)
  the_table <- data.frame(the_table)
  names(the_table) <- column_names
  classes <- lapply(the_table, function(x) {
    unlist(class(x))[1]
  })
  if (cap_columns) {
    names(the_table) <- Hmisc::capitalize(names(the_table))
  }
  if (remove_underscores_columns) {
    names(the_table) <- gsub("_", " ", names(the_table))
  }
  for (j in 1:ncol(the_table)) {
    the_column <- the_table[, j]
    the_class <- classes[j][1]
    if (the_class %in% c("character", "factor")) {
      if (cap_characters) {
        the_column <- as.character(the_column)
        the_column <- Hmisc::capitalize(the_column)
      }
      if (remove_line_breaks) {
        the_column <- gsub("\n", " ", the_column)
      }
    }
    else if (the_class %in% c("POSIXct", "Date")) {
      the_column <- format(the_column, format = date_format)
    }
    else if (the_class %in% c("numeric", "integer")) {
      the_column <- round(the_column, digits = round_digits)
      if (comma_numbers) {
        if(!grepl('year', tolower(names(the_table)[j]))){
          the_column <- scales::comma(the_column)
        }
      }
    }
    the_table[, j] <- the_column
  }
  if (remove_row_names) {
    row.names(the_table) <- NULL
  }
  if (data_table) {
    if (download_options) {
      if(no_scroll){
        the_table <- DT::datatable(the_table, options = list(#pageLength = nrows,
          scrollY = '300px', paging = FALSE,
          dom = "Bfrtip", buttons = list("copy", "print",
                                         list(extend = "collection", buttons = "csv",
                                              text = "Download"))), rownames = FALSE, extensions = "Buttons")
      } else {
        the_table <- DT::datatable(the_table, options = list(pageLength = nrows,
                                                             # scrollY = '300px', paging = FALSE,
                                                             dom = "Bfrtip", buttons = list("copy", "print",
                                                                                            list(extend = "collection", buttons = "csv",
                                                                                                 text = "Download"))), rownames = FALSE, extensions = "Buttons")
      }
      
    }
    else {
      if(no_scroll){
        the_table <- DT::datatable(the_table, options = list(#pageLength = nrows,
          scrollY = '300px', paging = FALSE,
          columnDefs = list(list(className = "dt-right",
                                 targets = 0:(ncol(the_table) - 1)))), rownames = FALSE)
      } else {
        the_table <- DT::datatable(the_table, options = list(pageLength = nrows,
                                                             columnDefs = list(list(className = "dt-right",
                                                                                    targets = 0:(ncol(the_table) - 1)))), rownames = FALSE)
      }
    }
  }
  return(the_table)
}


# Define function for generating all the radar charts in the ui
generate_radar_ui <- function(tab_name = 'organization_and_governance'){
  title <- simple_cap(gsub('_', ' ', tab_name))
  title <- convert_capitalization(title)
  paste0("tabPanel(title = '",title, "',column(2), box(title = '",title, "',
              status = 'info',
              collapsible = TRUE,
              width = 8,
              chartJSRadarOutput('", tab_name, "_chart')), column(2))")
}


# Define function for generating all the radar charts in the html
generate_radar_html <- function(rd, # radar data
                                tab_name = 'organization_and_governance'){
    make_radar_chart(rd,
                     tn = '", tab_name, "')
}