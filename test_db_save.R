
source('Global.R')

fields <- list(client_id="integer",assessment_id="integer",question_id="integer",last_modified_time="timestamptz",last_modified_user_id="int",score="numeric",rationale="varchar")

saving_data <- data.frame(client_id=11,assessment_id=24,question_id=15,last_modified_time=now(),last_modified_user_id=1,score=3,rationale="text")

conn <- poolCheckout(db_get_pool())

dbWriteTable(conn,name=c("public","_pd_dfsbenchmarking_save_client_assessment_data"),value=saving_data,append=TRUE,overwrite=FALSE,row.names=FALSE,field.types=fields)

poolReturn(conn)
