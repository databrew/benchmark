# Libraries
library(tidyverse)
library(radarchart)
library(shinyWidgets)
library(DBI)
library(RPostgreSQL)
library(yaml)
library(pool)
library(shiny)

functions <- dir('R',pattern=".*\\.R$")
for (i in 1:length(functions)){
  source(paste0('R/', functions[i]), chdir = TRUE)
}

# Define UI for application that draws a histogram
ui <- fluidPage(
  
  # Application title
  titlePanel("Reactivity example"),
  

      fluidRow(column(3,actionButton('click', 'Next Walkthrough')),column(9,textOutput("the_text"))),
      fluidRow(column(12,style='background-color:lightsteelblue;',tableOutput("the_clients"))),
      fluidRow(column(12,tableOutput("the_client"))),
      fluidRow(column(12,style='background-color:lightsteelblue;',tableOutput("the_client_assessments"))),
      fluidRow(column(12,tableOutput("the_assessment"))),
      fluidRow(column(12,style='background-color:lightsteelblue;',tableOutput("the_assessment_data")))
)

# Define server logic required to draw a histogram
server <- function(input, output) {
  
  ###SAME IN APP###
  USER <- reactiveValues(db_session_id=NULL,user_id=NULL,user_name=NULL,current_client_id=NULL,current_assessment_id=NULL)
  
  LISTINGS <- reactiveValues(client_listing=NULL,client_assessment_listing=NULL)
  #CLIENT <- reactiveValues(client_info=NULL)
  ASSESSMENT <- reactiveValues(assessment_template=NULL,assessment_data=NULL) #Will take two data.frames: one, layout of questions and categores; two, the data to go along
  #HELPER FUNCTIONS
  source('session_functions.R', local = TRUE)
  ###END SAME###
  
  STATUS <- reactiveVal(value="Please login")
  
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
    
    refresh_client_listing()    
    print("Login Result")
    print(log_in_attempt)
  }
  
  call_load_client <- function(UI_SELECTED_CLIENT_ID)
  {
    #UI_SELECTED_CLIENT_ID <- get_client_listing()$client_id[1] #Auto-selects whatever is top-1 client
    print(paste0("You selected client_id=",UI_SELECTED_CLIENT_ID))
    client_info <- load_client(UI_SELECTED_CLIENT_ID) #CLIENT$client_info and LISTINGS$client_assessment_listing set in load_client()
    print(client_info)
    print(get_client_listing())
  }
  
  call_load_client_assessment <- function(UI_SELECTED_ASSESSMENT_ID)
  {
    #UI_SELECTED_ASSESSMENT_ID <- get_current_client_assessment_listing()$assessment_id[1] #Auto-selects whatever is top-1 client
    print(paste0("You selected client_assessment_id=",UI_SELECTED_ASSESSMENT_ID))
    assessment_info <- load_client_assessment(UI_SELECTED_ASSESSMENT_ID) #CLIENT$client_info and LISTINGS$client_assessment_listing set in load_client()
    print(assessment_info[1,])
  }
  call_edit_assessment_data <- function()
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
  call_update_ifc_client_id <-function(UI_SELECTED_CLIENT_ID)
  {
    selected_client_info <- get_current_client_info()
    UI_NEW_IFC_CLIENT_ID <- ceiling(runif(1,.000001,.999999)*1000000) #usually a 6-digit number but this isn't important...just example value
    selected_client_info$ifc_client_id <- UI_NEW_IFC_CLIENT_ID
    updated_client_id <- db_edit_client(get_db_session_id(),get_current_client_id(),selected_client_info)
    print(paste0("Client ",updated_client_id," has been updated!"))
    
    #These are unnecessary...can update the reactiveVariable locally.  Let's decide how best to do and/or how long it takes to do the full round-trip database refresh
    refresh_client_listing() #We've updated info on the back-end so re-pull listing to refresh display (could in principle be done on just front-end too)
    #load_client(UI_SELECTED_CLIENT_ID) #Since we're currently viewing this client and open, let's also re-load.  Also not super necessary.
  }
  call_update_assessment_date <-function(UI_SELECTED_ASSESSMENT_ID)
  {
    selected_assessment_info <- subset(x=get_current_client_assessment_listing(),subset=assessment_id==UI_SELECTED_ASSESSMENT_ID)
    random_days <- ceiling(runif(1,1,365))
    UI_NEW_ASSESSMENT_DATE <- now() - days(random_days) #Random date in the last year
    selected_assessment_info$assessment_date <- UI_NEW_ASSESSMENT_DATE
    selected_assessment_info$assessment_name <- paste0("Assessment Name Update ",random_days)
    updated_assessment_id <- db_edit_client_assessment(db_session_id=get_db_session_id(),UI_SELECTED_ASSESSMENT_ID,selected_assessment_info)

    print(paste0("Assessment ",updated_assessment_id," has been updated!"))
    
    #These are unnecessary...can update the reactiveVariable locally.  Let's decide how best to do and/or how long it takes to do the full round-trip database refresh
    #refresh_client_listing() #We've updated info on the back-end so re-pull listing to refresh display (could in principle be done on just front-end too)
    refresh_client_assessment_listing() #Since we're currently viewing this client and open, let's also re-load.  Also not super necessary.
  }
  call_new_client <- function()
  {
    random_100 <- ceiling(runif(1,1,100))
    UI_CLIENT_FORM <- data.frame(client_id=-1,ifc_client_id=random_100,name=paste0('New Bank ',random_100),short_name=paste0('NBC',random_100),firm_type='Bank',address='111 Main St.',city='SomePlace',country='USA',stringsAsFactors = F)
    new_client_id <- db_edit_client(get_db_session_id(),UI_CLIENT_FORM$client_id,UI_CLIENT_FORM) #Client_id=-1 needs to come from the UI form, where -1 is specified as value when user clicks on 'add new'.  A separate argument to db_edit just for clarity as it's the key ID
    print(paste0("Client ",UI_CLIENT_FORM$name," has been added as client_id=",new_client_id))
    refresh_client_listing()
  }
  call_new_assessment <- function()
  {
    random_100 <- ceiling(runif(1,1,100))
    new_date <- now() - days(random_100)
    
      
    UI_ASSESSMENT_FORM <- data.frame(assessment_id=-1,client_id=get_current_client_id(),assessment_name=paste0('New Assessment ',random_100),assessment_date=new_date,stringsAsFactors = F)
    new_assessment_id <- db_edit_client_assessment(get_db_session_id(),UI_ASSESSMENT_FORM$assessment_id,UI_ASSESSMENT_FORM)
      
    print(paste0("Assessment ",UI_ASSESSMENT_FORM$name," for ",get_current_client_info()$name," has been added as assessment_id=",new_assessment_id))
    refresh_client_assessment_listing()
  }
  
  
  observeEvent(input$click, {
    click <- as.numeric(input$click)
    print(click)
    if (click==1) { call_db_login(); STATUS("Please select client whose client_id=11"); }
    if (click==2) { call_load_client(11); STATUS("Please select an assessment whose assessment_id=24"); }
    if (click==3) { call_load_client_assessment(24); STATUS("Please perform the assessment"); }
    if (click %in% c(4:7,17:19)) { call_edit_assessment_data(); ifelse(click==7,STATUS("Please save the assessment and close"),STATUS("Please edit some numbers assessment")); }
    if (click==8) { call_save_and_close(); STATUS("Ooops... Client Garanti bank's IFC ID is wrong, let's fix it.   Select the client_id=1"); }
    if (click==9) { call_load_client(1); STATUS("Now edit the IFC ID field and save it"); }
    if (click==10) { call_update_ifc_client_id(1); STATUS("That's better!  Oops, looks like the assessment is wrong!  Let's edit assessment_id=1 while we're here..."); }
    if (click==11) { call_update_assessment_date(1); STATUS("That's better!  Let's close and then create a new client"); }
    if (click==12) { unload_client(); STATUS("Now let's 'add new client' ... and fill-in and submit the form"); }
    if (click==13) { call_new_client(); STATUS("Looking good.  Let's select him and go create an assessment for him"); }
    if (click==14) { call_load_client(max(get_client_listing()$client_id)); STATUS("Now let's 'add new assessment' ... and fill-in and submit the form"); }
    if (click==15) { call_new_assessment(); STATUS("New click with a new assessment!  Let's select the assessment to fill it out!"); }
    if (click==16) { call_load_client_assessment(max(get_current_client_assessment_listing()$assessment_id)); STATUS("Fill in some data for this New Assessment...!"); }
    if (click==20) { call_save_and_close(); STATUS("!WALKTHROUH COMPLETED!"); }
  })
  
  output$the_text <- renderText({
    STATUS()
  })
  
  output$the_clients <- renderTable({
    print("Rendering the_clients")
    #LISTINGS$client_listing
    get_client_listing()
  })

  output$the_client <- renderTable({
    print("Rendering the_client")
    #CLIENT$client_info #Really not needed to create a new reactive CLIENT value since it's equal to a subset of client_listing and current_client_id, should be reactive on USER$current_client_id
    get_current_client_info()
  })
  
  output$the_client_assessments <- renderTable({
    print("Rendering the_assessments")
    al <- get_current_client_assessment_listing()
    print(al)
    al
  })
  
  output$the_assessment <- renderTable({
    print("Rendering the_assessment head...")
    as <- get_current_assessment_template()
    as[1:3,c(1:6,11:17)]
  })

  output$the_assessment_data <- renderTable({
    print("Rendering the_assessment head...")
    assessment_data <- get_current_assessment_data()

  })
  
}

# Run the application 
shinyApp(ui = ui, server = server)

