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

# Heper function for printing tab layout into ui
print_menu_item <- function(i){
  cat(paste0('menuItem(
  text="', tab_dict$full_name[i],
'",
  tabName="', tab_dict$name[i], '",
  icon=icon("eye")),\n'))
}
for(i in 1:nrow(tab_dict)){
  print_menu_item(i)
}

print_tab_item <- function(i){
  cat(paste0('tabItem(
      tabName="', tab_dict$name[i], '",
      fluidPage()
    ),\n'))
}
for(i in 1:nrow(tab_dict)){
  print_tab_item(i)
}
