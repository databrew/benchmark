SESSION <- 1

update_session <- function(){
  x <- SESSION
  new_x <- x + 1
  message('Updating session from ', x, ' to ', new_x)
  # SESSION <- new_x
  SESSION <<- new_x # same effects
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
    # Since SESSION is not reactive, this text doesn't get updated
    # without an explicit call to something else being updated...
    SESSION
  })
}

# Run the application 
shinyApp(ui = ui, server = server)

