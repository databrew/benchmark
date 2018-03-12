library(openxlsx)
library(RPostgreSQL)
library(yaml)
library(DBI)
library(pool)
library(lubridate)

SESSION <- list()
db_get_pool <- function()
{
  if (!exists("GLOBAL_DB_POOL") || get("GLOBAL_DB_POOL")$valid==FALSE)  GLOBAL_DB_POOL <<- create_pool(options_list = credentials_extract(),F)
  get("GLOBAL_DB_POOL")
}

db_disconnect <- function()
{
  open_conns <- dbListConnections (PostgreSQL())
  if (length(open_conns) > 0) mapply(dbDisconnect,open_conns)
  if (exists("GLOBAL_DB_POOL") && get("GLOBAL_DB_POOL")$valid) poolClose(get("GLOBAL_DB_POOL"))
}

###LOGIN FUNCTIONS###
loggedin <- function() { return(!is.null(SESSION$db_session_id) && SESSION$user_id >-1) }
logout <- function() { SESSION <<- list();  return (!loggedin()) }
db_session_id <- function() { return(SESSION$db_session_id) }
db_login <- function(username,password)
{
  conn <- poolCheckout(db_get_pool())
  login <- dbGetQuery(conn,"select * from pd_dfsbenchmarking.user_login( $1 , $2 )",params=list(username=username,password=password)) 
  poolReturn(conn)
  
  SESSION$user_id <<- login$user_id
  SESSION$user_name <<- login$name
  SESSION$db_session_id <<- login$session_id
  return (login)
}


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
  if(is.na(assessment_id)){
    assessment_id <- -1
  }
  
  if (!loggedin()) return(message("Warning: Not logged in"));
  if (is.null(client_id) | is.null(assessment_id)) return(message("Error: attempt to save data entry without current client/assessment"))
  
  assessment_data <- get_current_assessment_data()
  
  entry <- data.frame(client_id=client_id,
                      assessment_id=assessment_id,
                      question_id=question_id,
                      last_modified_time=now(),
                      last_modified_user_id=SESSION$user_id,
                      last_modified_user_name=SESSION$user_name,
                      score=score,
                      rationale=rationale,
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
  SESSION$client_info$current_assessment_data <<- assessment_data
  
  return (assessment_data)
}

db_save_client_assessment_data <- function()
{
  ll <- loggedin()
  ahnd <- assessment_has_new_data()
  if (!ll) return(message("Warning: Not logged in"));
  if (!ahnd) return (TRUE)
  
  assessment_data <- get_current_assessment_data()
  assessment_data$assessment_id <- get_current_assessment_id()

  saving_data <- subset(x=assessment_data,subset=is_changed==TRUE,select=c("client_id","assessment_id","question_id","last_modified_time","last_modified_user_id","score","rationale"))
  saving_data$assessment_id <- ifelse(is.na(saving_data$assessment_id), -1, saving_data$assessment_id)
  
  conn <- poolCheckout(db_get_pool())
  
  #There's a vague chance that multiple users will be writing to table concurrently -- so it's never deleted
  dbWriteTable(conn,name=c("public","_pd_dfsbenchmarking_save_client_assessment_data"),value=saving_data,append=TRUE,overwrite=FALSE)
  
  ##If table doesn't get deleted, just need to create this once in the DB and not via script
  ##dbSendQuery(conn,"create index if not exists _pd_dfsbenchmarking_save_client_assessment_data_index ON public._pd_dfsbenchmarking_save_client_assessment_data USING btree (assessment_id,question_id,last_modified_time);");
  message('______about to save data')
  rows_inserted <- dbGetQuery(conn,"select pd_dfsbenchmarking.assessments_data_save( $1 );",params=list(session_id=db_session_id()))
  poolReturn(conn)

  rows_expected <- sum(assessment_data$is_changed)
  rows_inserted <- as.numeric(unlist(rows_inserted))
  if (rows_expected != rows_inserted) message(paste0("Warning: Saving Assessment Data expected to save ",rows_expected," but reported ",rows_inserted," affected"))
  
  #Now that we've saved, un-mark it as is_changed and save back to the SESSION
  assessment_data$is_changed <- FALSE
  SESSION$client_info$current_assessment_data <<- assessment_data
  
  return (rows_inserted)  
}

db_get_client_assessment_data <- function(client_id,assessment_id)
{
  if (!loggedin()) return(message("Warning: Not logged in"));
  
  conn <- poolCheckout(db_get_pool())
  
  assessement_data <- NULL
  
  #assessment_data <- dbGetQuery(conn,'select client_id,assessment_id,question_id,last_modified_time,last_modified_user_id,last_modified_user_name,score,rationale,false as is_changed
  #                              from pd_dfsbenchmarking.view_assessments_current_data where assessment_id = $1 and client_id = $2
  #                              and pd_dfsbenchmarking.user_has_client_access(client_id,pd_dfsbenchmarking.user_id_session_chain( $3 ));',
  #                              params=list(assessment_id=assessment_id,
  #                                          client_id=client_id,
  #                                          session_id=db_session_id())) 
  
  #Changed to load the full set of assessment questions and data.  Only need the survey questions and layout at the time the assessment is being loaded
  #and someone wants to do it or view it
  assessment_data <- dbGetQuery(conn,'select * from pd_dfsbenchmarking.assessment_load( $1 , $2 , $3 )',
                                params=list(client_id=client_id,
                                            assessment_id=assessment_id,
                                            session_id=db_session_id())) 
                                
  #Any new assessment will have an empty dataset
  if (nrow(assessment_data)==0) assessment_data <- NA
  
  poolReturn(conn)
  return (assessment_data)
}

db_edit_client_assessment <- function(assessment_id,assessment_info)
{
  if (!loggedin()) return(message("Warning: Not logged in"));
  if (nrow(assessment_info) != 1) return(message("Error: Can only edit one client at a time"))
  
  conn <- poolCheckout(db_get_pool())
  assessment_info$assessment_date <- as.character(as.Date(assessment_info$assessment_date))
  
  assessment_id <- dbGetQuery(conn,'select pd_dfsbenchmarking.client_assessment_edit( $1 , $2 , $3 , $4 , $5 );',
                              params=list(session_id=db_session_id(),
                                          assessment_id=assessment_id,
                                          client_id=assessment_info$client_id,
                                          assessment_name=assessment_info$assessment_name,
                                          assessment_date=assessment_info$assessment_date)) 
  poolReturn(conn)
  return (unlist(assessment_id))
}

db_get_client_assessment_listing <- function(client_id)
{
  if (!loggedin()) return(message("Warning: Not logged in"));
  
  conn <- poolCheckout(db_get_pool())
  
  #eventually will add heirarchal user groups to allow managers to view all and/or all created by subordinates.  For now MEL does all. 
  listing <- dbGetQuery(conn,'select * from pd_dfsbenchmarking.view_client_assessment_listing
                        where pd_dfsbenchmarking.user_has_client_access(client_id,pd_dfsbenchmarking.user_id_session_chain( $1 ))',
                        params=list(session_id=db_session_id())) 
  poolReturn(conn)
  SESSION$client_assessment_listing <<- listing
  return (listing)
  
}
#Loads all client data (into a form) so that a user can edit it.
#sort of a useless function, kept to keep align with the .txt -- but we're basically loading all data with the client_listing
load_client <- function(client_id)
{
  client_info <- as.list(SESSION$client_listing[SESSION$client_listing$client_id == client_id,])
  
  client_assessments <- db_get_client_assessment_listing(client_id)
  
  #note, client_info has an 'assessments' value equal to assessments-count, which is overwritten by the actual retreived list
  client_info[["assessments"]] <- client_assessments 
  client_info$current_assessment_id <- NA
  client_info$current_assessment_data <- NA
  
  SESSION$client_info <<- client_info
  return (client_info)
}
get_current_client_id <- function() { return (SESSION$client_info$client_id) }
unload_client <- function() { SESSION$client_info <<- NULL }

load_client_assessment <- function(assessment_id)
{
  gcci <- get_current_client_id()
  message('gcci is ', gcci)
  if (is.null(gcci)) return(message("Error: No client is loaded.  Load client before loading assessment."))
  
  assessments <- SESSION$client_info$assessments
  current_assessment <- assessments[assessments$assessment_id==assessment_id,]
  
  if (nrow(current_assessment) != 1) return(message(paste0("Error: Requested assessment ",assessment_id," not found!")))
  
  assessment_template <- db_get_client_assessment_data(gcci,assessment_id)
  if(!all(is.na(assessment_template))){
    assessment_data <- assessment_template[,c("client_id","assessment_id","question_id","last_modified_time","last_modified_user_id","last_modified_user_name","score","rationale")]
    assessment_data$is_changed <- FALSE
    
    SESSION$client_info$current_assessment_id <<- current_assessment$assessment_id
    SESSION$client_info$current_assessment_template <<- assessment_template #does this need to change on load/unload since it's the same in all instances?  Does it matter?
    SESSION$client_info$current_assessment_data <<- assessment_data
    
    return (assessment_template)
  }
  
}
unload_client_assessment <- function() 
{
  SESSION$client_info$current_assessment_id <<- NULL
  SESSION$client_info$current_assessment_data <<- NULL
  SESSION$client_info$current_assessment_template <<- NULL
  
}
get_current_assessment <- function() { return (SESSION$client_info$assessments[SESSION$client_info$assessments$assessment_id==SESSION$client_info$current_assessment_id,]) }
get_current_assessment_id <- function() { return (SESSION$client_info$current_assessment_id) }
get_current_assessment_data <- function() { return (SESSION$client_info$current_assessment_data) }
get_client_assessments <- function()
{
  if (is.null(get_current_client_id())) return(message("Warning: Client must be loaded before accessing list of client assessments"))
  return(SESSION$client_info$assessments)
}

#Presented to users when they log in a list of clients whose surveys they can access, or whose details they can edit
db_get_client_listing <- function()
{
  if (!loggedin()) return(message("Warning: Not logged in"));
  
  conn <- poolCheckout(db_get_pool())
  
  #eventually will add heirarchal user groups to allow managers to view all and/or all created by subordinates.  For now MEL does all. 
  listing <- dbGetQuery(conn,'select * from pd_dfsbenchmarking.view_client_listing
                        where pd_dfsbenchmarking.user_has_client_access(client_id,pd_dfsbenchmarking.user_id_session_chain( $1 ))',
                        params=list(session_id=db_session_id())) 
  poolReturn(conn)
  SESSION$client_listing <<- listing
  return (listing)
}

#Edit/Update a client and/or create a new client.   When client_id==-1 flag to create new
db_edit_client <- function(client_id,client_info)
{
  if (!loggedin()) return(message("Warning: Not logged in"));
  if (nrow(client_info) != 1) return(message("Error: Can only edit one client at a time"))
  
  conn <- poolCheckout(db_get_pool())
  
  #eventually will add heirarchal user groups to allow managers to view all and/or all created by subordinates.  For now MEL does all. 
  client_id <- dbGetQuery(conn,'select pd_dfsbenchmarking.client_edit( $1 , $2 , $3, $4 , $5, $6 , $7 , $8 , $9 );',
                          params=list(session_id=db_session_id(),
                                      client_id=client_info$client_id,
                                      ifc_client_id=client_info$ifc_client_id,
                                      name=client_info$name,
                                      short_name=client_info$short_name,
                                      firm_type=client_info$firm_type,
                                      address=client_info$address,
                                      city=client_info$city,
                                      country=client_info$country)) 
  
  poolReturn(conn)
  
  return (unlist(client_id))
  
}
