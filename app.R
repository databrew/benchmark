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
  fluidRow(),
  hidden(
    lapply(seq(n_tabs), function(i) {
      div(class = "page",
        id = paste0("step", i),
        paste("Tab", i, 'of', nrow(tab_dict)))
    })
  ),
  br(),
  actionButton("prevBtn", "< Previous"),
  actionButton("nextBtn", "Next >"),
  tabItems(
    tabItem(
      tabName="instructions",
      fluidPage()
    ),
    tabItem(
      tabName="strategy_and_execution",
      fluidPage()
    ),
    tabItem(
      tabName="organization_and_governance",
      fluidPage()
    ),
    tabItem(
      tabName="partnerships",
      fluidPage()
    ),
    tabItem(
      tabName="products",
      fluidPage()
    ),
    tabItem(
      tabName="marketing",
      fluidPage()
    ),
    tabItem(
      tabName="distribution_and_channels",
      fluidPage()
    ),
    tabItem(
      tabName="risk_management",
      fluidPage()
    ),
    tabItem(
      tabName="it_and_mis",
      fluidPage()
    ),
    tabItem(
      tabName="operations_and_customer_service",
      fluidPage()
    ),
    tabItem(
      tabName="responsible_finance",
      fluidPage()
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
}

shinyApp(ui, server)