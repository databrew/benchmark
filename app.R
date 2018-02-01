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
    column(12,
           hidden(
             lapply(seq(n_tabs), function(i) {
               div(class = "page",
                   id = paste0("step", i),
                   paste("Tab", i, 'of', nrow(tab_dict)),
                   style = "font-size: 200%;")
             })
           )),
    actionButton("prevBtn", "< Previous"),
           actionButton("nextBtn", "Next >")
  ),
  tabItems(
    tabItem(
      tabName="instructions",
      includeMarkdown('includes/instructions.md')
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
      fluidPage()
    )
  )
)

# UI
ui <- dashboardPage(header, sidebar, body, skin="blue")

# Server
server <- function(input, output, session) {
  
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
  
}

shinyApp(ui, server)