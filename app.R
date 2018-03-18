library(shiny)
library(shinydashboard)
library(shinyjs)
source('global.R')

the_width <- 370
header <- dashboardHeader(title="DFS Benchmarking Tool",
                          tags$li(class = 'dropdown',  
                                  tags$style(type='text/css', "#log_out_button {margin-right: 10px; margin-left: 10px; font-size:80%; margin-top: 10px}"),
                                  # tags$style(type='text/css', "#log_in_text { width:100%; margin-top: 14px; margin-left: 10px; margin-right: 10px; font-size:100%}"),
                                  tags$style(type='text/css', "#save_and_close_ui {margin-right: 10px; margin-left: 10px; font-size:80%; margin-top: 10px}"),
                                  tags$li(tags$li(class = 'dropdown',
                                                  uiOutput('save_and_close_ui'))),
                                  tags$li(class = 'dropdown',
                                          img(src='blue.png', align = "center", width = '160px', height = '10px')),
                                  tags$li(class = 'dropdown',
                                          span(uiOutput('log_in_text'), class = "logo")),
                                  tags$li(class = 'dropdown',
                                          img(src='blue.png', align = "center", width = '20px')),
                                  tags$li(tags$li(class = 'dropdown',
                                                  uiOutput('log_out_button')))),
                          titleWidth = the_width)
# sidebar <- uiOutput('dashboard_sidebar')
sidebar <- dashboardSidebar(
  width = the_width,
  sidebarMenu(id="tabs",
              sidebarMenuOutput("menu")
  )
)
body <- dashboardBody(
  tags$style(".fa-check {color:#0000FF}"),
  tags$style(".fa-exclamation-circle {color:#B22222}"),
  # Conflicted with width
  # tags$head(
  #   tags$link(rel = "stylesheet", type = "text/css", href = "custom.css")
  # ),
  
  useShinyjs(),
  fluidRow(
    column(12,
           hidden(
             lapply(seq(n_tabs), function(i) {
               div(class = "page",
                   id = paste0("step", i),
                   paste("Tab", i, 'of', nrow(tab_dict)),
                   style = "font-size: 140%;")
             })
           ),
           align = 'center',
           uiOutput('log_in_button')),
    # column(4),
    height = '50px'
    
  ),
  tabItems(
    tabItem(
      tabName = 'home',
      fluidPage()
    ),
    tabItem(
      tabName="instructions",
      fluidPage(
        fluidRow(h1('Instructions', align = 'center')),
        fluidRow(
          column(6,
                 includeMarkdown('includes/instructions.md')),
          column(6,
                 includeMarkdown('includes/instructions_b.md'))
        ),
        fluidRow(h3('Example', align = 'center')),
        fluidRow(
          box(#title = 'Example',
            fluidPage(
              fluidRow(column(3),
                       column(6, sliderInput('example',
                                             'Score (1-7)',
                                             min = 0,
                                             max = 7,
                                             value = 0,
                                             step = 0.5)),
                       column(3)),
              uiOutput('example_ui'),
              fluidRow(column(12,
                              h4('Meaning:'),
                              p(textOutput('example_text'))))),
            height = '350px'),
          box(chartJSRadarOutput('example_chart'), height = '350px')
        )
      )
      
    ),
    tabItem(
      tabName = 'configuration',
      fluidPage(
        fluidRow(
          column(6, align = 'center',
                 uiOutput('configuration_ui_left')),
          column(6, align = 'center',
                 uiOutput('configuration_ui_right'))
        ),
        fluidRow(
          column(6, align = 'center',
                 actionButton('create_client',
                              'Create new client',
                              icon = icon('user', 'fa-3x'))),
          column(6, align = 'center',
                 actionButton('create_assessment',
                              'Create new assessment',
                              icon = icon('address-card', 'fa-3x')))
        ),
        br(), 
        uiOutput('launch_assessment_ui'),
        br(), br(), br(), br(), br(), br(), br(), br(),
        fluidRow(
          column(6,
                 h4('Client data', align = 'center'),
                 DT::dataTableOutput('client_table')),
          column(6,
                 h4('Assessment data', align = 'center'),
                 DT::dataTableOutput('assessment_table'))
        )
      )
      
    ),
    tabItem(
      tabName="strategy_and_execution",
      uiOutput('strategy_and_execution_ui')
    ),
    tabItem(
      tabName="organization_and_governance",
      uiOutput('organization_and_governance_ui')
    ),
    tabItem(
      tabName="partnerships",
      uiOutput('partnerships_ui')
    ),
    tabItem(
      tabName="products",
      uiOutput('products_ui')
    ),
    tabItem(
      tabName="marketing",
      uiOutput('marketing_ui')
    ),
    tabItem(
      tabName="distribution_and_channels",
      uiOutput('distribution_and_channels_ui')
    ),
    tabItem(
      tabName="risk_management",
      uiOutput('risk_management_ui')
    ),
    tabItem(
      tabName="it_and_mis",
      uiOutput('it_and_mis_ui')
    ),
    tabItem(
      tabName="operations_and_customer_service",
      uiOutput('operations_and_customer_service_ui')
    ),
    tabItem(
      tabName="responsible_finance",
      uiOutput('responsible_finance_ui')
    ),
    tabItem(
      tabName="graphs",
      uiOutput('graphs_ui')
    ),
    tabItem(
      tabName="assessment",
      uiOutput('assessment_ui')
    ),
    tabItem(
      tabName = 'about',
      fluidPage(
        fluidRow(h4("The dashboard was developed as a part of activities under the ", 
                    a(href = 'http://www.ifc.org/wps/wcm/connect/region__ext_content/ifc_external_corporate_site/sub-saharan+africa/priorities/financial+inclusion/za_ifc_partnership_financial_inclusion',
                      target='_blank',
                      "Partnership for Financial Inclusion"),
                    " (a $37.4 million joint initiative of the ",
                    a(href = "http://www.ifc.org/wps/wcm/connect/corp_ext_content/ifc_external_corporate_site/home",
                      target='_blank',
                      'IFC'),
                    " and the ",
                    a(href = "http://www.mastercardfdn.org/",
                      target='_blank',
                      'MasterCard Foundation'),
                    " to expand microfinance and advance digital financial services in Sub-Saharan Africa) by the FIG Africa Digital Financial Services unit (the MEL team).")),
        br(),
        fluidRow(div(img(src='partnershiplogo.png', 
                         align = "center",
                         height = '90'), style="text-align: center;"),
                 br(), 
                 style = 'text-align:center;'
        ),
        br(),
        fluidRow(
          shinydashboard::box(
            title = 'Margarete Biallas',
            fluidPage(
              fluidRow(
                div(a(img(src='about/Marg.png', 
                          align = "center",
                          height = '80'),
                      href="mailto:mbiallas@ifc.org"), 
                    style="text-align: center;")
              ),
              fluidRow(h5('Senior DFS Specialist'),
                       h5('Washington, D.C. ', 
                          a(href = 'mailto:mbiallas@ifc.org',
                            'mbiallas@ifc.org'))),
              fluidRow(helpText("Margarete leads IFC's Digital Financial Advisory Services. Previously, she managed IFC‘s Access to Finance program in the Mekong and was responsible for financial markets advisory services in Vietnam, Cambodia, and Lao PDR, where she worked on IFC’s earliest mobile financial services initiatives. Prior to joining IFC she worked as a Senior Risk Manager with KfW, where she led the development of a limit management system for banks' financial markets exposures. As Credit Officer for Eastern Europe and Asia she reviewed all of KfW's commercial investments in these two regions. She successfully established two ventures providing education."))
            ),
            width = 3),
          shinydashboard::box(
            title = 'Soren Heitmann',
            fluidPage(
              fluidRow(
                div(a(img(src='about/Soren Heitmann.jpg', 
                          align = "center",
                          height = '80'),
                      href="mailto:sheitmann@ifc.org"), 
                    style="text-align: center;")
              ),
              fluidRow(h5('Project Lead'),
                       h5('Johannesburg ', 
                          a(href = 'mailto:sheitmann@ifc.org',
                            'sheitmann@ifc.org'))),
              fluidRow(helpText("Soren has a background in database management, software engineering and web technology. He manages the applied research and integrated monitoring, evaluation and learning program for the IFC-MasterCard Foundation Partnership for Financial Inclusion. He works at the nexus of data-driven research and technology to help drive learning and innovation within IFC’s Digital Financial Services projects in Sub-Saharan Africa."))
            ),
            width = 3),
          shinydashboard::box(
            title = 'Oleksiy Anokhin',
            fluidPage(
              fluidRow(
                div(a(img(src='about/Oleksiy Anokhin.jpg', 
                          align = "center",
                          height = '80'),
                      href="mailto:oanokhin@ifc.org"), 
                    style="text-align: center;")
              ),
              fluidRow(h5('Project Specialist'),
                       h5('Washington, DC ', 
                          a(href = 'mailto:oanokhin@ifc.org',
                            'oanokhin@ifc.org'))),
              fluidRow(helpText("Oleksiy focuses on data-driven visualization solutions for international development. He is passionate about using programmatic tools (such as interactive dashboards) for better planning and implementation of projects, as well as for effective communication of projects results to various stakeholders."))
            ),
            width = 3),
          shinydashboard::box(
            title = 'Joe Brew',
            fluidPage(
              fluidRow(
                div(a(img(src='about/Joe Brew.png', 
                          align = "center",
                          height = '80'),
                      href="mailto:jbrew1@worldbank.org"), 
                    style="text-align: center;")
              ),
              fluidRow(h5('Data Scientist'),
                       h5('Amsterdam ', 
                          a(href = 'mailto:jbrew1@worldbank.org',
                            'jbrew1@worldbank.org'))),
              fluidRow(helpText("Joe is a data scientist for", a(href = 'http://databrew.cc/', 'DataBrew.'), "He has a background in epidemiology and development economics. He works in both industry as a consultant as well as academia. His research focuses on the economics of malaria elimination programs in Sub-Saharan Africa."))
            ),
            width = 3)
        ),
        fluidRow(column(12,
                        align = 'right',
                        uiOutput('db_info')))
      )
    )
  )
)

# UI
ui <- dashboardPage(header, sidebar, body, skin="blue")

# Server
server <- function(input, output, session) {
  
  # data base info
  output$db_info <- renderUI({
    creds <- credentials_extract()
    fluidPage(
      fluidRow(
        helpText(paste0('db: ', creds$dbname)),
        helpText(paste0('host: ', creds$host))
      )
    )
  })
  
  counter <- reactiveVal(0)
  # Define some reactive values for later update
  USER <- reactiveValues(db_session_id=NULL,user_id=NULL,user_name=NULL,current_client_id=NULL,current_assessment_id=NULL)
  LISTINGS <- reactiveValues(client_listing=NULL,client_assessment_listing=NULL)
  #CLIENT <- reactiveValues(client_info=NULL)
  ASSESSMENT <- reactiveValues(assessment_template=NULL,assessment_data=NULL) #Will take two data.frames: one, layout of questions and categores; two, the data to go along
  #HELPER FUNCTIONS
  source('session_functions.R', local = TRUE)
  STATUS <- reactiveVal(value="Please login")
  update_session <- function(status) {
    STATUS <<- status
    print(paste("Status updated to: ",STATUS))
  }
  user <- reactiveVal(value = '')
  logged_in <- reactiveVal(value = FALSE)
  failed_log_in <- reactiveVal(value = 0)
  
  # Observe the log in submit and see if logged in
  observeEvent(input$log_in_submit, {
    # Attempt the log-in
    UI_LOGIN<- input$user_name
    UI_PASS<- input$password
    log_in_attempt <- db_login(UI_LOGIN,UI_PASS)
    # the user_id will be -1 if log in failed
    if(log_in_attempt$user_id > -1){
      # Successful log-in
      message('Successful log in')
      # Update the reactive user object
      user(input$user_name)
      # # Update the true/false logged_in switch
      logged_in(TRUE)
      # # Update the USER dataframe
      USER$user_id <- log_in_attempt$user_id
      USER$user_name <- log_in_attempt$name
      USER$db_session_id <- log_in_attempt$session_id
      USER$current_client_id <- NULL #They didn't select one yet!  Must select from a list provided by client_listing
      USER$current_assessment_id <- NULL #They didn't select one yet!  Must (a) Select a client (b) Select from a list provided by client_assessment_listing
      refresh_client_listing()    
      message("Login Result")
      print(log_in_attempt)
    } else {
      # failed log-in, send signal to re-render the log-in modal
      fli <- failed_log_in()
      failed_log_in(fli + 1)
    }
  })
  
  
  # Observe log in submit and prompt selection of client and assessment name
  observeEvent(input$log_in_submit, {
    li <- logged_in()
    if(li){
      message('Changing to configuration tab having now logged-in')
      updateTabItems(session, "tabs", 'configuration')
    }
  })
  # Observe the launch button
  observeEvent(input$launch_assessment, {
    li <- logged_in()
    if(li){
      # The below commented out section picks the first non-finished tab.
      # But it's slow, and sometimes gets into infinite back and forths
      # so currently commenting out.
      # # Get submissions
      # subs <- reactiveValuesToList(submissions)
      # subs <- unlist(subs)
      # 
      # # Get the most recent not finished part
      # tab_names <- tab_dict$name
      # tab_names <- tab_names[!tab_names %in% c('instructions', 'home', 'configuration', 'graphs', 'about')]
      # done_list <- rep(NA, length(tab_names))
      # for(i in 1:length(tab_names)){
      #   i <- i + 1
      #   tabName <- tab_names[i]
      #     these_competencies <- competency_dict %>%
      #       filter(tab_name == tabName) %>%
      #       .$combined_name
      #   these_competencies <- paste0(these_competencies, '_submit')
      #   these_competencies <- subs[names(subs) %in% these_competencies]
      #   all_ok <- all(these_competencies)
      #   done <- FALSE
      #   if(exists('these_competencies')){
      #     if(length(these_competencies) > 0){
      #       if(all_ok){
      #         message('Everything is done for ', tabName, '.')
      #         done <- TRUE
      #       }
      #     }
      #   }
      #   done_list[i] <- done
      # }
      # dones <- unlist(done_list)
      # if(all(dones)){
      #   this_one <- tab_names[1]
      # } else {
      #   this_one <- tab_names[(which(!dones))[1]]
      # }
      # 
      # message('Launching assessment to first non-finished tab: ', this_one)
      this_one <- 'strategy_and_execution'
      updateTabItems(session, "tabs", this_one)
    }
  })
  
  # Observe the log out and clear the user
  observeEvent(input$log_out, {
    # Reset the failed log in attempt counter
    failed_log_in(0)
    # Save the data
    save_assessment_data()
    # Unload stuff
    unload_client_assessment()
    unload_client()
    # Reset the reactive values
    message('Logging out. Resetting reactive values.')
    USER <- reactiveValues(db_session_id=NULL,user_id=NULL,user_name=NULL,current_client_id=NULL,current_assessment_id=NULL)
    LISTINGS <- reactiveValues(client_listing=NULL,client_assessment_listing=NULL)
    ASSESSMENT <- reactiveValues(assessment_template=NULL,assessment_data=NULL) #Will take two data.frames: one, layout of questions and categores; two, the data to go along
    # Clear the submissions
    submissions <- reactiveValues()
    STATUS("Please login")
    logged_in(FALSE)
    failed_log_in <- reactiveVal(value = 0)
    user('')
    logged_in(FALSE)
  })
  # Observe the log out and clear the user
  observeEvent(input$save_and_close, {
    unload_client_assessment()
    updateSelectInput(session = session,
                      inputId = 'assessment',
                      selected = '')
    updateTabItems(session, "tabs", 'configuration')

  })
  
  
  # Log in / out
  output$log_in_button <- renderUI({
    # Get whether currently logged in
    logged_in_now <- logged_in()
    if(is.null(logged_in_now)){
      logged_in_now <- FALSE
    }
    if(!logged_in_now){
      fluidPage(
        fluidRow(column(12,
                        textInput('user_name', 'User name', value = 'mbiallas')),
                 column(12,
                        textInput('password', 'Password', value = '230984'))),
        fluidRow(
          column(12,
                 textOutput('failed_log_in_text'))
        ),
        fluidRow(
          column(12,
                 action_modal_button('log_in_submit', "Submit", icon = icon('check-circle')))
        )
      )
    } else {
      fluidPage(h4(textOutput('assessment_text')),
                h3(textOutput('section_text')))
    }
  })
  
  output$log_out_button <- renderUI({
    # Get whether currently logged in
    logged_in_now <- logged_in()
    if(is.null(logged_in_now)){
      logged_in_now <- FALSE
    }
    if(logged_in_now){
      actionButton('log_out', 'Log out', icon = icon('sign-in'))
    } else {
      NULL
    }
  })

  failed_log_in_text <- reactiveVal(value = '')
  observeEvent(c(failed_log_in()), {
    fli <- failed_log_in()
    if(fli > 0){
      message('Failed log in attempt. Re-prompting the log-in.')
      failed_log_in_text('Incorrect user name / password combination.')
    }
  })
  observeEvent(input$log_out, {
    fli <- failed_log_in()
      message('Logging out. Re-setting the failed log in attempt text.')
      failed_log_in_text('')
  })
  
  output$failed_log_in_text <-
    renderText({
      ok <- FALSE
      x <- failed_log_in_text()
      if(!is.null(x)){
        if(length(x) > 0){
          if(x != ''){
            ok <- TRUE
          }
        }
      }
      if(ok){
        return(x)
      }
    })

  
  # Generate logged in text
  output$log_in_text <- renderText({
    u <- user()
    out <- 'Not logged in'
    if(!is.null(u)){
      if(u != ''){
        out <- paste0('Logged in as ', u)
      }
    }
    return(out)
  })
  
  output$example_ui <- renderUI({
    
    ie <- input$example
    colors <- rep('black', 3)
    make_red <- ifelse(ie > 0 & ie <=2.5, 1,
                       ifelse(ie > 0 & ie <=5.5, 2,
                              ifelse( ie > 0  & ie <= 7, 3, NA)))
    cols <- c('red', 'orange', 'green')
    if(!is.na(make_red)){
      colors[make_red] <- cols[make_red]
    }
    
    fluidRow(column(4,
                    h4(span('Formative staffing', style = paste0("color:", colors[1])), span('(score 1-3)', style = paste0("color:", colors[1]))),
                    p(span('The mobile banking operation is poorly-staffed.',style = paste0("color:", colors[1])))),
             column(4,
                    h4(span('Emerging staffing', style = paste0("color:", colors[2])), span('(score 4-5)', style = paste0("color:", colors[2]))),
                    p(span('The mobile banking operation has sufficient staff.', style=paste0("color:", colors[2])))),
             column(4,
                    h4(span('Developed staffing', style = paste0("color:", colors[3])), span('(score 6-7)', style = paste0("color:", colors[3]))),
                    p(span('The mobile banking operation is well-staffed.', style = paste0("color:", colors[3])))))
  })
  
  output$example_text <- renderText({
    x <- input$example
    dict <- data_frame(key = 0:7,
                       value = c('(no answer)',
                                 'inimally formative',
                                 'Formative',
                                 'Minimally emerging',
                                 'Emerging',
                                 'Emerged',
                                 'Minimally developed',
                                 'Developed'))
    val <- dict %>% filter(key == round(x)) %>% .$value
    paste0('In this competency, the mobile banking operation is ', tolower(val), '.')
  })
  
  output$example_chart <- renderChartJSRadar({
    x <- input$example
    scores <- list(
      'This Mobile Banking Operation' = c(x, 3, 5),
      'Best Practice' = rep(7, 3)
    )
    labs <- c('Staffing', 'Dimension B', 'Dimension A')
    chartJSRadar(scores = scores, labs = labs, maxScale = 7,
                 # height = '150px',
                 scaleStepWidth = 1,
                 scaleStartValue = 0,
                 responsive = TRUE,
                 labelSize = 11,
                 showLegend = TRUE,
                 addDots = TRUE,
                 showToolTipLabel = TRUE,
                 colMatrix = t(matrix(c(col2rgb('darkorange'), col2rgb('lightblue')), nrow = 2, byrow = TRUE)))
    
  })
  
  # Define a reactive value which is the currently selected tab number
  rv <- reactiveValues(page = 1)
  
  # Define function for changing the tab number in one direction or the 
  # other as a function of forward/back clicks
  navPage <- function(direction) {
    rv$page <- rv$page + direction
  }
  
  ## Get main tab
  main_tab <- reactiveVal(value = 'home')
  
  # Create reactive values to observe the submissions
  submissions <- reactiveValues()
  
  # Generate reactive input list for submission numbers saving
  eval(parse(text = create_input_list()))
  
  # Generate the reactive objects associated with each tab  
  for(tn in 1:length(tab_names)){
    this_tab_name <- tab_names[tn]
    these_competencies <- competency_dict %>% filter(tab_name == this_tab_name) %>% .$competency
    eval(parse(text = generate_reactivity(tab_name = this_tab_name,
                                          competencies = these_competencies)))
  }
  
  # Generate the uis for each tab
  for(tn in 1:length(tab_names)){
    this_tab_name <- tab_names[tn]
    these_competencies <- competency_dict %>% filter(tab_name == this_tab_name) %>% .$competency
    eval(parse(text = generate_ui(tab_name = this_tab_name,
                                  competencies = these_competencies)))
  }
  
  # Box with warnings for incomplete data
  output$warnings_box <- renderUI({
    
    the_submissions <- reactiveValuesToList(submissions)
    the_submissions <- unlist(the_submissions)
    # print(the_submissions)
    all_checked <- all(the_submissions)
    # if(!all_checked){
    # still_missing <- which(!the_submissions)
    # still_missing <- names(still_missing)
    # still_missing <- gsub('_submit', '', still_missing)
    # still_missing <- data.frame(combined_name = still_missing)
    # still_missing <- left_join(still_missing, 
    #                            competency_dict %>%
    #                              mutate(combined_name = tolower(combined_name)))
    # missing_text <- 'Interpret results with caution - you did not submit responses for the below areas:'
    # x <- still_missing %>%
    #   dplyr::select(tab_name,
    #                 competency) %>%
    #   mutate(tab_name = simple_cap(gsub('_', ' ', tab_name)),
    #          competency = simple_cap(gsub('_', ' ', competency))) %>%
    #   dplyr::rename(`Tab name` = tab_name,
    #                 Competency = competency)
    # x <- x %>%
    #   distinct(`Tab name`, Competency, .keep_all = TRUE)
    # missing_table <- DT::datatable(x, rownames = FALSE,
    #                                options = list(
    #                                  pageLength = 5,
    #                                  dom = 'tip'))
    # the_box <- box(title = 'Warning',
    #                status = 'danger',
    #                collapsible = TRUE,
    #                width = 12,
    #                fluidPage(
    #                  fluidRow(p(missing_text)),
    #                  fluidRow(missing_table))
    # )
    # } else {
    the_box <- NULL
    # }
    return(the_box)
  })
  
  # Radar charts
  for(i in 1:length(tab_names)){
    eval(parse(text = generate_radar_server(tab_name = tab_names[i])))
  }
  
  # Reactive objecting observing the selected sub tab
  sub_tab_selected <- reactiveVal(value = NULL)
  
  
  observeEvent({
    main_tab();
  }, {
    mt <- main_tab()
    message('Changed tabs to ', mt)
    # Get the name of the first sub tab associated with the clicked tab
    x <- competency_dict %>%
      filter(tab_name == mt)
    if(nrow(x) > 0){
      x <- x[1,]
      the_new_one <- convert_capitalization(simple_cap(gsub('_', ' ', x$competency))) %>% as.character
      message('Overwriting the selected sub tab with: ', the_new_one)
      sub_tab_selected(the_new_one)
    }
  })
  
  # Observe any clicks on the sub-tabs, and update the subtab accordingly
  eval(parse(text = observe_sub_tab()))
  
  # Assessment ui 
  output$assessment_ui <- renderUI({
    fluidPage()
  })
  # If tabs are set to assessment, bring to configuration
  observeEvent(input$tabs, {
    it <- input$tabs
    if(it == 'assessment'){
      message('Clicked on assessment sidebar menu. Bringing to strategy and execution')
      updateTabItems(session, "tabs", 'strategy_and_execution')
    }
  })
  
  # Create the graphs page
  output$graphs_ui <-
    renderUI({
      fluidPage(
        fluidRow(h3('Examine your results below:')),
        fluidRow(downloadButton("download_visualizations", "Download all charts!")),
        br(),
        
        fluidRow(
          # Can't run the below in loop due to comma separation
          eval(parse(text = generate_radar_ui(tab_name = tab_names[1]))),
          eval(parse(text = generate_radar_ui(tab_name = tab_names[2]))),
          eval(parse(text = generate_radar_ui(tab_name = tab_names[3]))),
          eval(parse(text = generate_radar_ui(tab_name = tab_names[4]))),
          eval(parse(text = generate_radar_ui(tab_name = tab_names[5]))),
          eval(parse(text = generate_radar_ui(tab_name = tab_names[6]))),
          eval(parse(text = generate_radar_ui(tab_name = tab_names[7]))),
          eval(parse(text = generate_radar_ui(tab_name = tab_names[8]))),
          eval(parse(text = generate_radar_ui(tab_name = tab_names[9]))),
          eval(parse(text = generate_radar_ui(tab_name = tab_names[10])))
        ),
        fluidRow(
          uiOutput('warnings_box')
        ),
        fluidRow(
          downloadButton('downloadData', 'Download your responses as raw data')
          
        )
      )
    })
  
  # # Observe any full completions of a competency, and navigate to next one
  eval(parse(text = sub_tab_completer()))
  
  
  # Download data
  output$downloadData <- downloadHandler(
    filename = function() { paste('raw_data', '.csv', sep='') },
    content = function(file, ip = input_list) {
      ip <- reactiveValuesToList(ip)
      ip <- unlist(ip)
      df <- data.frame(key = names(ip),
                       value = ip)
      write.csv(df, file, row.names = FALSE)})
  
  # Create reactive dataset for plotting radar
  radar_data <- reactive({
    x <- make_radar_data(ip = input_list)
    x
  })
  
  
  # Modal dialogs for adding comment
  eval(parse(text = generate_modals()))
  
  
  
  # Progress plot
  output$progress_plot <-
    renderPlot({
      # Observe log out
      li <- logged_in()
      it <- main_tab()
      if(it != 'about' & li){
        the_submissions <- reactiveValuesToList(submissions)
        the_submissions <- unlist(the_submissions)
        numerator <- length(which(the_submissions))
        denominator <- length(the_submissions)
        df <- data.frame(key = c('Finished', 'All'),
                         value = c(numerator, denominator - numerator),
                         dummy = 'a')
        p <- numerator / denominator * 100 
        p <- round(p, digits = 1)
        ggplot(data = df,
               aes(x = dummy,
                   y = value,
                   fill = key)) +
          geom_bar(stat = 'identity',
                   position = 'stack',
                   alpha = 0.9) +
          coord_flip() +
          labs(x = '',
               y = '') +
          ggthemes::theme_map() +
          # cowplot::theme_nothing() +
          scale_fill_manual(name = '', values = c('darkorange', 'lightblue')) +
          theme(legend.position = 'none') +
          # labs(title = paste0(p, '% completed')) +
          theme(plot.background = element_rect(fill = '#222d32', colour = '#222d32')) +
          theme(panel.background = element_rect(fill = '#222d32', colour = '#222d32')) +
          geom_text(aes(x = dummy[1],
                         y= value[1],
                         fill = NA,
                         label = paste0(p, '% completed')),
                     hjust = ifelse(df$value[1] < df$value[2], 0, 1),
                     size = 5,
                     border = NA)
          # theme(plot.title = element_text(colour = "#b8c7ce"))
      } else {
        ggplot() +
          ggthemes::theme_map() +
          theme(plot.background = element_rect(fill = '#222d32', colour = '#222d32')) +
          theme(panel.background = element_rect(fill = '#222d32', colour = '#222d32'))
      }
    })
  output$progress_plot_ui <-
    renderUI({
      li <- logged_in()
      if(!is.null(input$assessment)){
        if(input$assessment == ''){
          li <- FALSE
        }
      } else {
        li <- FALSE
      }
      if(li){
        div(style="margin-left:20px;margin-bottom: 10px; margin-right: 10px",
            plotOutput('progress_plot', height = '35px'))
      } else {
        NULL
      }
    })
  
  # Download visualizations
  output$download_visualizations <-
    downloadHandler(filename = "visualizations.pdf",
                    content = function(file){
                      
                      # Get data for radar charts
                      rd <- radar_data()
                      rd <- data.frame(rd)
                      # print(head(rd))
                      
                      # generate html
                      rmarkdown::render('rmds/visualizations.Rmd',
                                        params = list(rd = rd,
                                                      ip = input_list))
                      
                      # copy html to 'file'
                      file.copy("rmds/visualizations.pdf", file)
                      
                      # # delete folder with plots
                      # unlink("figure", recursive = TRUE)
                    },
                    contentType = "application/pdf"
    )
  
  output$menu <- renderMenu({
    li <- logged_in()
    lo <- li
    as <- input$assessment
    cl <- input$client

    # Figure out whether there are any assessments or not (ie, whether to show sidebar items)
    gccal <- get_current_client_assessment_listing()
    show_menu <- FALSE
    if(!is.null(gccal)){
      assessments <- gccal$assessment_id 
      if(!is.null(assessments)){
        if(length(assessments) > 0){
          show_menu <- TRUE
        }
      }
    } 
    if(!show_menu){
      li <- FALSE
    }
    
    mt <- main_tab()
    ss <- submissions
    # message('SUBMISSIONS IS -----------------------------')
    # x <- reactiveValuesToList(ss)
    # print(x)
    # # Instructions menu
    # (gets hidden once an assessment is selected)
    instructions_menu <- 
      generate_menu(it = input$tabs, text="Instructions",
                  tabName="instructions",
                  icon=icon("leanpub"),
                  submissions = submissions, mt = mt,
                  pass = TRUE, 
                  loggedin = li)
    
    # Get the assessment name:
    assessment_menu <- NULL
    if(li){
      this_assessment_id <- input$assessment
      gccal <- get_current_client_assessment_listing()
      has_ass <- FALSE
      if(!is.null(gccal)){
        assessments <- gccal$assessment_id 
        if(!is.null(assessments)){
          if(length(assessments) > 0){
            has_ass <- TRUE
            assessment_name <- gccal$assessment_name[as.numeric(gccal$assessment_id) == as.numeric(this_assessment_id)]
          }
        }
      }
      if(!is.null(input$assessment)){
        if(input$assessment == ''){
          has_ass <- FALSE
        }
      } else {
        has_ass <- FALSE
      }
      
      # Return text
      if(has_ass){
        assessment_name <- paste0('Assessment name: ', assessment_name)
      } else {
        assessment_name <- NULL
      }
      
      if(is.null(assessment_name)){
        assessment_menu <- NULL
      } else {
        assessment_menu <- 
          generate_menu(it = input$tabs, text=assessment_name,
                        tabName="assessment",
                        icon=icon("check-circle"),
                        pass = TRUE,
                        submissions = submissions, mt = mt,
                        loggedin = li)
        instructions_menu <-
          NULL
      }
    }
    
    if(!is.null(input$assessment)){
      if(input$assessment == ''){
        li <- FALSE
      }
    } else {
      li <- FALSE
    }
    
    sidebarMenu(
      generate_menu(it = input$tabs, text="Home",
                    tabName="home",
                    icon=icon("home"),
                    submissions = submissions, mt = mt,
                    pass = TRUE, 
                    loggedin = li),
      instructions_menu,
      generate_menu(it = input$tabs, text="Configuration",
                    tabName="configuration",
                    icon=icon("gears"),
                    pass = TRUE,
                    submissions = submissions, mt = mt,
                    loggedin = lo),
      assessment_menu,
      uiOutput('progress_plot_ui'),
      generate_menu(it = input$tabs, text="Strategy and execution",
                    tabName="strategy_and_execution",
                    icon=icon("crosshairs"),
                    submissions = submissions, mt = mt, 
                    loggedin = li,
                    sub = TRUE),
      generate_menu(it = input$tabs, text="Organization and governance",
                    tabName="organization_and_governance",
                    icon=icon("sitemap"),
                    submissions = submissions, mt = mt, 
                    loggedin = li,
                    sub = TRUE),
      generate_menu(it = input$tabs, text="Partnerships",
                    tabName="partnerships",
                    icon=icon("asterisk"),
                    submissions = submissions, mt = mt, 
                    loggedin = li,
                    sub = TRUE),
      generate_menu(it = input$tabs, text="Products",
                    tabName="products",
                    icon=icon("gift"),
                    submissions = submissions, mt = mt, 
                    loggedin = li,
                    sub = TRUE),
      generate_menu(it = input$tabs, text="Marketing",
                    tabName="marketing",
                    icon=icon("shopping-cart"),
                    submissions = submissions, mt = mt, 
                    loggedin = li,
                    sub = TRUE),
      generate_menu(it = input$tabs, text="Distribution and channels",
                    tabName="distribution_and_channels",
                    icon=icon("exchange"),
                    submissions = submissions, mt = mt, 
                    loggedin = li,
                    sub = TRUE),
      generate_menu(it = input$tabs, text="Risk management",
                    tabName="risk_management",
                    icon=icon("tasks"),
                    submissions = submissions, mt = mt, 
                    loggedin = li,
                    sub = TRUE),
      generate_menu(it = input$tabs, text="IT and MIS",
                    tabName="it_and_mis",
                    icon=icon("laptop"),
                    submissions = submissions, mt = mt, 
                    loggedin = li,
                    sub = TRUE),
      generate_menu(it = input$tabs, text="Operations and customer service",
                    tabName="operations_and_customer_service",
                    icon=icon("users"),
                    submissions = submissions, mt = mt, 
                    loggedin = li,
                    sub = TRUE),
      generate_menu(it = input$tabs, text="Responsible finance",
                    tabName="responsible_finance",
                    icon=icon("thumbs-up"),
                    submissions = submissions, mt = mt, 
                    loggedin = li,
                    sub = TRUE),
      generate_menu(it = input$tabs, text="Graphs",
                    tabName="graphs",
                    icon=icon("signal"),
                    submissions = submissions, mt = mt,
                    pass = TRUE, 
                    loggedin = li,
                    sub = TRUE),
      generate_menu(it = input$tabs, text = 'About',
                    tabName = 'about',
                    icon = icon('book'),
                    submissions = submissions, mt = mt,
                    pass = TRUE, 
                    loggedin = li)
    )
  })

  the_time <- reactiveVal(value = Sys.time())
  observeEvent(input$tabs, {
    it <- input$tabs
    new_time <- Sys.time()
    old_time <- the_time()
    difference <- round(as.numeric(old_time - new_time), digits = 3)
    message('difference is ', difference)
    if(difference < -0.5){
      message('Tab change was slow enough to assume that it was human. Setting the main_tab object to: ', it)
      main_tab(it)
    }
  })
  
  # Configuration uis
  output$configuration_ui_left <- renderUI({

    # Pickable clients
    gcl <- get_client_listing()
    message('gcl is ----------------------')
    print(gcl)
    show_client_selection <- FALSE
    if(!is.null(gcl)){
      if(nrow(gcl) > 0){
        show_client_selection <- TRUE
      }
      
    }
    if(show_client_selection){
      clients <- gcl$client_id
      clients_names <- gcl$name
      names(clients) <- paste0(clients_names, ' (id:', clients,')')
      selectInput('client',
                  'Select a client',
                  choices = clients)
      } else {
      h3('No clients yet exist for this user.')
    }
    
  })
  # Load the selected client
  observeEvent(input$client, {
    UI_SELECTED_CLIENT_ID <- input$client
    message('Selected client ', UI_SELECTED_CLIENT_ID)
    client_info <- load_client(UI_SELECTED_CLIENT_ID) #CLIENT$client_info and LISTINGS$client_assessment_listing set in load_client()
    message('---client info is')
    print(head(client_info, 3))
    message('---client listing is')
    print(head(get_client_listing(), 3))
  })
  
  
  
  output$configuration_ui_right <- renderUI({
    input$client
    input$create_client_confirm
    input$create_assessment_confirm
    gccal <- get_current_client_assessment_listing()
    show_menu <- FALSE
    if(!is.null(gccal)){
      assessments <- gccal$assessment_id 
      if(!is.null(assessments)){
        if(length(assessments) > 0){
          show_menu <- TRUE
          names(assessments) <- paste0(gccal$assessment_name, ' (id:', gccal$assessment_id, ')')      
        }
      }
    } 
    if(show_menu){
      # # Add a null value
      assessments <- c('', assessments)
      cc <- counter()
      fluidPage(
        selectInput('assessment',
                    'Select an assessment', 
                    assessments)
      )
    } else {
      fluidPage(h3('No assessments yet exist for this client.', align = 'center'))
    }
  })
  # Load the selected assessment
  observeEvent(input$assessment,{
    # Unload the previous assessment data
    unload_client_assessment()
    ia <- input$assessment
    if(ia != ''){
      UI_SELECTED_ASSESSMENT_ID <- ia
      message("You selected client_assessment_id=",UI_SELECTED_ASSESSMENT_ID)
      assessment_info <- load_client_assessment(UI_SELECTED_ASSESSMENT_ID) #CLIENT$client_info and LISTINGS$client_assessment_listing set in load_client()
      if(!is.null(assessment_info)){
        if(is.data.frame(assessment_info)){
          message('assessment_info has ', nrow(assessment_info), ' rows and is' )
          print(head(assessment_info %>%
                       dplyr::select(category_id,
                                     question_id,
                                     combined_name, score,
                                     client_id, 
                                     assessment_id)))
        }
      }
    }
    
  })
  
  # Table of client info
  output$client_table <- DT::renderDataTable({
    UI_SELECTED_CLIENT_ID <- input$client
    message('Selected client: ', UI_SELECTED_CLIENT_ID)
    if(!is.null(UI_SELECTED_CLIENT_ID)){
      client_info <- load_client(UI_SELECTED_CLIENT_ID)
      if(!is.null(client_info)){
        if(is.data.frame(client_info)){
          prettify(client_info %>%
                     dplyr::select(name,
                                   short_name,
                                   firm_type,
                                   city),
                   download_options = TRUE)
        }
      }
    }
  })
  
  # Table of assessment info
  output$assessment_table <- DT::renderDataTable({
    # Observe submissions changes and input_list
    x <- submissions
    x <- input_list
    x <- counter()
    gccal <- get_current_client_assessment_listing()
    UI_SELECTED_ASSESSMENT_ID <- input$assessment
    show_table <- FALSE
    if(!is.null(gccal)){
      assessments <- gccal$assessment_id
      if(length(assessments) > 0){
        if(!is.null(UI_SELECTED_ASSESSMENT_ID)){
          if(length(UI_SELECTED_ASSESSMENT_ID) > 0){
            assessment_info <- load_client_assessment(UI_SELECTED_ASSESSMENT_ID)
            if(!is.null(assessment_info)){
              if(length(assessment_info) > 0){
                show_table <- TRUE
              }
            }
          }
        }
      }
    }
    
    if(show_table){
      if(is.data.frame(assessment_info)){
        if(nrow(assessment_info) > 0){
          prettify(assessment_info %>%
                     dplyr::select(combined_name, score), download_options = TRUE)
        }
      }
    }
  })
  
  # Observe the create new client and show a modal for it
  observeEvent(input$create_client,{
    showModal(
      modalDialog(
        title = "Create a new client",
        fluidPage(
          fluidRow(
            column(4,
                   textInput('new_client_name',
                             'Name')),
            column(4,
                   textInput('new_client_short_name',
                             'Short name')),
            column(4,
                   textInput('new_client_firm_type',
                             'Firm type'))
          ),
          fluidRow(
            column(4,
                   textInput('new_client_address',
                             'Address')),
            column(4,
                   textInput('new_client_city',
                             'City')),
            column(4,
                   textInput('new_client_country',
                             'Country'))
          )
        ),
        easyClose = TRUE,
        footer = action_modal_button('create_client_confirm', "Submit", icon = icon('check-circle')),
        size = 'l'
      )
    )
  })
  
  # Observe the create new assessment button and show modal for it
  observeEvent(input$create_assessment,{
    
    showModal(
      modalDialog(
        title = "Create a new assessment",
        fluidPage(
          fluidRow(textInput('create_assessment_name',
                             'Name',
                             placeholder = 'e.g. Initial assessment'),
                   dateInput('create_assessment_date',
                             'Date of assessment'))
        ),
        easyClose = TRUE,
        footer = action_modal_button('create_assessment_confirm', "Submit", icon = icon('check-circle')),
        size = 'l'
      )
    )
  })
  
  # Upon creation of a new assessment, update the databas
  observeEvent(input$create_assessment_confirm, {
    # Get the time
    new_date <- input$create_assessment_date
    new_date <- paste(new_date, ' 01:00:00 CET')
    # Get the assessment name
    assessment_name <- input$create_assessment_name
    if(length(assessment_name) == 0){
      assessment_name <- paste0(paste0(sample(c(letters, LETTERS, 0:9), 5), collapse = ''),' - ', as.character(new_date))
    }
    
    # Define the form
    UI_ASSESSMENT_FORM <- 
      data.frame(assessment_id=-1,
                 client_id=get_current_client_id(),
                 assessment_name=assessment_name,
                 assessment_date=new_date,
                 stringsAsFactors = F)
    new_assessment_id <- db_edit_client_assessment(get_db_session_id(),
                                                   UI_ASSESSMENT_FORM$assessment_id,
                                                   UI_ASSESSMENT_FORM)
    
    print(paste0("Assessment ",UI_ASSESSMENT_FORM$name," for ",get_current_client_info()$name," has been added as assessment_id=",new_assessment_id))
    # Refersh the client assessment listing
    client_info <- load_client(input$client) #CLIENT$client_info and LISTINGS$client_assessment_listing set in load_client()
    refresh_client_assessment_listing()
    cc <- counter() +1
    counter(cc)
  })
  
  # Upon creation of a new client, unload the previous one and load the newly created on
  observeEvent(input$create_client_confirm, {
    # Unload the previous client
    unload_client()
    unload_client_assessment()
    # Create a new one
    random_100 <- ceiling(runif(1,1,100))
    UI_CLIENT_FORM <- data.frame(client_id=-1,
                                 ifc_client_id=random_100,
                                 name= input$new_client_name,
                                 short_name = input$new_client_short_name,
                                 firm_type = input$new_client_firm_type,
                                 address = input$new_client_address,
                                 city= input$new_client_city,
                                 country= input$new_client_country,
                                 stringsAsFactors = F)
    new_client_id <- db_edit_client(get_db_session_id(),UI_CLIENT_FORM$client_id,UI_CLIENT_FORM) #Client_id=-1 needs to come from the UI form, where -1 is specified as value when user clicks on 'add new'.  A separate argument to db_edit just for clarity as it's the key ID
    print(paste0("Client ",UI_CLIENT_FORM$name," has been added as client_id=",new_client_id))
    refresh_client_listing()
  })
  
  # Observe changes to selected assessment, and update the sliders accordingly
  observeEvent(input$assessment, {
    ia <- input$assessment
    unload_client_assessment()
    if(ia != ''){
      
      Sys.sleep(0.2) # this allows the submissions object to be cleared in generate_reactivity
      load_client_assessment(ia)
      # before the object gets updated. Has the effect of making sure that the finished/notfinished toggles are correct.
      as <- reactiveValuesToList(ASSESSMENT);
      if(!is.null(as)){
        as <- as$assessment_data %>% dplyr::select(question_id, score, rationale,last_modified_time) %>%
          # get the combined named
          left_join(competency_dict %>%
                      dplyr::select(question_id, combined_name),
                    by = 'question_id')
        as <- as %>% filter(!is.na(score));
        message('as is --------------------- ')
        print(as)
        # Go through each value in as and update the slider
        # if the item is not in as, set to 0
        for (i in 1:nrow(competency_dict)){
          this_question_id <- competency_dict$question_id[i]
          this_name <- competency_dict$combined_name[i]
          this_slider <- paste0(this_name, '_slider')
          if(this_name %in% as$combined_name){
            the_value <-as$score[as$question_id == this_question_id]
          } else{
            the_value <- 0
          }
          message('updating ', this_slider, ' to ', the_value)
          # Update the input list
          input_list[[this_slider]] <- the_value
          # Update the slider
          updateSliderInput(session = session,
                            inputId = this_slider,
                            value = the_value)
          # Update the submissions tracker
          if(!is.null(the_value)){
            if(!is.na(the_value)){
              if(the_value > 0){
                submissions[[paste0(this_name, '_submit')]] <- TRUE
              }
            }
          }
        }
      }
    }
  })
  
  # Launch assessment ui
  output$launch_assessment_ui <- renderUI({
    gccal <- get_current_client_assessment_listing()
    show_menu <- FALSE
    if(!is.null(gccal)){
      assessments <- gccal$assessment_id 
      if(!is.null(assessments)){
        if(length(assessments) > 0){
          show_menu <- TRUE
          names(assessments) <- paste0(gccal$assessment_name, ' (id:', gccal$assessment_id, ')')      
        }
      }
    }
    if(!is.null(input$assessment)){
      if(input$assessment == ''){
        show_menu <- FALSE
      }
    } else {
      show_menu <- FALSE
    }
    if(show_menu){
      fluidPage(fluidRow(column(12, align = 'center',
                                actionButton('launch_assessment',
                                             h2('Launch assessment', align = 'center'),
                                             icon = icon('play-circle', 'fa-3x')))))
    }
    
  })
  
  # Text indicating section
  output$section_text <- renderText({
    li <- logged_in()
    if(li){
      
      # Get client name
      this_client_id <- input$client
      gcl <- get_client_listing()
      if(is.null(gcl)){
        client_name <- ''
      } else {
        clients <- gcl$client_id
        clients_names <- gcl$name
        client_name <- clients_names[as.numeric(clients) == as.numeric(this_client_id)]
      }
      
      # Get assessment name
      this_assessment_id <- input$assessment
      gccal <- get_current_client_assessment_listing()
      has_ass <- FALSE
      if(!is.null(gccal)){
        assessments <- gccal$assessment_id 
        if(!is.null(assessments)){
          if(length(assessments) > 0){
            has_ass <- TRUE
            assessment_name <- gccal$assessment_name[as.numeric(gccal$assessment_id) == as.numeric(this_assessment_id)]
          }
        }
      }
      if(!is.null(input$assessment)){
        if(input$assessment == ''){
          has_ass <- FALSE
        }
      } else {
        has_ass <- FALSE
      }
      it <- input$tabs
      if(it %in% c('home', 'configuration', 'assessment',
                   'graphs', 'about')){
        has_ass <- FALSE
      }
      # Return text
      if(has_ass){
        paste0(convert_capitalization(simple_cap(gsub('_', ' ', it))))
      } else {
        NULL
      }
    }
  })
  
  
  # Text stating which assessment
  output$assessment_text <- renderText({
    li <- logged_in()
    if(li){
      
      # Get client name
      this_client_id <- input$client
      gcl <- get_client_listing()
      if(is.null(gcl)){
        client_name <- ''
      } else {
        clients <- gcl$client_id
        clients_names <- gcl$name
        client_name <- clients_names[as.numeric(clients) == as.numeric(this_client_id)]
      }
      
      # Get assessment name
      this_assessment_id <- input$assessment
      gccal <- get_current_client_assessment_listing()
      has_ass <- FALSE
      if(!is.null(gccal)){
        assessments <- gccal$assessment_id 
        if(!is.null(assessments)){
          if(length(assessments) > 0){
            has_ass <- TRUE
            assessment_name <- gccal$assessment_name[as.numeric(gccal$assessment_id) == as.numeric(this_assessment_id)]
          }
        }
      }
      if(!is.null(input$assessment)){
        if(input$assessment == ''){
          has_ass <- FALSE
        }
      } else {
        has_ass <- FALSE
      }
      
      
      # Current date
      assessment_date <- Sys.Date()
      
      # Return text
      if(has_ass){
        paste0('Assessment for ', client_name, 
               ': ',
               assessment_name,
               ', as of ', 
               format(assessment_date, '%B %d, %Y'), '.')
      } else {
        NULL
      }
    }
  })
  
  # Save and close button for header bar
  output$save_and_close_ui <-
    renderUI({
      li <- logged_in()
      if(!is.null(input$assessment)){
        if(input$assessment == ''){
          li <- FALSE
        }
      } else {
        li <- FALSE
      }
      if(li){
        actionButton('save_and_close',
                     'Save and close',
                     icon = icon('sign-in'))
      } else {
        NULL
      }
    })
  
  # On session end, close the pool
  session$onSessionEnded(function() {
    message('Session ended. Saving all data')
    message('Session ended. Closing the connection pool.')
    tryCatch(pool::poolClose(pool), error = function(e) {message('')})
  })
  
}

shinyApp(ui, server)