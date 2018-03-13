db_load_survey <- function(survey_id,pool){
  # Get assessment data for the survey id in question
  right <- 
    assessment_data %>%
    filter(assessment_id == survey_id) %>%
    # Arrange time to have most recent at top
    arrange(desc(entry_time)) %>%
    # Keep only one value for each assessment-question pair
    dplyr::distinct(assessment_id, question_id, .keep_all = TRUE)
  # Join to a full dataset of all questions
  left <- data_frame(question_id = 1:42)
  out <- left_join(left,
                   right, 
                   by = 'question_id') %>%
    mutate(assessment_id = survey_id)
  return(out)
}