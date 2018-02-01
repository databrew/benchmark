# Libraries
library(tidyverse)
library(radarchart)
library(ggradar) # devtools::install_github('ricardo-bion/ggradar')
# library(d3radarR) # devtools::install_github("timelyportfolio/d3radarR")



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
               'Graphs')
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
    b[i] <- paste0("input_list[['", this_input, "']] <- 3;\n")
  }
  # Observe any changes and register them
  z <- rep(NA, length(inputs))
  for(i in 1:length(inputs)){
    this_input <- inputs[i]
    this_event <- paste0('input$', this_input)
    # Observe buttons rather than sliders
    this_observation <- gsub('_slider', '_submit', this_event)
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
  message('Hi Joe, list name is ', list_name)
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
              min = 1, 
              max = 5,
              value = val)
}

# Define function for creating a submit button to follow each slider
create_submit <- function(item_name, show_icon = FALSE){
  if(show_icon){
    actionButton(paste0(item_name, '_submit'),
                 label = 'Submitted',
                 icon = icon('check'))
  } else {
    actionButton(paste0(item_name, '_submit'),
                 label = 'Submit')
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
             observeEvent(input$', tab_name, '_', competencies[i], '_1_submit,{
             submissions$', tab_name, '_', competencies[i], '_1_submit <- TRUE})
             observeEvent(input$', tab_name, '_', competencies[i], '_2_submit,{
             submissions$', tab_name, '_', competencies[i], '_2_submit <- TRUE})
             observeEvent(input$', tab_name, '_', competencies[i], '_3_submit,{
             submissions$', tab_name, '_', competencies[i], '_3_submit <- TRUE})
             
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
    
    b[i] <- paste0("box(title = '", simple_cap(gsub('_', ' ', this_competency)), "',
        width = 12,
        solidHeader = TRUE,
        collapsible = TRUE,
        collapsed = ", tab_name, "_", this_competency, "_submitted(),
        column(4,
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
    )")
  }
  b <- paste0(b, collapse = ',')
  
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
  
  # Group by competency
  out <- vals_df %>%
    group_by(tab_name, competency) %>%
    summarise(value = mean(value, na.rm = TRUE)) %>%
    ungroup
  
  # Get in format for charting
  out$labs <- simple_cap(gsub('_', ' ', out$competency))
  out$scores <- out$value
  
  # Return 
  return(out)
}

# Define function for making radar chart
make_radar_chart <- function(data,
                             tn = 'organization_and_governance'){
  # Subset to the tab in question
  data <- data %>%
    filter(tab_name == tn)
  scores <- list(
    'Observed' = data$scores,
    'Best practice' = rep(5, nrow(data))
  )
  labs <- data$labs
  chartJSRadar(scores = scores, labs = labs, maxScale = 5,
               scaleStepWidth = 1,
               scaleStartValue = 1,
               responsive = TRUE,
               labelSize = 8,
               showLegend = TRUE,
               addDots = TRUE,
               showToolTipLabel = TRUE,
               colMatrix = t(matrix(c(col2rgb('darkorange'), col2rgb('lightblue')), nrow = 2, byrow = TRUE)))
}


# Define function for generating all the radar charts in the server
generate_radar_server <- function(tab_name = 'organization_and_governance'){
  paste0("output$", tab_name, "_chart <- renderChartJSRadar({
    data <- radar_data()
    make_radar_chart(data,
                     tn = '", tab_name, "')
  })")
}

# Define function for generating all the radar charts in the ui
generate_radar_ui <- function(tab_name = 'organization_and_governance'){
  title <- simple_cap(gsub('_', ' ', tab_name))
  paste0("box(title = '",title, "',
              status = 'info',
              collapsible = TRUE,
              width = 4,
              chartJSRadarOutput('", tab_name, "_chart'))")
}

# Define function for generating all the radar charts in the ui
# Not runnable, since each thing is separated by a comma
# generate_radar_ui2 <- function(tab_names){
#   out <- rep(NA, length(tab_names))
#   for(i in 1:length(tab_names)){
#     tab_name <- tab_names[i]
#     title <- simple_cap(gsub('_', ' ', tab_name))
#     x <- paste0("box(title = '",title, "',
#               status = 'danger',
#               collapsible = TRUE,
#               width = 4,
#               chartJSRadarOutput('", tab_name, "_chart'))")
#     out[i] <- x
#   }
#   out <- paste0(out, collapse = ',')
#   return(out)
# }
