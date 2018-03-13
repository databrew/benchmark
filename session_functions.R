warning("LOADING SESSION FUNCTIONS")
#HELPER FUNCTIONS: get/set
#SESSION <- reactiveValues()
###LOGIN FUNCTIONS###
#loggedin <- function() { return(!is.null(SESSION$db_session_id) && SESSION$user_id >-1) }
#logout <- function() { SESSION <<- list();  return (!loggedin()) }





#HELPER FUNCTIONS: get/set
get_user_id <- function() { return(isolate(user_id())) }
get_user_name <- function() { return(isolate(user())) }

get_db_session_id <- function() { return(isolate(user_data$db_session_id)) }
get_current_client_id <- function() { return (isolate(user_data$current_client_id)) }
get_current_assessment_id <- function() { return (isolate(user_data$current_assessment_id)) }

get_client_listing <- function() { return(isolate(LISTINGS$client_listing)) }
get_client_assessment_listing <- function() { return(isolate(LISTINGS$client_assessment_listing)) }


get_current_assessment_info <- function() { return (subset(get_client_assessment_listing(),assessment_id==get_current_assessment_id())) }
get_current_assessment_data <- function() { return (isolate(ASSESSMENT$assessment_data)) }

assessment_has_new_data <- function()
{
  assessment_data <- get_current_assessment_data()
  if (identical(assessment_data,NA)) return(FALSE)
  return (any(assessment_data$is_changed))  
}

##TODO: Ensure only records changes if changes are actually made.  Ie, not setting 4 to 4 and same-text to same-text
record_assessment_data_entry <- function(question_id,score,rationale)
{
  client_id <- get_current_client_id()
  message('---client_id: ', client_id)
  assessment_id <- get_current_assessment_id()
  message('---assessment_id: ', assessment_id)
  if(is.na(assessment_id) | length(assessment_id) == 0){
    assessment_id <- -1
    message('------ forcing to: ', assessment_id)
  }
  
  
  if (!loggedin()) return(message("Warning: Not logged in"));
  if (is.null(client_id) | is.null(assessment_id)) return(message("Error: attempt to save data entry without current client/assessment"))
  
  assessment_data <- get_current_assessment_data()
  
  entry <- data.frame(client_id=nn(client_id),
                      assessment_id=nn(assessment_id),
                      question_id=nn(question_id),
                      last_modified_time=now(),
                      last_modified_user_id=get_user_id(),
                      last_modified_user_name=get_user_name(),
                      score=nn(score),
                      rationale=nn(rationale),
                      is_changed=TRUE)
  
  if (identical(assessment_data,NA)) #will happen if db_get_client_assessment_data is empty, on first assessment load
  {
    assessment_data <- entry
    
  } else {
    
    filter <- assessment_data$client_id==client_id & assessment_data$assessment_id==assessment_id & assessment_data$question_id==question_id
    #Means dataset already has answers to this question that user is changing, need to replace; remove it.  
    
    if (any(filter, na.rm = TRUE)) assessment_data <- assessment_data[!filter,] 
    assessment_data <- rbind(assessment_data,entry)
  }
  ASSESSMENT$assessment_data <- assessment_data
  
  return (assessment_data)
}


#Loads all client data (into a form) so that a user can edit it.
#sort of a useless function, kept to keep align with the .txt -- but we're basically loading all data with the client_listing
load_client <- function(client_id)
{

  cliet_info <- subset(get_client_listing(),client_id==client_id)
  if (nrow(client_info) != 1) return(message(paste0("Warning: unable to load client_id==",client_id," as ID does not exist in get_client_listing()")))
  
  user_data$current_client_id <- client_id

  #Set this reactiveVal (does it really need to be reactive though?)
  LISTINGS$client_assessment_listing <- db_get_client_assessment_listing(client_id)
  
  return (client_info)
}
unload_client <- function() { print('not implemented') }


load_client_assessment <- function(assessment_id)
{
  gcci <- get_current_client_id()
  message('gcci is ', gcci)
  if (is.null(gcci)) return(message("Error: No client is loaded.  Load client before loading assessment."))
  
  current_assessment <- subset(get_client_assessment_listing(),assessment_id==assessment_id)
  
  if (nrow(current_assessment) != 1) return(message(paste0("Error: Requested assessment ",assessment_id," not found!")))
  
  assessment_template <- db_get_client_assessment_data(gcci,assessment_id)
  
  #if(!all(is.na(assessment_template))) This will test if the contents of assessment_template are NA (many will be, where questions are left blank)
  if(!identical(assessment_template,NA)) #This will best if the object 'assessment_template' is NA, which it might be if the db_get_client_assessment_data call returns nadda
  {
    assessment_data <- assessment_template[,c("client_id","assessment_id","question_id","last_modified_time","last_modified_user_id","last_modified_user_name","score","rationale")]
    assessment_data$is_changed <- FALSE
    
    user_data$current_assessment_id <- assessment_id

    ASSESSMENT$assessment_template <- assessment_template
    ASSESSMENT$assessment_data <- assessment_data
    
    return (assessment_template)
  }
  
}

unload_client_assessment <- function() 
{
  ASSESSMENT$assessment_template <- NULL
  ASSESSMENT$assessment_data <- NULL
}
