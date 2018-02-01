library(shiny)
library(shinydashboard)
library(shinyjs)

source('global.R')

header <- dashboardHeader(title="Benchmarking tool")
sidebar <- dashboardSidebar(
  sidebarMenu(
    id = 'tabs',
    menuItem(
      text="Instructions",
      tabName="instructions",
      icon=icon("leanpub")),
    menuItem(
      text="Strategy and Execution",
      tabName="strategy_and_execution",
      icon=icon("crosshairs")),
    menuItem(
      text="Organization and Governance",
      tabName="organization_and_governance",
      icon=icon("sitemap")),
    menuItem(
      text="Partnerships",
      tabName="partnerships",
      icon=icon("asterisk")),
    menuItem(
      text="Products",
      tabName="products",
      icon=icon("gift")),
    menuItem(
      text="Marketing",
      tabName="marketing",
      icon=icon("shopping-cart")),
    menuItem(
      text="Distribution and Channels",
      tabName="distribution_and_channels",
      icon=icon("exchange")),
    menuItem(
      text="Risk Management",
      tabName="risk_management",
      icon=icon("tasks")),
    menuItem(
      text="IT and MIS",
      tabName="it_and_mis",
      icon=icon("laptop")),
    menuItem(
      text="Operations and Customer Service",
      tabName="operations_and_customer_service",
      icon=icon("users")),
    menuItem(
      text="Responsible Finance",
      tabName="responsible_finance",
      icon=icon("thumbs-up")),
    menuItem(
      text="Graphs",
      tabName="graphs",
      icon=icon("signal"))
  )
)

body <- dashboardBody(
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "custom.css")
  ),
  useShinyjs(),
  fluidRow(
    column(5,
           hidden(
             lapply(seq(n_tabs), function(i) {
               div(class = "page",
                   id = paste0("step", i),
                   paste("Tab", i, 'of', nrow(tab_dict)),
                   style = "font-size: 200%;")
             })
           )),
    column(7,
           actionButton("prevBtn", "< Previous"),
           actionButton("nextBtn", "Next >"))
    
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
              column(6,
                     strong('Staffing'),
                     p('The bank is well-staffed.'),
                     sliderInput('example',
                                 'Score',
                                 min = 0,
                                 max = 5,
                                 value = 3)),
              column(6,
                     h4('Meaning:'),
                     h3(textOutput('example_text')))
            ),
            height = '300px'),
          box(chartJSRadarOutput('example_chart'), height = '300px')
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
    )
  )
)

# UI
ui <- dashboardPage(header, sidebar, body, skin="blue")

# Server
server <- function(input, output, session) {
  
  output$example_text <- renderText({
    x <- input$example
    dict <- data_frame(key = 0:5,
                       value = c('not at all',
                                 'barely',
                                 'somewhat',
                                 'moderately well',
                                 'well',
                                 'completely'))
    val <- dict %>% filter(key == x) %>% .$value
    paste0('The above statement describes this bank ', val, '.')
  })
  
  output$example_chart <- renderChartJSRadar({
    x <- input$example
    scores <- list(
      'This Bank' = c(x, 3, 5),
      'Best Practice' = rep(5, 3)
    )
    labs <- c('Staffing', 'Dimension B', 'Dimension A')
    chartJSRadar(scores = scores, labs = labs, maxScale = 5,
                 scaleStepWidth = 1,
                 scaleStartValue = 1,
                 responsive = TRUE,
                 labelSize = 11,
                 showLegend = TRUE,
                 addDots = TRUE,
                 showToolTipLabel = TRUE,
                 colMatrix = t(matrix(c(col2rgb('darkorange'), col2rgb('lightblue')), nrow = 2, byrow = TRUE)))
    
  })
  
  # Define a reactive value which is the currently selected tab number
  rv <- reactiveValues(page = 1)
  
  observe({
    toggleState(id = "prevBtn", condition = rv$page > 1)
    toggleState(id = "nextBtn", condition = rv$page < n_tabs)
    hide(selector = ".page")
    show(paste0("step", rv$page))
  })
  
  # Define function for changing the tab number in one direction or the 
  # other as a function of forward/back clicks
  navPage <- function(direction) {
    rv$page <- rv$page + direction
  }
  
  # Observe the forward/back clicks, and update rv$page accordingly
  observeEvent(input$prevBtn, {
    # Update rv$page
    navPage(-1)
    })
  observeEvent(input$nextBtn, {
    # Update rv$page
    navPage(1)
  })
  
  # Observe any changes to rv$page, and update the selected tab accordingly
  observeEvent(rv$page, {
    tab_number <- rv$page
    tab_name <- tab_dict %>% filter(number == tab_number) %>% .$name
    updateTabsetPanel(session, inputId="tabs", selected=tab_name)
  })
  
  # Observe any click on the left tab menu, and update accordingly the rv$page object
  observeEvent(input$tabs, {
    tab_name <- input$tabs
    tab_number <- tab_dict %>% filter(name == tab_name) %>% .$number
    message(paste0('Selected tab is ', input$tabs, '. Number: ', tab_number))
    rv$page <- tab_number
  })
  
  # Create reactive values to observe the submissions
  submissions <- reactiveValues()
  
  # Generate reactive input list for submission numbers saving
  eval(parse(text = create_input_list()))

  # Generate the reactive objects associated with each tab  
  for(tn in 1:length(tab_names)){
    message(tn)
    this_tab_name <- tab_names[tn]
    these_competencies <- competency_dict %>% filter(tab_name == this_tab_name) %>% .$competency
    eval(parse(text = generate_reactivity(tab_name = this_tab_name,
                                          competencies = these_competencies)))
  }

  # Generate the uis for each tab
  for(tn in 1:length(tab_names)){
    message(tn)
    this_tab_name <- tab_names[tn]
    these_competencies <- competency_dict %>% filter(tab_name == this_tab_name) %>% .$competency
    eval(parse(text = generate_ui(tab_name = this_tab_name,
                                          competencies = these_competencies)))
  }
  
  # Box with warnings for incomplete data
  output$warnings_box <- renderUI({
    
    the_submissions <- reactiveValuesToList(submissions)
    the_submissions <- unlist(the_submissions)
    print(the_submissions)
    all_checked <- all(the_submissions)
    print(all_checked)
    if(!all_checked){
      still_missing <- which(!the_submissions)
      still_missing <- names(still_missing)
      still_missing <- unlist(lapply(strsplit(still_missing, '[[:digit:]]'), function(x){
        substr(x[1], 1, nchar(x[1]) - 1)}))
      still_missing <- data.frame(combined_name = still_missing)
      still_missing <- left_join(still_missing, 
                                 competency_dict %>%
                                   mutate(combined_name = tolower(combined_name)))
      missing_text <- 'Interpret results with caution - you did not submit responses for the below areas:'
      x <- still_missing %>%
        dplyr::select(tab_name,
                      competency) %>%
        mutate(tab_name = simple_cap(gsub('_', ' ', tab_name)),
               competency = simple_cap(gsub('_', ' ', competency))) %>%
        dplyr::rename(`Tab name` = tab_name,
                      Competency = competency)
      x <- x %>%
        distinct(`Tab name`, Competency, .keep_all = TRUE)
      missing_table <- DT::datatable(x, rownames = FALSE,
                                     options = list(
                                       pageLength = 5,
                                       dom = 'tip'))
      the_box <- box(title = 'Warning',
                     status = 'danger',
                     collapsible = TRUE,
                     width = 12,
                     fluidPage(
                       fluidRow(p(missing_text)),
                       fluidRow(missing_table))
      )
      
      
    } else {
      the_box <- NULL
    }
    return(the_box)
  })
  
  # Radar charts
  for(i in 1:length(tab_names)){
    eval(parse(text = generate_radar_server(tab_name = tab_names[i])))
  }

  # Create the graphs page
  output$graphs_ui <-
    renderUI({
      fluidPage(
        fluidRow(h3('Examine your results below:')),
        
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
        eval(parse(text = generate_radar_ui(tab_name = tab_names[10]))),
        fluidRow(
          uiOutput('warnings_box')
        )
      )
    })
  
  # Create reactive dataset for plotting radar
  radar_data <- reactive({
    make_radar_data(ip = input_list)
  })
  
}

shinyApp(ui, server)