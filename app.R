library(shiny)
library(shinydashboard)
library(shinyjs)
library(rhandsontable)
library(data.table)

  source('global.R')

the_width <- 350
header <- dashboardHeader(title="DFS Benchmarking Tool",
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
    column(3,
           hidden(
             lapply(seq(n_tabs), function(i) {
               div(class = "page",
                   id = paste0("step", i),
                   paste("Tab", i, 'of', nrow(tab_dict)),
                   style = "font-size: 140%;")
             })
           ),
           uiOutput('log_in_text')),
    column(6,
           align = 'center',
           uiOutput('log_in_out')),
    column(3,
           plotOutput('progress_plot', height = '50px')),
    height = '50px'
    
  ),
  tabItems(
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
        )
      )
    ),
    tabItem(
      tabName = 'settings',
      fluidPage(
        fluidRow(column(6,
                        uiOutput('settings_ui')),
                 column(6,
                        uiOutput('settings_ui2'))),
        fluidRow(column(12,
                        align = 'center',
                        uiOutput('settings_ui3')))
      )
    )
  )
)

# UI
ui <- dashboardPage(header, sidebar, body, skin="blue")

# Server
server <- function(input, output, session) {
  
  
  user <- reactiveVal(value = as.character(NA))
  user_id <- reactiveVal(value = -1)
  logged_in <- reactiveVal(value = FALSE)
  user_data <- reactiveValues()
  
  # Observe the log in submit and see if logged in
  observeEvent(input$log_in_submit, {
    # Attempt to log in
    log_in_attempt <- db_login(input$user_name,
                               input$password)
    # Evaluate success
    if(log_in_attempt$user_id >= 0){
      # Success
      user(input$user_name)
      logged_in(TRUE)
      user_id(log_in_attempt$user_id)
      user_data$client_listing <- db_get_client_listing()

    } else {
      # Set values to not logged in
      user(NA)
      logged_in(FALSE)
      user_id(-1)
      # And re-generate the log in modal
      showModal(log_in_modal)
    }
  })
  
  # Observe the log out and clear the user
  observeEvent(input$log_out, {
    user('')
    user_id(-1)
    logged_in(FALSE)
    user_data$client_listing <- NULL
    user_data$client_info <- NULL
  })
  
  # Log in / out
  output$log_in_out <- renderUI({
    # Get whether currently logged in
    logged_in_now <- logged_in()
    if(is.null(logged_in_now)){
      logged_in_now <- FALSE
    }
    if(logged_in_now){
      fluidPage(actionButton('edit_user', 'Edit user details', icon = icon('sign-in')),
                actionButton('log_out', 'Log out', icon = icon('sign-in')),
                actionButton('edit_client', 'Edit client details', icon = icon('sign-in')))
    } else {
      actionButton('log_in', 'Log in', icon = icon('sign-in'))
    }
  })
  
  # Observe the log in button and do a modal
  observeEvent(input$log_in, {
    showModal(log_in_modal)
  })
  
  # Observe log in submit and prompt selection of client and assessment name
  observeEvent(input$log_in_submit, {
    updateTabItems(session, "tabs", 'settings')
  })
  
  # Once a selection is sure, start the survey
  observeEvent(input$client_select_submit,{
    updateTabItems(session, "tabs", 'strategy_and_execution')
  })
  
  # Observe editing buttons
  observeEvent(input$edit_user, {
    showModal(modalDialog(
      title = "Edit user",
      fluidPage(
        helpText('The below takes data but doesn\'t actually do anything with it.'),
        rHandsontableOutput("edit_user_table")),
      easyClose = TRUE,
      footer = action_modal_button('edit_user_submit', "Submit", icon = icon('check-circle')),
      size = 'l'
    )) 
  })
  
  observeEvent(input$edit_client, {

    # udci <- user_data$client_info
    # # udci$ifc_client_id <- udci$ifc_client_id + 1
    # user_data$client_info <- udci
    # 
    
    showModal(modalDialog(
      title = "Edit client",
      fluidPage(
        rHandsontableOutput("edit_client_table")
        
      ),
      easyClose = TRUE,
      footer = action_modal_button('edit_client_submit', "Submit", icon = icon('check-circle')),
      size = 'l'
    )) 
  })
  
  
  # Generate logged in text
  output$log_in_text <- renderText({
    u <- user()
    message('user is ', u)
    out <- 'Not logged in'
    if(!is.null(u)){
      if(!is.na(u)){
        if(u != ''){
          out <- paste0('Logged in as ', u)
        }
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
  main_tab <- reactiveVal(value = 'instructions')

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
      it <- main_tab()
      if(it != 'about'){
        the_submissions <- reactiveValuesToList(submissions)
        the_submissions <- unlist(the_submissions)
        numerator <- length(which(the_submissions))
        denominator <- length(the_submissions)
        df <- data.frame(key = c('Finished', 'All'),
                         value = c(numerator, denominator),
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
          labs(title = paste0(p, '% completed')) +
          theme(plot.background = element_rect(fill = '#ecf0f5', colour = '#ecf0f5')) +
          theme(panel.background = element_rect(fill = '#ecf0f5', colour = '#ecf0f5'))
      } else {
        ggplot() +
          ggthemes::theme_map() +
          theme(plot.background = element_rect(fill = '#ecf0f5', colour = '#ecf0f5')) +
          theme(panel.background = element_rect(fill = '#ecf0f5', colour = '#ecf0f5'))
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

    mt <- main_tab()
    sidebarMenu(
      generate_menu(text="Home",
                    tabName="instructions",
                    icon=icon("leanpub"),
                    submissions = submissions, mt = mt,
                    pass = TRUE),
      generate_menu(text = 'Settings',
                    tabName = 'settings',
                    icon = icon('user'),
                    submissions = submissions, mt = mt,
                    pass = TRUE),
      generate_menu(text="Strategy and execution",
                    tabName="strategy_and_execution",
                    icon=icon("crosshairs"),
                    submissions = submissions, mt = mt),
      generate_menu(text="Organization and governance",
                    tabName="organization_and_governance",
                    icon=icon("sitemap"),
                    submissions = submissions, mt = mt),
      
      generate_menu(text="Partnerships",
                    tabName="partnerships",
                    icon=icon("asterisk"),
                    submissions = submissions, mt = mt),
      generate_menu(text="Products",
                    tabName="products",
                    icon=icon("gift"),
                    submissions = submissions, mt = mt),
      generate_menu(text="Marketing",
                    tabName="marketing",
                    icon=icon("shopping-cart"),
                    submissions = submissions, mt = mt),
      generate_menu(text="Distribution and channels",
                    tabName="distribution_and_channels",
                    icon=icon("exchange"),
                    submissions = submissions, mt = mt),
      generate_menu(text="Risk management",
                    tabName="risk_management",
                    icon=icon("tasks"),
                    submissions = submissions, mt = mt),
      generate_menu(text="IT and MIS",
                    tabName="it_and_mis",
                    icon=icon("laptop"),
                    submissions = submissions, mt = mt),
      generate_menu(text="Operations and customer service",
                    tabName="operations_and_customer_service",
                    icon=icon("users"),
                    submissions = submissions, mt = mt),
      generate_menu(text="Responsible finance",
                    tabName="responsible_finance",
                    icon=icon("thumbs-up"),
                    submissions = submissions, mt = mt),
      generate_menu(text="Graphs",
                    tabName="graphs",
                    icon=icon("signal"),
                    submissions = submissions, mt = mt,
                    pass = TRUE),
      generate_menu(text = 'About',
                    tabName = 'about',
                    icon = icon('book'),
                    submissions = submissions, mt = mt,
                    pass = TRUE))
  })
  # isolate({
  #   mt <- main_tab()
  #   updateTabItems(session, "tabs", mt)
  # })
  
  the_time <- reactiveVal(value = Sys.time())
  observeEvent(input$tabs, {
    it <- input$tabs
    new_time <- Sys.time()
    old_time <- the_time()
    difference <- as.numeric(old_time - new_time)
    message('Time between tab change was ', abs(round(difference, digits = 2)))
    if(difference < -0.5){
      message('---Slow tab change time assumed to be human. Setting tab to ', it)
      main_tab(it)
    }
  })
  
  # Reactive assessment choices
  assessment_choices_reactive <- reactive({
    x <- input$log_in_submit
    x <- input$client_select
    a <- SESSION$client_info$assessments$assessment_id
    names(a) <- SESSION$client_info$assessments$assessment_name
    message('assessment choices reactive is ')
    print(a)
    return(a)
  })

  
  # Reactive client choices
  client_choices_reactive <- reactive({
    # Just observe new client
    input$create_new_client_submit
    udcl <- SESSION$client_listing
    message('udcl is ')
    print(udcl)
    
    client_choices <- udcl$client_id
    names(client_choices) <- udcl$name
    return(client_choices)
  })
  
  # User details ui
  output$settings_ui3 <- renderUI({
    
    fluidPage(
      fluidRow(column(12, align = 'center',
                      action_modal_button('client_select_submit', "Continue", icon = icon('check-circle', 'fa-3x')))),
      hr(),
      br(), br(), 
      fluidRow(h1('Or', align = 'center')),
      fluidRow(h3('Create a new assessment', align = 'center')),
      fluidRow(column(12, align = 'center',
                      actionButton('create_new_assessment', 'Create new assessment', icon = icon('user')))),
      fluidRow(h1('Or', align = 'center')),
      fluidRow(h3('Create a new client', align = 'center')),
      fluidRow(column(12, align = 'center',
                      actionButton('create_new_client', 'Create new client', icon = icon('user'))))
    )
    
  })
  output$settings_ui2 <- renderUI({
    li <- logged_in()
    
    assessment_choices <- assessment_choices_reactive()
    # # a <- assessments$assessment_id
    # # names(a) <- assessments$assessment_name
    # # assessment_choices <- a
    # input$client_select # just observe
    # assessment_choices <- SESSION$client_assessment_listing$assessment_id
    # names(assessment_choices) <- SESSION$client_assessment_listing$assessment_name
    # message('assessment choices are')
    # print(assessment_choices)
    
    if(!li){
      return(NULL)
    } else {
      column(12, align = 'center',
             selectizeInput('assessment_name_select',
                            'Select assessment name',
                            choices = assessment_choices))
    }
    })
  output$settings_ui <- renderUI({
    li <- logged_in()
    
    client_choices <- client_choices_reactive()
    
    
    if(!li){
      fluidPage(h2('Log in above', align = 'center'))
    } else {
      u <- user()
      fluidPage(
        fluidRow(column(12, align = 'center',
                        selectizeInput('client_select',
                                        'Select client',
                                        choices = client_choices)))
      )
    }
  })
  
  # Observe the client selection confirmation
  observeEvent(input$client_select, {
    selected_client <- input$client_select
    
    user_data$client_info <- SESSION$client_info <- load_client(selected_client)
    message('The selected client is ', selected_client)
  })
  observeEvent(input$client_select_confirm, {
    selected_client <- input$client_select
    user_data$client_info <- SESSION$client_info <- load_client(selected_client)
    message('The selected client is ', selected_client)
  })
  observeEvent(input$log_in_submit, {
    selected_client <- input$client_select
    user_data$client_info <- SESSION$client_info <- load_client(selected_client)
    message('The selected client is ', selected_client)
  })
  
  # If creating a new client/assessment, prompt details
  observeEvent(input$create_new_client,{
    showModal(modalDialog(
      title = "Create new client",
      fluidPage(
        fluidRow(column(12,
                        textInput('client_type',
                                  'Create a new client',
                                  placeholder = 'e.g. Acme Industries')))#,
      ),
      easyClose = TRUE,
      footer = action_modal_button('create_new_client_submit', "Submit", icon = icon('check-circle')),
      size = 's'
    ))
  })
  observeEvent(input$create_new_assessment,{
    showModal(modalDialog(
      title = "Create new assessment",
      fluidPage(
        fluidRow(
                 column(12,
                        textInput('assessment_name_type',
                                  'Create a new assessment name',
                                  placeholder = 'e.g. Initial intake survey')))#,
      ),
      easyClose = TRUE,
      footer = action_modal_button('create_new_assessment_submit', "Submit", icon = icon('check-circle')),
      size = 's'
    ))
  })
  
  # Observe any selection of assessment
  observeEvent(input$assessment_name_select, {
                   message('assessment name is ', input$assessment_name_select)
                   li <- logged_in()
                   if(li){
                     
                     # Make sure a client has been selected
                     selected_client <- input$client_select
                     user_data$client_info <- load_client(selected_client)
                     
                     cid <- get_current_client_id()
                     ccid <- -1
                     if(length(cid) > 0){
                       if(!is.na(cid)){
                         if(cid != ''){
                           ccid <- cid
                         }
                       }
                     }
                     
                     message('ccid is ', ccid)
                     td <- today()
                     new_name <- as.numeric(input$assessment_name_select)
                     message('assessment id / new name is')
                     print(new_name)
                     SESSION$client_info$current_assessment_id <- as.numeric(new_name)
                     updated_assessment_id <- 
                       db_edit_client_assessment(-1,
                                                 data.frame(client_id=ccid,
                                                            assessment_name=new_name,
                                                            assessment_date=td,
                                                            stringsAsFactors=F))
                     # message('updated assessment id is ')
                     # print(updated_assessment_id)
                     # SESSION$client_info$current_assessment_id <- updated_assessment_id
                     
                     # If not -1 load it
                     # if(updated_assessment_id != -1){
                     cid <- as.numeric(get_current_client_id())
                     message('cid here is ', cid)
                     
                     user_data$client_info <- 
                       SESSION$client_info <- 
                       load_client(cid)
                     
                     ins <- input$assessment_name_select
                     message('ins here is ', ins)
                     load_client_assessment(ins)
                     # }
                     
                   }
                   
                 })
  
  observeEvent(input$create_new_client_submit, {
    message('Trying to create new client: ', input$client_type)
    ccid <- get_current_client_id()
    message('+++ccid is ', ccid)
    updated_client_id <- 
      db_edit_client(ccid,
                     data.frame(client_id=SESSION$client_info$client_id,
                                ifc_client_id=SESSION$client_info$ifc_client_id,
                                name=input$client_type,
                                short_name='',
                                firm_type='',
                                address='',
                                city='',
                                country='',
                                stringsAsFactors = F))
    
  })
  
  observeEvent(input$create_new_assessment_submit,{
    # Make sure a client has been selected
    selected_client <- input$client_select
    user_data$client_info <- load_client(selected_client)
    
    cid <- get_current_client_id()
    ccid <- -1
    if(length(cid) > 0){
      if(!is.na(cid)){
        if(cid != ''){
          ccid <- cid
        }
      }
    }
    
    message('ccid is ', ccid)
    td <- today()
    new_name <- input$assessment_name_type
    updated_assessment_id <- 
      db_edit_client_assessment(-1,
                                data.frame(client_id=ccid,
                                           assessment_name=new_name,
                                           assessment_date=td,
                                           stringsAsFactors=F))
    message('updated assessment id is ')
    print(updated_assessment_id)
    # Update the assessment id in the session
    
    
    # If not -1 load it
    # if(updated_assessment_id != -1){
      user_data$client_info <- 
        SESSION$client_info <- 
        load_client(get_current_client_id())

      load_client_assessment(updated_assessment_id)
    # }
    
  })

  # On session end, close the pool
  session$onSessionEnded(function() {
    message('Session ended. Closing the connection pool.')
    tryCatch(pool::poolClose(pool), error = function(e) {message('')})
  })
  
  output$edit_client_table <- renderRHandsontable({
    input$client_select # just observing
    udci <- SESSION$client_info
    x <- data_frame(client_id=udci$client_id,
                    ifc_client_id=udci$ifc_client_id,
                    name= udci$name,
                    short_name= nn(udci$short_name),
                    firm_type= nn(udci$firm_type),
                    address= udci$address,
                    city= udci$city,
                    country= udci$country)
    rhandsontable(x, readOnly = FALSE, selectCallback = TRUE,
                  rowHeaders = NULL)
  })
  
  output$edit_user_table <- renderRHandsontable({
    x <- data_frame(user_id = SESSION$user_id,
                    user_name = SESSION$user_name)
    rhandsontable(x, readOnly = FALSE, selectCallback = TRUE,
                  rowHeaders = NULL)
  })
    
  observeEvent(input$edit_client_submit, {
    x <- input$edit_client_table[[1]]
    vals <- unlist(lapply(x[[1]], function(z){nn(z)}))
    out <- data_frame(client_id = NA,
                      ifc_client_id = NA,
                      name = NA,
                      short_name = NA,
                      firm_type = NA,
                      address = NA,
                      city = NA,
                      country = NA)
    out[1,] <- vals
    out$client_id <- as.numeric(out$client_id)
    out$ifc_client_id <- as.numeric(out$ifc_client_id)
    
    # Update the database
    db_edit_client(out$client_id,
                   out)
    
    # # Update the session
    udci <- user_data$client_info
    # udci$client_id <- out$client_id
    # udci$ifc_client_id <- out$ifc_client_id
    # udci$name <- out$name
    # udci$short_name <- out$short_name
    # udci$firm_type <- out$firm_type
    # udci$address <- out$address
    # udci$city <- out$city
    # udci$country <- out$country
    # message('overwriting user_data')
    # user_data$client_info <- udci
    message('Overwriting user_data client info and client listing')
    updated_client_id <- udci$client_id
    user_data$client_info <- SESSION$client_info <- load_client(updated_client_id)
    user_data$client_listing <- SESSION$client_listing <- db_get_client_listing()
  })
  
  # Observe the input list (the list of all results)
  results <- reactive({
    ip <- input_list
    ip <- reactiveValuesToList(ip)
    ip <- unlist(ip)
    
    combined_names <- competency_dict$combined_name
    
    # Get values for each of the combined names
    vals_df <-
      data.frame(combined_name = combined_names)
    # Get broken down names from dict
    vals_df <- left_join(vals_df,
                         competency_dict,
                         by = 'combined_name')
    vals_df$value <- NA
    vals_df$value_name <- paste0(vals_df$combined_name, '_slider')
    for(i in 1:nrow(vals_df)){
      the_name <- vals_df$value_name[[i]]
      the_value <- ip[names(ip) == the_name]
      the_value <- as.numeric(the_value)
      vals_df$value[i] <- the_value
    }
    
    # Group by competency and get weighted score
    out <- vals_df %>%
      dplyr::select(tab_name, competency, value)
    return(out)
  })
  
  # # Upon any change of tabs, see the input_list
  # observeEvent(input$tabs, {
  #   right <- results()
  #   # print(head(right))
  #   # get the question id
  #   left <- view_assessment_questions_list %>%
  #     dplyr::select(question_id, tab_name, competency)
  #   x <- left_join(left, right, by = c('tab_name', 'competency'))
  #   x <- x %>% dplyr::select(question_id, value)
  #   message('x is ')
  #   print(head(x))
  # })
  

  
}

shinyApp(ui, server)