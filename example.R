SESSION <- 1

update_session <- function(){
  message('Updating session')
  x <- SESSION
  new_x <- x + 1
  SESSION <- x
  # SESSION <<- x # same effects
}

library(shiny)

# Define UI for application that draws a histogram
ui <- fluidPage(
  
  # Application title
  titlePanel("Reactivity example"),
  
  # Sidebar with a slider input for number of bins 
  sidebarLayout(
    sidebarPanel(
      actionButton('click', 'Click here')
    ),
    
    # Show a plot of the generated distribution
    mainPanel(
      textOutput("the_text")
    )
  )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
  
  observeEvent(input$click, {
    update_session()
  })
  
  output$the_text <- renderText({
    SESSION
  })
}

# Run the application 
shinyApp(ui = ui, server = server)

