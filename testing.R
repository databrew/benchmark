# Should be run from parent directory (dfsbenchmarking)

## Commented out the below. If running from parent directory (as per above instructions), no need to hard-code any directory issues.
# # Define whether on Joe's computer (dev) or elsewhere (prod)
# joe <- grepl('joebrew', getwd())
# 
# if(joe){
#   dir <- getwd()
# } else {
#   dir <- paste0(dirname(path.expand("~")),"/WBG/Sinja Buri - FIG SSA MEL/MEL Program Operations/Knowledge Products/Dashboards & Viz/Benchmarking Excel online tool/GitHub/dfsbenchmarking")
#   setwd(dir)
# }

# Source helper files
functions <- dir('R')
for(i in 1:length(functions)) {
  source(paste0('R/', functions[i]), chdir = TRUE) 
}


##User arrives at welcome page
##User logs in
db_login('MEL','FIGSSAMEL')
client_listing <- db_get_client_listing()

##User selects top-1 client
client_info <- load_client(client_listing$client_id[1])
print(get_current_client_id())

#User decides to edit the client, change the ifc_client_id by 1
print(client_info$ifc_client_id)
client_info$ifc_client_id <- client_info$ifc_client_id + 1
#get the ID of the client we changed (should be 11)
updated_client_id <- db_edit_client(get_current_client_id(),data.frame(client_id=client_info$client_id,ifc_client_id=client_info$ifc_client_id,name='New Bank Co.',short_name='NBC',firm_type='Bank',address='111 Main St.',city='Anytown',country='USA',stringsAsFactors = F))
print(updated_client_id) #should be the same!

#refresh the listing & reload the client, if update was successful
if (updated_client_id >-1)
{
  client_listing <- db_get_client_listing()
  client_info <- load_client(updated_client_id) #if there's an update error, will be -1
}

#assessments are loaded into client_info during load_client()
#display so user can load or edit
assessments <- client_info$assessments

#User decides to create (or find) assessment 'New Assessment'
updated_assessment_id <- db_edit_client_assessment(-1,data.frame(client_id=get_current_client_id(),assessment_name="New Assessment",assessment_date=today(),stringsAsFactors=F))

#reload the client to get current assessment info
if (updated_assessment_id >-1)
{
  client_info <- load_client(get_current_client_id())
}

#User selects the new assessment
load_client_assessment(updated_assessment_id)

#User starts answering questions...
record_assessment_data_entry(question_id=2,score=2,rationale="We're a 2!")
record_assessment_data_entry(question_id=3,score=3,rationale="A bit better...")
record_assessment_data_entry(question_id=4,score=2,rationale="A little worse")
record_assessment_data_entry(question_id=5,score=6,rationale="No, actually, great!")

print('Preparing to save:')
print(get_current_assessment_data())
#So system will auto-save as often as designed or specified... Presumably every question... but now we've entred a few frist
saved <- db_save_client_assessment_data()
print(paste("Saved ",saved," entries"))
record_assessment_data_entry(question_id=15,score=4,rationale="4")

db_save_client_assessment_data()
saved <- db_save_client_assessment_data()
print(paste("Saved ",as.numeric(saved)," entries"))

db_disconnect()

