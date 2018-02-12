library(shiny)
library(shinydashboard)
library(shinyjs)

source('global.R')

header <- dashboardHeader(title="Benchmarking tool", 
                          dropdownMenu(type = "tasks", badgeStatus = "success",
                                       taskItem(value = 90, color = "green",
                                                "Documentation"
                                       ),
                                       taskItem(value = 17, color = "aqua",
                                                "Project X"
                                       ),
                                       taskItem(value = 75, color = "yellow",
                                                "Server deployment"
                                       ),
                                       taskItem(value = 80, color = "red",
                                                "Overall project"
                                       )
                          ))
                          
                          
                          # tags$li(class = "dropdown", plotOutput('xxx',height = '40px')))
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
      icon=icon("signal")),
    menuItem(
      text = 'About',
      tabName = 'about',
      icon = icon('book'))
  )
)

body <- dashboardBody(
  tags$style(".fa-check {color:#0000FF}"),
  tags$style(".fa-exclamation-circle {color:#B22222}"),
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
                   style = "font-size: 140%;")
             })
           )),
    column(3,
           actionButton("prevBtn", "Previous", icon = icon("arrow-circle-left", "fa-1x")),
           actionButton("nextBtn", "Next", icon = icon("arrow-circle-right", "fa-1x"))),
    column(4,
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
                       h5('Johannesburg, ', 
                          a(href = 'mailto:sheitmann@ifc.org',
                            'sheitmann@ifc.org'))),
              fluidRow(helpText("Soren has a background in database management, software engineering and web technology. He manages the applied research and integrated monitoring, evaluation and learning program for the IFC-MasterCard Foundation Partnership for Financial Inclusion. He works at the nexus of data-driven research and technology to help drive learning and innovation within IFC’s Digital Financial Services projects in Sub-Saharan Africa."))
            ),
            width = 4),
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
                       h5('Washington, DC, ', 
                          a(href = 'mailto:oanokhin@ifc.org',
                            'oanokhin@ifc.org'))),
              fluidRow(helpText("Oleksiy focuses on data-driven visualization solutions for international development. He is passionate about using programmatic tools (such as interactive dashboards) for better planning and implementation of projects, as well as for effective communication of projects results to various stakeholders."))
            ),
            width = 4),
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
                       h5('Amsterdam, ', 
                          a(href = 'mailto:jbrew1@worldbank.org',
                            'jbrew1@worldbank.org'))),
              fluidRow(helpText("Joe is a data scientist for", a(href = 'http://databrew.cc/', 'DataBrew.'), "He has a background in epidemiology and development economics. He works in both industry as a consultant as well as academia. His research focuses on the economics of malaria elimination programs in Sub-Saharan Africa."))
            ),
            width = 4)
        ),
        fluidRow(br(),
                 div(a(actionButton(inputId = "email", label = "Contact", 
                                    icon = icon("envelope", lib = "font-awesome")),
                       href="mailto:sheitmann@ifc.org",
                       align = 'center')), 
                 style = 'text-align:center;'
        )
      )
    )
  )
)

# UI
ui <- dashboardPage(header, sidebar, body, skin="blue")

# Server
server <- function(input, output, session) {
  
  output$example_ui <- renderUI({
    
    ie <- input$example
    colors <- rep('black', 3)
    make_red <- ifelse(ie > 0 & ie <=3, 1,
                       ifelse(ie > 0 & ie <=5, 2,
                              ifelse( ie > 0  & ie <= 7, 3, NA)))
    cols <- c('red', 'orange', 'green')
    if(!is.na(make_red)){
      colors[make_red] <- cols[make_red]
    }
    print(colors)
    
    fluidRow(column(4,
                    h4(span('Formative staffing', style = paste0("color:", colors[1])), span('(score 1-3)', style = paste0("color:", colors[1]))),
                    p(span('The bank is poorly-staffed.',style = paste0("color:", colors[1])))),
             column(4,
                    h4(span('Emerging staffing', style = paste0("color:", colors[2])), span('(score 4-5)', style = paste0("color:", colors[2]))),
                    p(span('The bank has sufficient staff.', style=paste0("color:", colors[2])))),
             column(4,
                    h4(span('Developed staffing', style = paste0("color:", colors[3])), span('(score 6-7)', style = paste0("color:", colors[3]))),
                    p(span('The bank is well-staffed.', style = paste0("color:", colors[3])))))
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
    paste0('In this competency, the bank is ', tolower(val), '.')
  })
  
  output$example_chart <- renderChartJSRadar({
    x <- input$example
    scores <- list(
      'This Bank' = c(x, 3, 5),
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
    # print(the_submissions)
    all_checked <- all(the_submissions)
    # print(all_checked)
    if(!all_checked){
      still_missing <- which(!the_submissions)
      still_missing <- names(still_missing)
      still_missing <- gsub('_submit', '', still_missing)
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

  # Reactive objecting observing the selected sub tab
  sub_tab_selected <- reactiveVal(value = NULL)
  ## Use the first sub_tab upon changing tabs
  observeEvent({input$tabs;
    input$prevBtn;
    input$nextBtn}, {
      message('Changed tabs to ', input$tabs)
      # Get the name of the first sub tab associated with the clicked tab
      x <- competency_dict %>%
        filter(tab_name == input$tabs)
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
                      rmarkdown::render('visualizations.Rmd',
                                        params = list(rd = rd,
                                                      ip = input_list))

                      # copy html to 'file'
                      file.copy("visualizations.pdf", file)
                      
                      # # delete folder with plots
                      # unlink("figure", recursive = TRUE)
                    },
                    contentType = "application/pdf"
    )
  
}

shinyApp(ui, server)