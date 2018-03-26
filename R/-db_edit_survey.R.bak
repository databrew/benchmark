db_edit_survey <- function(#survey_id = 1,
                           #client_id = 1,
                           data,
                           pool){
  
  # Make sure that data matches the form in the database
  nd <- names(data) 
  correct_columns <- c('assessment_id',
                       'question_id',
                       'entry_time',
                       'entry_user_id',
                       'score',
                       'rationale')
  if(!all(nd == correct_columns)){
    stop(paste0('The data object should have the following column names only: ',
                paste0('\n---', correct_columns, collapse = '')))
  }
  
  # If it passed the above, then we'll delete the old stuff for this client/survey
  # and replace with the new stuff
  cc <- poolCheckout(pool)
  
  # For now, not dropping anything since it's all time-stamped anyway
  # # Loop through the each row of the new data, replacing appropriately
  # for(i in 1:nrow(data)){
  #   this_row <- data[i,]
  #   message('Dropping the following row from assessment_data:')
  #   print(this_row)
  #   # Delete the old stuff
  #   dbSendQuery(conn = cc,
  #               statement = paste0('DELETE FROM pd_dfsbenchmarking.assessment_data WHERE ',
  #                                  'assessment_id = ', this_row$assessment_id,
  #                                  ' AND question_id = ', this_row$question_id))
  # }
  # 
  # Add the new stuff (outside of the loop)
  dbWriteTable(cc, c("pd_dfsbenchmarking", "assessment_data"), 
               data, 
               append = TRUE, 
               row.names = FALSE)

  poolReturn(cc)
}