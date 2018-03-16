print("LOADING SESSION FUNCTIONS")
#HELPER FUNCTIONS: get/set
#SESSION <- reactiveValues()
###LOGIN FUNCTIONS###
loggedin <- function() { return(!is.null(USER$db_session_id) && !is.null(USER$user_id) && USER$user_id >-1) }
#logout <- function() { SESSION <<- list();  return (!loggedin()) }

#HELPER FUNCTIONS: get/set
#Not sure if best to keep these in isolate() to ensure they don't trigger reactivity and to manually reference reactiveValues in the render functions, or to leave exposed to reactivity?
get_user_id <- function() { return(isolate(USER$user_id)) }
get_user_name <- function() { return(isolate(USER$user_name)) }

get_db_session_id <- function() { return((USER$db_session_id)) }
get_current_client_id <- function() { return ((USER$current_client_id)) }
get_current_assessment_id <- function() { return ((USER$current_assessment_id)) }

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
  if(is.na(question_id)){
    stop('question_id must not be NA.')
  }

  if (!loggedin()) return(message("Warning: Not logged in"))
  
  client_id <- get_current_client_id()
  assessment_id <- get_current_assessment_id()
  
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
    message('OLD ASSESSMENT CURRENT DATA ALREADY EXISTS')
    message('DOES AN ENTRY SCORE ALREADY EXIST FOR THIS QUESTION -- SHOULD NAs FROM TEMPLATE-READ-IN?')
    filter <- assessment_data$client_id==client_id & assessment_data$assessment_id==assessment_id & assessment_data$question_id==question_id
    message(paste('FILTER: ',any(filter)))
    #Means dataset already has answers to this question that user is changing, need to replace; remove it.  
    
    if (any(filter, na.rm = TRUE)) assessment_data <- assessment_data[!filter,] 
    assessment_data <- rbind(assessment_data,entry)
  }
  ASSESSMENT$assessment_data <<- assessment_data
  
  return (assessment_data)
}


refresh_client_listing <- function()
{
  if (is.null(get_db_session_id())) return(message("Unable to refresh client listing without a valid session ID"))
  
  LISTINGS$client_listing <- db_get_client_listing(get_db_session_id())
  return (get_client_listing())
}
refresh_client_assessment_listing <- function()
{
  if (is.null(get_db_session_id())) return(message("Unable to refresh client listing without a valid session ID"))
  if (is.null(get_current_client_id())) return(message("Unable to refresh client listing without a selected client"))
  
  LISTINGS$client_assessment_listing <<- db_get_client_assessment_listing(get_db_session_id(),get_current_client_id())
}
#Loads all client data (into a form) so that a user can edit it.
#sort of a useless function, kept to keep align with the .txt -- but we're basically loading all data with the client_listing
load_client <- function(selected_client_id)
{
  if (is.null(selected_client_id) || !is.numeric(as.numeric(selected_client_id))) return(warning(paste0("Warning: load_client bad input parameters for selected_client_id=",selected_client_id)))

  client_info <- subset(x=get_client_listing(),subset=client_id==selected_client_id)
  get_client_listing()
  if (nrow(client_info) != 1) return(message(paste0("Warning: unable to load client_id==",selected_client_id," as ID does not exist in get_client_listing()")))
  

  USER$current_client_id <<- selected_client_id

  #must be called after setting USER$current_client_id
  refresh_client_assessment_listing()
  
  return (client_info)
}
unload_client <- function() 
{ 
  if (assessment_has_new_data()) return (message("Cannot unload client while assessment is open with unsaved data"))
  USER$current_client_id <<- NULL
  LISTINGS$client_assessment_listing <<- NULL
}


load_client_assessment <- function(selected_assessment_id)
{
  if (is.null(selected_assessment_id) || !is.numeric(as.numeric(selected_assessment_id))) return(warning(paste0("Warning: load_client bad input parameters for selected_assessment_id=",selected_assessment_id)))
  
  if (is.null(get_current_client_id())) return(message("Error: No client is loaded.  Load client before loading assessment."))
  
  #Check to make sure selected_assessment exists!
  gccal <- get_current_client_assessment_listing()
  go <- FALSE
  if(!is.null(gccal)){
    if(length(gccal) > 0){
      current_assessment <- subset(gccal,subset=assessment_id==selected_assessment_id) 
      go <- TRUE
    }
  }
  if (go){
    if(nrow(current_assessment) != 1) return(message(paste0("Error: Requested assessment ",selected_assessment_id," not found!")))
  }

  print(paste0("load_client_assessment: ",get_db_session_id()," , ",get_current_client_id()," , ", selected_assessment_id))  
  assessment_template <- db_get_client_assessment_data(get_db_session_id(),get_current_client_id(),selected_assessment_id)
  


  if(!identical(assessment_template,NA)) #This will best if the object 'assessment_template' is NA, which it might be if the db_get_client_assessment_data call returns nadda
  {
    assessment_data <- assessment_template[,c("client_id","assessment_id","question_id","last_modified_time","last_modified_user_id","last_modified_user_name","score","rationale")]
    assessment_data$is_changed <- FALSE
    
    USER$current_assessment_id <<- selected_assessment_id

    ASSESSMENT$assessment_template <<- assessment_template
    ASSESSMENT$assessment_data <<- assessment_data
    print(paste0("LOADED! assessment: ",selected_assessment_id))
          
    return (assessment_template)
  }
  else
  {
    print(paste0("NOT LOADED: Client assessment is NA selected_assessmen_id=",selected_assessment_id))
    return (NA)
  }
}

save_assessment_data <- function()
{
  unsaved_assessment_data <- get_current_assessment_data()
  saved_assessment_data <- db_save_client_assessment_data(get_db_session_id(),unsaved_assessment_data)
  ASSESSMENT$assessment_data <<- saved_assessment_data
  return (saved_assessment_data)
}

unload_client_assessment <- function() 
{
  print("Unloading assessment")
  print("SAVING NEW DATA...just in case")
  save_assessment_data()
  
  ASSESSMENT$assessment_data <<- NULL
  ASSESSMENT$assessment_template <<- NULL
  USER$current_assessment_id <<- NULL
}

update_session <- function(status) {
  STATUS <<- status
  print(paste("Status updated to: ",STATUS))
}



call_db_login <- function()
{
  UI_LOGIN<-"MEL" #User input
  UI_PASS<-"FIGSSAMEL" #User input
  log_in_attempt <- db_login(UI_LOGIN,UI_PASS)
  USER$user_id <- log_in_attempt$user_id
  USER$user_name <- log_in_attempt$name
  USER$db_session_id <- log_in_attempt$session_id
  USER$current_client_id <- NULL #They didn't select one yet!  Must select from a list provided by client_listing
  USER$current_assessment_id <- NULL #They didn't select one yet!  Must (a) Select a client (b) Select from a list provided by client_assessment_listing
  
  LISTINGS$client_listing <- db_get_client_listing(get_db_session_id())
  
  print("Login Result")
  print(log_in_attempt)
}

call_load_client <- function()
{
  UI_SELECTED_CLIENT_ID <- get_client_listing()$client_id[1] #Auto-selects whatever is top-1 client
  print(paste0("You selected client_id=",UI_SELECTED_CLIENT_ID))
  client_info <- load_client(UI_SELECTED_CLIENT_ID) #CLIENT$client_info and LISTINGS$client_assessment_listing set in load_client()
  print(client_info)
  print(get_client_listing())
}

call_load_client_assessment <- function()
{
  UI_SELECTED_ASSESSMENT_ID <- get_current_client_assessment_listing()$assessment_id[1] #Auto-selects whatever is top-1 client
  print(paste0("You selected client_assessment_id=",UI_SELECTED_ASSESSMENT_ID))
  assessment_info <- load_client_assessment(UI_SELECTED_ASSESSMENT_ID) #CLIENT$client_info and LISTINGS$client_assessment_listing set in load_client()
  print(assessment_info[1,])
  
}
call_edit_assessment <- function()
{
  UI_SCORE <- ceiling(runif(1,0,7)) #From user input
  UI_QUESTION <- ceiling(runif(1,2,43)) #From user input
  UI_RATIONALE <- paste0("For question ",UI_QUESTION," ... I rate ",UI_SCORE)
  
  record_assessment_data_entry(question_id=UI_QUESTION,score=UI_SCORE,rationale=UI_RATIONALE)
}
call_save_and_close <- function()
{
  new_data <- get_current_assessment_data_changed()
  print("SAVING NEW DATA: ")
  print(new_data)
  saved <- db_save_client_assessment_data(get_db_session_id(),new_data)
  print(paste0("SAVED: ",nrow(saved)))
  
  unload_client_assessment()
  unload_client()
}