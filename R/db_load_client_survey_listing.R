db_load_client_survey_listing <- function(client_id = 1,
                                          pool){
  
  # Get the client data for the client_id in question
  cid <- client_id

  # Get the survey data associated with the client
  survey_data <-
    assessments %>%
    filter(client_id == cid)

  return(survey_data)
  
}