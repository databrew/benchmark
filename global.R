# Libraries
library(dplyr)
library(tidyr)
library(ggplot2)
library(readr)
library(radarchart)
library(shinyWidgets)
library(DBI)
library(RPostgreSQL)
library(yaml)
library(pool)
library(lubridate)
library(shiny)
functions <- dir('R')
for (i in 1:length(functions)){
  source(paste0('R/', functions[i]), chdir = TRUE)
}
source('session_functions.R', local = TRUE)

# Define function for converting numeric values to 1 of the 3 categories
convert_to_category <- function(number = 0){
  ifelse(number < 1,
         0,
         ifelse(number <3,
                1,
                ifelse(number <= 5.5,
                       2, 
                       3)))
}

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
  inputs <- paste0(competency_dict$combined_name, '_slider')
  qualys <- paste0(competency_dict$combined_name, '_qualy')
  buttons <- paste0(competency_dict$combined_name, '_next_competency')
  b <- rep(NA, length(inputs))
  counter <- 0
  for(i in 1:length(inputs)){
    this_input <- inputs[i]
    this_qualy <- qualys[i]
    v <- 0
    counter <- counter + 1
    b[counter] <- paste0("input_list[['", this_input, "']] <- ", v, ";\n")
    counter <- counter + 1
    b[counter] <- paste0("input_list[['", this_qualy, "']] <- '';\n")
  }
  # Observe any changes to slider and then register  them
  x <- z <- y <- v <- u <-    rep(NA, length(inputs))
  for(i in 1:length(inputs)){
    this_input <- inputs[i]
    this_qualy <- qualys[i]
    this_cn <- gsub('_slider', '', this_input)
    this_question_id <- competency_dict %>% dplyr::filter(combined_name == this_cn) %>% .$question_id;
    this_event <- paste0('input$', this_input)
    this_event_qualy <- gsub('_slider', '_qualy', this_event)
    # # Observe buttons rather than sliders
    # this_observation <- gsub('_slider', '_submit', this_event)
    # Observe sliders rather than buttons
    this_observation <- this_event
    this_observation_qualy <- this_event_qualy
    this_button <- paste0('input$',buttons[i])
    
    # Observe the sliders and update the input list for scores
    x[i] <- 
      paste0("observeEvent(",this_observation,", { ;
             input_list[['", this_input, "']] <- ", this_event,"});\n")
    
    # Observe the press here when done and update the input list for text
    v[i] <-
      paste0("observeEvent(",this_button,", { ;
             input_list[['", this_qualy, "']] <- ", this_event_qualy,"});\n")
    # Observe the sliders and update the input list for text
    y[i] <- 
      paste0("observeEvent(",this_observation,", { ;
             input_list[['", this_qualy, "']] <- ", this_event_qualy,"});\n")
    
    
    # Save the data upon slider move
    z[i] <- 
      paste0("observeEvent(",this_observation,", { ;
              if(", this_event, " > 0.5){
                record_assessment_data_entry(question_id=",this_question_id, ",score=", this_event, ",rationale=", this_event_qualy,");
                # Force a re-load of assessment data
                cc <- counter()
                cc <- cc + 1
                counter(cc)
                message('Counter increased to ', cc)
                save_assessment_data()
              }
  });\n")
    
    # Save the data upon next competency button click move
    u[i] <- 
      paste0("observeEvent(",this_button,", { ;
                record_assessment_data_entry(question_id=",this_question_id, ",score=", this_event, ",rationale=", this_event_qualy,");
                # Force a re-load of assessment data
                cc <- counter()
                cc <- cc + 1
                counter(cc)
                message('Counter increased to ', cc)
                save_assessment_data()

  });\n")
  }
  
  paste0(a,
         paste0(b,
                x, 
                v,
                u,
                y,
                z, collapse = ''),
         collapse = '')
}

slider_label_values <- list(A = c('Unrated', 'Emerging', '&nbsp;', '&nbsp;' , '&nbsp;' , '&nbsp;','Formative','&nbsp;','&nbsp;','Developed','&nbsp;','Best Practice'),
               B = c('&nbsp;', 'Emerging', '&nbsp;', '&nbsp;' , '&nbsp;' , '&nbsp;','Formative','&nbsp;','&nbsp;','Developed','&nbsp;','&nbsp;'))

# Define function for creating a slider for a given item
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
    # print(sort(names(ip)))
    val <- 0
  }
  
  
  
  sliderInput(paste0(item_name, '_slider'),
              'Score (1-7)',
              min = 0, 
              max = 7,
              value = val,
              step = 0.5)
}

# Define function for creating text input below slider (qualitative )
create_qualy <- function(item_name,
                          ip){
  
  list_name <- paste0(item_name, '_qualy')
  ip <- reactiveValuesToList(ip)
  ip <- unlist(ip)
  
  if(list_name %in% names(ip)){
    val <- ip[names(ip) == list_name]
  } else {
    message('PROBLEM')
    message(' this is list name: ', list_name)
    message('it is not in names of ip: ')
    # print(sort(names(ip)))
    val <- ''
  }
  
  textAreaInput(paste0(item_name, '_qualy'),
            label = 'Qualitative rationale',
            cols = 6,
            rows = 2,
            value = val,
            placeholder = 'Type here a rationale for your evaluation score.',
            # placeholder = ifelse(val == '',
            #                      'Add a reason or commentary pertaining to the selected score.',
            #                      NULL),
            resize = 'vertical')
}



# Define function for creating a submit button to follow each slider
create_submit <- function(item_name, show_icon = FALSE){
  if(show_icon){
    icon("check", "fa-3x")
  } else {
    icon('exclamation-circle', 'fas fa-spinner fa-pulse')
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
             submissions$', tab_name, '_', competencies[i], '_submit <- FALSE; # NEW ONE!
             
            # Upon change of assessment, set all submissions back to false 
            observeEvent(c(input$assessment), { 
                submissions$', tab_name, '_', competencies[i], '_submit <- FALSE
            })
  
             # Create reactive colors
             ', tab_name, '_', competencies[i], '_colors <- reactiveValues()
             ', tab_name, '_', competencies[i], '_colors[["a"]] <- "black"
             ', tab_name, '_', competencies[i], '_colors[["b"]] <- "black"
             ', tab_name, '_', competencies[i], '_colors[["c"]] <- "black"
             
             # Observe submissions
             observeEvent(input$', tab_name, '_', competencies[i], '_slider,{
             if(input$', tab_name, '_', competencies[i], '_slider >= 1){
             submissions$', tab_name, '_', competencies[i], '_submit <- TRUE
             # Colors
             x <- input$', tab_name, '_', competencies[i], '_slider
             new_value <- convert_to_category(x)
             lt <- letters[new_value]
             other_letters <- letters[1:3][letters[1:3] != lt]
             ', tab_name, '_', competencies[i], '_colors[[lt]] <- ifelse(new_value == 1, "red", ifelse(new_value == 2, "orange", "green"))
             ', tab_name, '_', competencies[i], '_colors[[other_letters[1]]] <- "black"
             ', tab_name, '_', competencies[i], '_colors[[other_letters[2]]] <- "black"
             } else {
              ', tab_name, '_', competencies[i], '_colors[["a"]] <- "black"
              ', tab_name, '_', competencies[i], '_colors[["b"]] <- "black"
              ', tab_name, '_', competencies[i], '_colors[["c"]] <- "black"
             }
             })
             
             # Reactives saying whether the entire competency has been submitted
             ', tab_name, '_', competencies[i], '_submitted <- reactive({
             x <- submissions$', tab_name, '_', competencies[i], '_submit;
             x
             })')
  }
  paste0(out, collapse = '\n')
  }

# Function to observe when an entire sub_tab gets submitted and move the sub_tab accordingly
sub_tab_completer <- function(){
  submission_objects <- paste0(competency_dict$combined_name, '_submitted()')
  sub_tabs <- convert_capitalization(simple_cap(gsub('_', ' ', competency_dict$competency)))
  tabs <- competency_dict$tab_name
  competency_objects <- paste0('input$', competency_dict$combined_name, '_next_competency')
  out <- list()
  for(i in 1:length(competency_objects)){
    # for(i in 1:length(submission_objects)){
    out[[i]] <- 
      paste0(
        "observeEvent(", 
        # The below observes the completion of the sub-tab
        #submission_objects[i], ", { 
        
        # Alternative is to observe the click ofthe action button
        competency_objects[i], ", {
        
        sts <- sub_tab_selected();
        # sm <- ", submission_objects[i], "
        
        # Action button approach
        sm <- TRUE
        message('Clicked the -press here when done- button')
        
        if(is.null(sts)){
        mt <- main_tab(); 
        x <- competency_dict %>% 
        filter(tab_name == mt) %>% 
        mutate(competency = convert_capitalization(simple_cap(gsub('_', ' ', competency)))) %>% 
        .$competency;
        sts <- x[1]
        message('---new sts is ', sts)
        
        }
        if(!is.null(sts)){
        if(sm & sts == '", sub_tabs[i], "'){
        this_tab <- '", tabs[i], "'
        this_sub_tab <- '", sub_tabs[i], "'
        next_tab <- '", tabs[i + 1], "'
        next_sub_tab <- '", sub_tabs[i + 1], "'
        df <- data.frame(name = c('this_tab', 'this_sub_tab', 'next_tab', 'next_sub_tab'), val = this_tab, this_sub_tab, next_tab, next_sub_tab);
        if(next_tab != this_tab){
        main_tab(next_tab);# navPage(1)
        sub_tab_selected(next_sub_tab)
        } else {
        sub_tab_selected(next_sub_tab)
        }
        }
        } else {
        message('WEIRD, STS IS NULL')
        }
        
  })"
      )
}
  out <- unlist(out)
  out <- paste0(out, collapse = ';\n')
  return(out)
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
  a <- ''
  # Each box
  b <- rep(NA, n_competencies)
  g <- b
  for(i in 1:n_competencies){
    this_competency <- competencies[i]
    this_combined_name <- paste0(tab_name, '_', this_competency)
    this_title <- convert_capitalization(simple_cap(gsub('_', ' ', this_competency)))
    competency_done <- paste0(tab_name, "_", this_competency, "_submitted()")
    selection_phrase <- paste0('(sts != "', this_title,'")')
    # collapsed <- paste0('any(', competency_done , ', ', selection_phrase, ', na.rm = TRUE)')
    collapsed <- selection_phrase
    if(length(collapsed) < 1){
      collapsed <- 'FALSE'
    }
    
    # Define colors
    colors_one <- paste0(tab_name, '_', competencies[i], '_colors[["a"]]')
    colors_two <- paste0(tab_name, '_', competencies[i], '_colors[["b"]]')
    colors_three <- paste0(tab_name, '_', competencies[i], '_colors[["c"]]')
    
    g[i] <- 
      paste0("tags$head(tags$script(HTML(make_js_slider('", this_combined_name,  "')))),")
    
    b[i] <- paste0("box(title = p(paste0('", this_title, "', ifelse(", competency_done, ", ' (Done)', ''))),        width = 12,
                   solidHeader = TRUE,
                   collapsible = TRUE,
                   collapsed = ", collapsed,  ",
                   ",
                   # collapsed = ", competency_done, ",
                   "style = \"overflow-y:scroll; max-height: 400px\",fluidPage(",
                   "fluidRow(column(1), 
                    
                    column(10,create_slider('", tab_name, "_", this_competency, "', 
                            ip = input_list)), column(1, create_submit('", tab_name, "_", this_competency, "', 
                   show_icon = ", competency_done, "))),",
                   "fluidRow(column(12, create_qualy('", tab_name, "_", this_competency, "', ip = input_list))),",
                   "fluidRow(column(3), ",
                   # "column(3)",
                   "column(6, align = 'center', actionButton('", paste0(tab_name, "_", this_competency, "_next_competency"), "', 'Press here when done')), column(3)",
                   "),",
                   
                   
                   "fluidRow(column(4, span(h4('", paste0('Emerging ', convert_capitalization(simple_cap(gsub('_', ' ', this_competency))), ''), "'), style= paste0('color:',", colors_one, "))), 
                   column(4, span(h4('", paste0('Formative ', convert_capitalization(simple_cap(gsub('_', ' ', this_competency))), ''), "'), style= paste0('color:',", colors_two, "))),
                   column(4, span(h4('", paste0('Developed ', convert_capitalization(simple_cap(gsub('_', ' ', this_competency))), ''), "'), style= paste0('color:',", colors_three, ")))),",
                   "fluidRow(column(4, span(p(get_ui_text('", tab_name, "_", this_competency, "_1')), style= paste0('color:',", colors_one, "))), 
                   column(4, span(p(get_ui_text('", tab_name, "_", this_competency, "_2')), style= paste0('color:',", colors_two, "))),
                   column(4, span(p(get_ui_text('", tab_name, "_", this_competency, "_3')), style= paste0('color:',", colors_three, "))))",
                   "))")
  }
  b <- paste0(b, collapse = ',')
  g <- paste0(g, collapse = '\n')
  # in g, replace the last character (comma) with a semi colon
  
  
  out <- 
    paste0("output$",tab_name, "_ui <- ",
           "renderUI({",
           "sts<- sub_tab_selected(); 
           # if going to next tab, sts will be nothing...
           if(length(sts) < 1){mt <- main_tab(); 
           x <- competency_dict %>% filter(tab_name == mt) %>% mutate(competency = convert_capitalization(simple_cap(gsub('_', ' ', competency)))) %>% .$competency;
           sts <- x[1]
           };",
           'div(',
           g,
            # "if(length(sts) < 1){sts <- convert_capitalization(simple_cap(gsub('_', ' ', competencies)))[1]};",
           "fluidPage(",
           a,
           b,
           "))})")
  return(out)
}

# Generate modals for adding comments
generate_modals <- function(){
  button_names <- competency_dict$combined_name
  out <- list()
  for(i in 1:length(button_names)){
    this_tab_name <- button_names[i]
    comment_name <- paste0('comment_', this_tab_name)
    out[[i]] <- paste0('observeEvent(input$show_', this_tab_name, ', { message("MODAL TIME");
                       x <- sub_tab_selected()
                       message("Sub tab selected worked and it is ", x);
                       showModal(modalDialog(title = paste0("Entering a qualitative rationale on the rating for ", x), footer = modalButton("Submit"),
                       easyClose = TRUE, 
                       fluidPage(fluidRow(textInput("', comment_name, '", label = "")))))
  })')
  }
  out <- unlist(out)
  out <- paste0(out, collapse = '\n')
  return(out)
}

# Text for observing all of the sub_tab selections
observe_sub_tab <- function(){
  cn <- competency_dict$tab_name
  cn <- unique(cn)
  cnt <- paste0('sub_tab_', cn)
  sub_tabs <- paste0('input$', cnt)
  out <- list()
  for(i in 1:length(sub_tabs)){
    this_sub_tab <- sub_tabs[i]
    this_name <- cnt[i]
    out[[i]] <- paste0("observeEvent({",this_sub_tab,"; input$tabs}, { #message('The following sub_tab id was just clicked: ", cnt[i],"' );
                       sub_tab_selected(", this_sub_tab,");
                       #message('---Overwriting the sub_tab_selected with: ', sub_tab_selected())
  });"
    )
}
  out <- unlist(out)
  out <- paste0(out, collapse = '\n')
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
    data.frame(combined_name = combined_names)
  # Get broken down names from dict
  vals_df <- left_join(vals_df,
                       competency_dict,
                       by = 'combined_name')
  vals_df$value <- NA
  vals_df$value_name <- paste0(vals_df$combined_name, '_slider')
  for(i in 1:nrow(vals_df)){
    the_name <- vals_df$value_name[[i]]
    the_value <- ip[names(ip) == the_name]
    the_value <- as.numeric(the_value)
    vals_df$value[i] <- the_value
  }
  
  # Group by competency and get weighted score
  out <- vals_df %>%
    dplyr::select(tab_name, competency, value)
  
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
                             label_size = 9,
                             height = NULL,
                             gg = FALSE){
  # Subset to the tab in question
  data <- data %>%
    filter(tab_name == tn) %>%
    # Arrange alphabetically
    arrange(labs)
  scores <- list(
    'This Bank' = data$scores,
    'Best Practice' = rep(7, nrow(data))
  )
  labs <- data$labs
  if(gg){
    pd <- data %>%
      dplyr::select(labs, scores) %>%
      mutate(group = 'This bank') %>%
      mutate(scores = ifelse(is.na(scores), 0, scores))
    benchmark <- pd %>%
      mutate(scores = 7,
             group = 'Benchmark')
    pd <- bind_rows(pd, benchmark) %>% mutate(scores = scores)
    pd <- pd %>% spread(key = labs, value = scores)
    # pd$group <- gsub(' ', '\n', pd$group)
    names(pd) <- gsub(' ', '\n', names(pd))
    ggradar(plot.data = pd,
            axis.label.size = 3,
            grid.max = 7,
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
    # load('~/Desktop/chart.RData')
    labsx <- rep(NA, length(labs))
    for(i in 1:length(labs)){
      out <- labs[i]
      splote <- unlist(strsplit(out, ' '))
      n_words <- length(splote)
      if(n_words > 2){
        out <- paste0(paste0(splote[1:2], collapse = ' '), '...', collapse = '')
      }
      labsx[i] <- out
      # out <- gsub(' ', '\n', labs[i])
      # words <- strsplit(labs[i], ' ')
      # out <- lapply(words, function(x){paste0('["', x, '"]')})
      # out <- unlist(out)
      # out <- paste0('[', paste0(out, collapse = ','), ']')
      labsx[i] <- out
    }
    show_legend <- tn == 'strategy_and_execution'
  chartJSRadar(scores = scores, labs = labsx, maxScale = 7,
                      height = height,
                      scaleStepWidth = 1,
                      scaleStartValue = 0,
                      responsive = TRUE,
                      labelSize = label_size,
                      showLegend = show_legend,
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
  paste0("box(title = '",title, "',
         status = 'info',
         collapsible = TRUE,
         width = 6,
         fluidPage(fluidRow(column(12, align = 'center', chartJSRadarOutput('", tab_name, "_chart'), br(), downloadButton(paste0('download_', '", tab_name, "', '_chart'), 'Download chart')))))")
}

# Define function for generating the donwload handlers
generate_download_handlers <- function(tab_name = 'organization_and_governance'){
  paste0("output$download_", tab_name, "_chart <- downloadHandler(
    filename = function() { paste('chart', '.png', sep='') },
    content = function(file) {
      rd <- radar_data()
      make_radar_chart(rd, tn = '", tab_name, "', label_size = 14, height = 250, gg = TRUE)
      device <- function(..., width, height) grDevices::png(..., width = width, height = height, res = 300, units = 'in')
        ggsave(file, device = device)
      
         })")
}


# Define function for generating all the radar charts in the html
generate_radar_html <- function(rd, # radar data
                                tab_name = 'organization_and_governance'){
  make_radar_chart(rd,
                   tn = '", tab_name, "')
}

# Define functions for generating menus
generate_menu <- function(done = FALSE,
                          icon = 'user',
                          text = 'Some name',
                          tabName = 'some_name',
                          submissions,
                          pass = FALSE,
                          selected = NULL,
                          mt = '',
                          loggedin = TRUE,
                          sub = FALSE,
                          it = NULL){
  if(!loggedin & !pass){
    return(NULL)
  } else if(!loggedin & (grepl('graph', tabName) | grepl('configur', tabName))){
    return(NULL)
  } else {
    if(mt == tabName){
      selected <- TRUE
    } else {
      selected<- FALSE
    }
    
    if(pass){
      menuItem(
        text = text,
        tabName = tabName,
        icon = icon,
        selected = selected)
    } else {
      subs <- reactiveValuesToList(submissions)
      subs <- unlist(subs)
      
      # See if the entire tab's competencies have been submitted
      if(!tabName %in% c('instructions', 'graphs', 'about'))
        these_competencies <- competency_dict %>%
        filter(tab_name == tabName) %>%
        .$combined_name
      these_competencies <- paste0(these_competencies, '_submit')
      these_competencies <- subs[names(subs) %in% these_competencies]
      all_ok <- all(these_competencies)
      done <- FALSE
      if(exists('these_competencies')){
        if(length(these_competencies) > 0){
          if(all_ok){
            message('Everything is done for ', tabName, '.')
            
            done <- TRUE
          }
        }
      }
      
      if(done){
        bl <- 'Done'
        bc <- 'green'
      } else {
        bl <- 'To do'
        bc <- 'red'
      }
      # Color the selected tab orange
      if(!is.null(it)){
        if(it == tabName){
          text <- span(text, style = 'color:orange')
        }
      }
      if(sub){
        div(style="margin-left:45px;margin-bottom: 10px; margin-right: 10px",
            menuItem(
              text = text,
              tabName = tabName,
              icon = icon,
              badgeLabel = bl,
              badgeColor = bc,
              selected = selected)
            
            )
      } else {
        menuItem(
          text = text,
          tabName = tabName,
          icon = icon,
          badgeLabel = bl,
          badgeColor = bc,
          selected = selected)
      }
      
    }
  }
}

# Define the log in modal
log_in_modal <- 
  modalDialog(
    title = "Log in",
    fluidPage(
      fluidRow(column(12,
                      textInput('user_name', 'User name', value = 'MEL')),
               column(12,
                      textInput('password', 'Password', value = 'FIGSSAMEL')))
    ),
    easyClose = TRUE,
    footer = action_modal_button('log_in_submit', "Submit", icon = icon('check-circle')),
    size = 's'
  )
   


# Database set-up
pool <- create_pool(options_list = credentials_extract(),
                    use_sqlite = FALSE)
# # Get the data from the db into memory
db_to_memory(pool = pool)

# # Fix the agile process / agile processes inconsistency
# if('agile_process' %in% view_assessment_questions_list$competency){
#   view_assessment_questions_list$competency[view_assessment_questions_list$competency == 'agile_process'] <-
#     'agile_processes'
# }

# get the question ids into the competency dict
competency_dict <-
  left_join(competency_dict,
            view_assessment_questions_list %>%
              dplyr::select(combined_name,
                            question_id),
            by = 'combined_name')

# Define some javascript for the categorical sliders
make_js_slider <- function(tn){
  tn <- paste0(tn, '_slider')
      paste0(
        "$(function() {
setTimeout(function(){
var names = ['Unrated', 'Formative (1)', '(2)',  'Emerging (3)', '(4)', '(5)', 'Developed (6)', '(7)'];
var vals = names;
$('#", tn, "').data('ionRangeSlider').update({'values':vals})
}, 7)})"
      )
}
