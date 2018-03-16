#########################
### CONNECTION GROUPS ###
#########################

db_disconnect <- function()
{
  open_conns <- dbListConnections (PostgreSQL())
  if (length(open_conns) > 0) mapply(dbDisconnect,open_conns)
  if (exists("GLOBAL_DB_POOL") && get("GLOBAL_DB_POOL")$valid) 
  {
    poolClose(get("GLOBAL_DB_POOL"))
    rm("GLOBAL_DB_POOL")
  }
}

db_get_pool <- function()
{
  if (!exists("GLOBAL_DB_POOL") || get("GLOBAL_DB_POOL")$valid==FALSE)
  {
    print('Creating Global Pool Object')
    db_disconnect()    
    GLOBAL_DB_POOL <<- create_pool(options_list = credentials_extract(),FALSE)
  }
  get("GLOBAL_DB_POOL")
}


####################
### LOGIN GROUPS ###
####################

#On success will return: user_id int, name varchar, session_id varchar
#On fail will return: user_id == -1, name == NA, session_id == NA
db_login <- function(username,password)
{
  conn <- poolCheckout(db_get_pool())
  login <- dbGetQuery(conn,"select * from pd_dfsbenchmarking.user_login( $1 , $2 )",params=list(username=username,password=password)) 
  poolReturn(conn)
  
  return (login)
}

#####################
### CLIENT GROUPS ###
#####################

#Presented to users when they log in a list of clients whose surveys they can access, or whose details they can edit
db_get_client_listing <- function(db_session_id)
{
  #if (!loggedin()) return(message("Warning: Not logged in"));
print(paste0("debug: Getting db_ge_client_listing with ",db_session_id))
  conn <- poolCheckout(db_get_pool())
  
  #eventually will add heirarchal user groups to allow managers to view all and/or all created by subordinates.  For now MEL does all. 
  listing <- dbGetQuery(conn,'select * from pd_dfsbenchmarking.view_client_listing
                        where pd_dfsbenchmarking.user_has_client_access(client_id,pd_dfsbenchmarking.user_id_session_chain( $1 ))',
                        params=list(session_id=db_session_id)) 
  poolReturn(conn)
  #SESSION$client_listing <<- listing
  return (listing)
}

#Edit/Update a client and/or create a new client.   When client_id==-1 flag to create new
db_edit_client <- function(db_session_id,client_id,client_info)
{
  #if (!loggedin()) return(message("Warning: Not logged in"));
  if (nrow(client_info) != 1) return(message("Error: Can only edit one client at a time"))
  
  conn <- poolCheckout(db_get_pool())
  
  #eventually will add heirarchal user groups to allow managers to view all and/or all created by subordinates.  For now MEL does all. 
  client_id <- dbGetQuery(conn,'select pd_dfsbenchmarking.client_edit( $1 , $2 , $3, $4 , $5, $6 , $7 , $8 , $9 );',
                          params=list(session_id=db_session_id,
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


################################
### CLIENT ASSESSMENT GROUPS ###
################################
db_get_client_assessment_listing <- function(db_session_id,client_id)
{
  #  if (!loggedin()) return(message("Warning: Not logged in"));
  if (is.null(db_session_id) || is.na(db_session_id) || !is.numeric(as.numeric(client_id))) return(warning(paste("Invlaid input values to db_get_client_assessment_listing: db_session_id=",db_session_id,"; client_id=",client_id)))
  
  conn <- poolCheckout(db_get_pool())
  
  #eventually will add heirarchal user groups to allow managers to view all and/or all created by subordinates.  For now MEL does all. 
  listing <- dbGetQuery(conn,'select * from pd_dfsbenchmarking.view_client_assessment_listing
                        where client_id = $1 and 
                              pd_dfsbenchmarking.user_has_client_access(client_id,pd_dfsbenchmarking.user_id_session_chain( $2 ))',
                        params=list(client_id=client_id,session_id=db_session_id)) 
  poolReturn(conn)
  # SESSION$client_assessment_listing <<- listing
  return (listing)
  
}

db_save_client_assessment_data <- function(db_session_id,assessment_data)
{
  #ll <- loggedin()
  #ahnd <- assessment_has_new_data()
  #if (!ll) return(message("Warning: Not logged in"));
  #if (!ahnd) return (TRUE)
  fields <- list(client_id="integer",
                 assessment_id="integer",
                 question_id="integer",
                 last_modified_time="timestamptz",
                 last_modified_user_id="int",
                 score="numeric",
                 rationale="varchar")
  
  start_time <- Sys.time()
  nothing <- FALSE
  if(is.null(assessment_data)){
    nothing <- TRUE
  } else if(nrow(assessment_data) == 0){
    nothing <- TRUE
  }
  if(nothing){return(assessment_data)}
  
  saving_data <- assessment_data %>%
    filter(is_changed) %>%
    dplyr::select(client_id,
                  assessment_id,
                  question_id,
                  last_modified_time,
                  last_modified_user_id,
                  score,
                  rationale)
  # saving_data <- subset(x=assessment_data,subset=is_changed==TRUE,select=c("client_id","assessment_id","question_id","last_modified_time","last_modified_user_id","score","rationale"))
  if (nrow(saving_data)==0) return (assessment_data) #No data to save
  if (any(is.na(saving_data$client_id))) return(warning("Unable to save client_assessment_data: NAs in client_id"))
  if (any(is.na(saving_data$assessment_id))) return(warning("Unable to save client_assessment_data: NAs in assessment_id"))
  if (any(is.na(saving_data$question_id))) return(warning("Unable to save client_assessment_data: NAs in question_id"))
  if (any(is.na(saving_data$last_modified_user_id))) return(warning("Unable to save client_assessment_data: NAs in last_modified_user_id"))
  if (any(is.na(saving_data$score) || is.null(saving_data$score) || saving_data$score > 7 || saving_data$score < 1)) return(warning("Unable to save client_assessment_data: score out of range 1-7"))
  
  saving_data[is.na(saving_data$rationale) | is.null(saving_data$rationale),"rationale"] <- "" #Insert blank strings instead of NULL where no rationale
  
  conn <- poolCheckout(db_get_pool())
  
  #There's a vague chance that multiple users will be writing to table concurrently -- so it's never deleted
  #dbWriteTable(conn,name=c("public","_pd_dfsbenchmarking_save_client_assessment_data"),value=saving_data,append=TRUE,overwrite=FALSE,row.names=FALSE,field.types=fields)
  dbSendQuery(conn,"drop table if exists public._pd_dfsbenchmarking_save_client_assessment_data")
  dbWriteTable(conn,name=c("public","_pd_dfsbenchmarking_save_client_assessment_data"),value=saving_data,row.names=FALSE,field.types=fields)
  
  ##If table doesn't get deleted, just need to create this once in the DB and not via script
  ##dbSendQuery(conn,"create index if not exists _pd_dfsbenchmarking_save_client_assessment_data_index ON public._pd_dfsbenchmarking_save_client_assessment_data USING btree (assessment_id,question_id,last_modified_time);");
  message('______about to save data')
  rows_inserted <- dbGetQuery(conn,"select pd_dfsbenchmarking.assessments_data_save( $1 );",params=list(session_id=db_session_id))

  message('______saved data')
  
  poolReturn(conn)
  rows_expected <- sum(assessment_data$is_changed)
  rows_inserted <- as.numeric(unlist(rows_inserted))
  if (rows_expected != rows_inserted) message(paste0("Warning: Saving Assessment Data expected to save ",rows_expected," but reported ",rows_inserted," affected"))
  
  #Now that we've saved, un-mark it as is_changed and save back to the SESSION
  assessment_data$is_changed <- FALSE
  #SESSION$client_info$current_assessment_data <<- assessment_data

  end_time <- Sys.time()
  
  print(paste0("db_save_client_assessment_data time: ", end_time - start_time))
  
  return (assessment_data)  
}

db_get_client_assessment_data <- function(db_session_id,client_id,assessment_id)
{
  #if (!loggedin()) return(message("Warning: Not logged in"));
  
  if (is.null(db_session_id) || is.na(db_session_id) || !is.numeric(as.numeric(client_id)) || !is.numeric(as.numeric(assessment_id))) return(warning(paste("Invlaid input values to db_get_client_asessment_data: db_session_id=",db_session_id,"; client_id=",client_id,"; assessment_id=",assessment_id)))
  
  conn <- poolCheckout(db_get_pool())
  
  assessement_data <- NULL
  
  #Changed to load the full set of assessment questions and data.  Only need the survey questions and layout at the time the assessment is being loaded
  #and someone wants to do it or view it
  assessment_data <- dbGetQuery(conn,'select * from pd_dfsbenchmarking.assessment_load( $1 , $2 , $3 )',
                                params=list(client_id=client_id,
                                            assessment_id=assessment_id,
                                            session_id=db_session_id)) 
  
  #Any new assessment will have an empty dataset
  if (nrow(assessment_data)==0) assessment_data <- NA
  
  poolReturn(conn)
  return (assessment_data)
}

db_edit_client_assessment <- function(db_session_id,assessment_id,assessment_info)
{
  #if (!loggedin()) return(message("Warning: Not logged in"));
  if (nrow(assessment_info) != 1) return(message("Error: Can only edit one client at a time"))
  
  conn <- poolCheckout(db_get_pool())
  assessment_info$assessment_date <- as.character(as.Date(assessment_info$assessment_date))
  
  assessment_id <- dbGetQuery(conn,'select pd_dfsbenchmarking.client_assessment_edit( $1 , $2 , $3 , $4 , $5 );',
                              params=list(session_id=db_session_id,
                                          assessment_id=assessment_id,
                                          client_id=assessment_info$client_id,
                                          assessment_name=assessment_info$assessment_name,
                                          assessment_date=assessment_info$assessment_date)) 
  poolReturn(conn)
  return (unlist(assessment_id))
}

