print("LOADING SESSION FUNCTIONS")
#HELPER FUNCTIONS: get/set
#SESSION <- reactiveValues()
###LOGIN FUNCTIONS###
loggedin <- function() { return(!is.null(user_data$db_session_id) && !is.null(user_data$user_id) && user_data$user_id >-1) }
#logout <- function() { SESSION <<- list();  return (!loggedin()) }





#HELPER FUNCTIONS: get/set
#Not sure if best to keep these in isolate() to ensure they don't trigger reactivity and to manually reference reactiveValues in the render functions, or to leave exposed to reactivity?
get_user_id <- function() { return(isolate(user_data$user_id)) }
get_user_name <- function() { return(isolate(user_data$user_name)) }

get_db_session_id <- function() { return((user_data$db_session_id)) }
get_current_client_id <- function() { return ((user_data$current_client_id)) }
get_current_assessment_id <- function() { return ((user_data$current_assessment_id)) }

get_client_listing <- function() { return((LISTINGS$client_listing)) }
get_current_client_info <- function() 
{ 
  if (is.null(get_client_listing()) || is.null(get_current_client_id())) return(NULL)
  return ((subset(x=get_client_listing(),subset=client_id==get_current_client_id()))) 
}
get_current_client_assessment_listing <- function() { return((LISTINGS$client_assessment_listing)) }



get_current_assessment_info <- function() 
{ 
  if (is.null(get_current_client_id()) || is.null(get_current_client_assessment_listing()) || is.null(get_current_assessment_id())) return (NULL)
  return (x=subset(get_current_client_assessment_listing(),subset=assessment_id==get_current_assessment_id())) 
}
get_current_assessment_template <- function() { return ((ASSESSMENT$assessment_template)) }
get_current_assessment_data <- function() { return ((ASSESSMENT$assessment_data)) }
get_current_assessment_data_changed <- function() {   return ((subset(ASSESSMENT$assessment_data,is_changed==TRUE))) }

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
  
  #took out the nn -- if there are nulls we should get to this point!  Should return errors above.   Also not permit NULL scoring, etc
  print(paste("[",client_id,"] [",assessment_id,"] [",question_id,"] [",now(),"] [",get_user_id(),"] [",get_user_name(),"] [",score,"] [",rationale,"]"))
  entry <- data.frame(client_id=client_id,
                      assessment_id=assessment_id,
                      question_id=question_id,
                      last_modified_time=now(),
                      last_modified_user_id=get_user_id(),
                      last_modified_user_name=get_user_name(),
                      score=score,
                      rationale=rationale,
                      is_changed=TRUE)
  
  if (identical(assessment_data,NA)) #will happen if db_get_client_assessment_data is empty, on first assessment load
  {
    print('NEW ASSESSMENT CURRENT DATA DOES NOT EXIST YET')
    assessment_data <- entry
    
  } else {
    print('OLD ASSESSMENT CURRENT DATA ALREADY EXISTS')
    print('DOES AN ENTRY SCORE ALREADY EXIST FOR THIS QUESTION -- SHOULD NAs FROM TEMPLATE-READ-IN?')
    filter <- assessment_data$client_id==client_id & assessment_data$assessment_id==assessment_id & assessment_data$question_id==question_id
    print(paste('FILTER: ',any(filter)))
    #Means dataset already has answers to this question that user is changing, need to replace; remove it.  
    
    if (any(filter, na.rm = TRUE)) assessment_data <- assessment_data[!filter,] 
    assessment_data <- rbind(assessment_data,entry)
  }
  ASSESSMENT$assessment_data <- assessment_data
  
  return (assessment_data)
}


#Loads all client data (into a form) so that a user can edit it.
#sort of a useless function, kept to keep align with the .txt -- but we're basically loading all data with the client_listing
load_client <- function(selected_client_id)
{

  client_info <- subset(x=get_client_listing(),subset=client_id==selected_client_id)
  print(get_client_listing())
  print(client_info)
  if (nrow(client_info) != 1) return(message(paste0("Warning: unable to load client_id==",selected_client_id," as ID does not exist in get_client_listing()")))
  

  user_data$current_client_id <<- selected_client_id

  #CLIENT$client_info <<- client_info
  LISTINGS$client_assessment_listing <<- db_get_client_assessment_listing(get_db_session_id(),selected_client_id)
  
  return (client_info)
}
unload_client <- function() 
{ 
  if (assessment_has_new_data()) return (message("Cannot unload client while assessment is open with unsaved data"))
  user_data$current_client_id <<- NULL
  LISTINGS$client_assessment_listing <<- NULL
}


load_client_assessment <- function(selected_assessment_id)
{
  
  if (is.null(get_current_client_id())) return(message("Error: No client is loaded.  Load client before loading assessment."))
  
  #Check to make sure selected_assessment exists!
  current_assessment <- subset(get_current_client_assessment_listing(),subset=assessment_id==selected_assessment_id) 
  if (nrow(current_assessment) != 1) return(message(paste0("Error: Requested assessment ",selected_assessment_id," not found!")))

  print(paste0("load_client_assessment: ",get_db_session_id()," , ",get_current_client_id()," , ", selected_assessment_id))  
  assessment_template <- db_get_client_assessment_data(get_db_session_id(),get_current_client_id(),selected_assessment_id)
  


  if(!identical(assessment_template,NA)) #This will best if the object 'assessment_template' is NA, which it might be if the db_get_client_assessment_data call returns nadda
  {
    assessment_data <- assessment_template[,c("client_id","assessment_id","question_id","last_modified_time","last_modified_user_id","last_modified_user_name","score","rationale")]
    assessment_data$is_changed <- FALSE
    
    user_data$current_assessment_id <<- selected_assessment_id

    ASSESSMENT$assessment_template <<- assessment_template
    ASSESSMENT$assessment_data <<- assessment_data
    print(paste0("LOADED! assessment: ",selected_assessment_id))
          
    return (assessment_template)
  }
  else print("NOT LOADED")
  
}

unload_client_assessment <- function() 
{
  print("Unloading assessment")
  print("SAVING NEW DATA...just in case")
  db_save_client_assessment_data(get_db_session_id(),get_current_assessment_data_changed())
  
  ASSESSMENT$assessment_data <<- NULL
  ASSESSMENT$assessment_template <<- NULL
  user_data$current_assessment_id <<- NULL
}
