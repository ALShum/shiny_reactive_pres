library(shiny)
shinyServer(
  function(input, output, session) {
    input_type = reactive({
      str(input)
    })

    output[["input"]] = renderPrint({input_type()})
  }
)