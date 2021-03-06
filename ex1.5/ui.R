library(shiny)
shinyUI(
  fluidPage(
    titlePanel("Hello World!"),

    sidebarPanel(
      sliderInput("obs", 
        "Number of observations", 
        min = 1,
        max = 1000,
        value = 100)
    ),

    mainPanel(
      plotOutput("plot"),
      tableOutput("table")
    )
  )
)