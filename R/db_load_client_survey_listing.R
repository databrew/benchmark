db_load_client_survey_listing <- function(client_id = 1,
                                          pool){
  
  # Get the client data for the client_id in question
  cid <- client_id
  client_data <- clients %>% 
    filter(client_id == cid)
  if(nrow(client_data) == 0){
    stop(paste0('No data in the clients table for client_id ', cid))
  }
  
  # Get the survey data associated with the client
  survey_data <-
    assessments %>%
    filter(client_id == cid)
  
  # (client_id,survey_id,survey_name,assessment_date)
  
}