db_load_client <- function(client_id = 1,
                           pool){
   
    # Get the client data for the client_id in question
  cid <- client_id
  client_data <- clients %>% 
    filter(client_id == cid)
  if(nrow(client_data) > 0){
    return(client_data)
  } else {
    stop(paste0('No data in the clients table for client_id ', cid))
  }
}