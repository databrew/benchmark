#' DB to memory
#' 
#' Assign the data from the database to the global environment
#' @param pool A connection pool
#' @param return_list Return the objects as a list, rather than assignation to global environment
#' @return Objects assigned to global environment
#' @export

db_to_memory <- function(pool,
                         return_list = FALSE){
  require(DBI)
  out_list <- list()
  
  # Read in all tables
  # tables <- unique(dbListTables(pool, 'pd_wbgbenchmark'))
  tables <- c(#'assessment_data',
              # 'assessment_question_categories',
              # 'assessment_question_categories_category_id_seq',
              # 'assessment_questions',
              # 'assessment_questions_question_id_seq',
              'assessments',
              # 'assessments_assessment_id_seq',
              # 'clients',
              # 'clients_client_id_seq',
              # 'users',
              # 'users_user_id_seq',
              'view_assessment_questions_list')#,
              # 'view_assessments_current_data',
              # 'view_client_assessment_listing',
              # 'view_client_listing')
  
  for (i in 1:length(tables)){
    this_table <- tables[i]
    message(paste0('Reading in the ', this_table, ' from the database and assigning to global environment.'))
    x <- get_data(tab = this_table,
                  schema = 'pd_dfsbenchmarking',
                  connection_object = pool,
                  use_sqlite = FALSE)
    if(return_list){
      out_list[[i]] <- x
      names(out_list)[i] <- this_table
    } else {
      assign(this_table,
             x,
             envir = .GlobalEnv)
    }
  }
  if(return_list){
    return(out_list)
  }
}