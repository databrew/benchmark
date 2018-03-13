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
  user_data <- reactiveValues(db_session_id=NULL,current_client_id=NULL,current_assessment_id=NULL)
  
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
    user_data$user_id <- log_in_attempt$user_id
    user_data$user_name <- log_in_attempt$name
    user_data$db_session_id <- log_in_attempt$session_id
    user_data$current_client_id <- NULL #They didn't select one yet!  Must select from a list provided by client_listing
    user_data$current_assessment_id <- NULL #They didn't select one yet!  Must (a) Select a client (b) Select from a list provided by client_assessment_listing
    
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
  
  observeEvent(input$click, {
    click <- as.numeric(input$click)
    print(click)
    if (click==1) { call_db_login(); STATUS("Please select a client"); }
    if (click==2) { call_load_client(); STATUS("Please select an assessment"); }
    if (click==3) { call_load_client_assessment(); STATUS("Please perform the assessment"); }
    if (click %in% c(4:7)) { call_edit_assessment(); ifelse(click==7,STATUS("Please save the assessment and close"),STATUS("Please edit some numbers assessment")); }
    if (click==8) { call_save_and_close(); STATUS("Walkthrough complete, for now"); }
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
    #CLIENT$client_info #Really not needed to create a new reactive CLIENT value since it's equal to a subset of client_listing and current_client_id, should be reactive on user_data$current_client_id
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

