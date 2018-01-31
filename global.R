# Libraries
library(tidyverse)

# Create a dictionary of tab names / numbers
tab_dict <- data_frame(number = 1:2,
                       name = c('main',
                                'about'))
n_tabs <- nrow(tab_dict)
