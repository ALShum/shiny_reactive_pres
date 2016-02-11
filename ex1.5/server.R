slow = function(x) {
  Sys.sleep(1)
  x
}
x_data = rnorm(1000, 0, 5)
y_data = rnorm(1000, 0, 5)

##library(shiny)
##library(ggplot2)
##shinyServer(
## function(input, output, session) {
##   data <- reactive({
##     x = slow(head(x_data, input$obs))
##     y = head(y_data, input$obs)
##     data.frame(x = x, y = y)
##   })
##
##   output$plot <- renderPlot({
##     qplot(x = x, y = y, data = data())
##   })
##
##   output$table <- renderTable({
##     data()
##   })
## }
##)

##library(shiny)
##library(ggplot2)
##shinyServer(
##  function(input, output, session) {
##    output$plot <- renderPlot({
##      qplot(x = slow(head(x_data, input$obs)), y = head(y_data, input$obs))
##    })
##    output$table <- renderTable({
##      data.frame(x = head(x_data, input$obs), y = head(y_data, input$obs))
##    })
##})


library(shiny)
library(ggplot2)
shinyServer(
 function(input, output, session) {
   data <- reactive({
     x = slow(head(x_data, input$obs))
     y = head(y_data, input$obs)
     df = data.frame(x = x, y = y)
     output$table <- renderTable({
      df
     })

     df
   })

   output$plot <- renderPlot({
     qplot(x = x, y = y, data = data())
   })
 }
)