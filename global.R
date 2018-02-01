# Libraries
library(tidyverse)

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

# # Heper functions for printing tab layout into ui
# print_menu_item <- function(i){
#   cat(paste0('menuItem(
#   text="', tab_dict$full_name[i],
# '",
#   tabName="', tab_dict$name[i], '",
#   icon=icon("eye")),\n'))
# }
# for(i in 1:nrow(tab_dict)){
#   print_menu_item(i)
# }
# 
# print_tab_item <- function(i){
#   cat(paste0('tabItem(
#       tabName="', tab_dict$name[i], '",
#       fluidPage()
#     ),\n'))
# }
# for(i in 1:nrow(tab_dict)){
#   print_tab_item(i)
# }

# So as to avoid flooding the ui, create a dictionary of text to be placed in the ui
source('ui_dict.R')  

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

# Define function for creating a 1-5 slider for a given item
create_slider <- function(item_name){
  sliderInput(paste0(item_name, '_slider'),
              'Score',
              min = 1, 
              max = 5,
              value = 3)
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
               create_slider('", tab_name, "_", this_competency, "_1'),
               create_submit('", tab_name, "_", this_competency, "_1', 
                             show_icon = submissions$", tab_name, "_", this_competency, "_1_submit)),
        column(4,
               p(get_ui_text('", tab_name, "_", this_competency, "_2')),
               create_slider('", tab_name, "_", this_competency, "_2'),
               create_submit('", tab_name, "_", this_competency, "_2',
                             show_icon = submissions$", tab_name, "_", this_competency, "_2_submit)),
        column(4,
               p(get_ui_text('", tab_name, "_", this_competency, "_3')),
               create_slider('", tab_name, "_", this_competency, "_3'),
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
