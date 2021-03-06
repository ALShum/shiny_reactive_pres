---
title       : Introduction to Shiny
subtitle    : 
author      : Alex Shum
job         : 
framework   : revealjs        # {io2012, html5slides, shower, dzslides, ...}
highlighter : highlight.js  # {highlight.js, prettify, highlight}
hitheme     : tomorrow      # 
widgets     : [mathjax]            # {mathjax, quiz, bootstrap}
mode        : selfcontained # {standalone, draft}
knit        : slidify::knit2slides
---

## Shiny: Reactive Programming for Fun

Alex Shum

February 11, 2016

---

## Shiny: Reactive Programming for Fun
* Shiny logic flow
  - Reactive sources
  - Reactive endpoint
* Reactive Functions
  - Minimize side effects!
* When to use side effects
  - Reactive Values
  - Observers/Observe Event
* Bonus: How to literally avoid getting murdered by Joe Cheng

---

## Shinytology: OT Levels
1. Started tutorial.  Used `output` and `input`.
2. Finished tutorial.  Used reactive functions,
3. Written reactive functions to depend on other reactive functions.
4. When to use `reactive()` vs. `observe()`
5. Higher-order reactives: functions that have reactive expressions as inputs and return values.
6. Reactive Expressions are Monads.

---

## Reactive Programming


```r
A = c(1, 2, 3, 4)
B = 3 * A
A = c(1, 1, 1, 1)
```

What is the value of `B` at the end of this code segment?

* Normal R: `B == c(3, 6, 9 12)`
* Reactive R: `B == c(3, 3, 3, 3)`
* Reactive programming allows automatic updates whenever a change is detected.

--- &vertical

## Simple example User Interface


```r
shinyUI(
  fluidPage(
    titlePanel("Hello World!"),

    sidebarPanel(
      sliderInput("obs", 
        "Number of observations:", 
        min = 1,
        max = 1000, 
        value = 500)
    ),
    # Show a plot of the generated distribution
    mainPanel(
      plotOutput("distPlot")
    )
  )
)
```

***

## Simple example Server Code

```r
shinyServer(
  function(input, output) {
    output$distPlot <- renderPlot({
      dist <- rnorm(input$obs)
      hist(dist)
    })
  }
)
```

***

## Source and Endpoint

* Data input from "Reactive Source"
  - Typically user input from browser interface.
  - Example: select an item, click a button, enter in a value.
* Data output as "Reactive endpoint"
  - Reactive endpoint displays result to user.
  - Example: Plot data after processing.

***

## Server and UI Design
* Server function has `input` and `output` parameters.
  - These are `reactiveValues` -- lists of reactive types.
  - `input` is a reactiveValues list for data from the UI.
  - `output` is a reactiveValues list with plots and output for the UI.

---

## All the stuff inbetween Source and Endpoint
* Reactive Expressions: like functions
* Reactive Values: like lists
* Observer: perform actions
* ObserveEvent: perform actions

--- &vertical

## Another example

ui.r


```r
shinyUI(
  fluidPage(
    titlePanel("Hello World 2!"),

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
```

*** 

server.r (incorrect)


```r
slow = function(x) {
  Sys.sleep(1)
  x
}
x_data = rnorm(1000, 0, 5)
y_data = rnorm(1000, 0, 5)

shinyServer(
function(input, output, session) {
  output$plot <- renderPlot({
    qplot(x = slow(head(x_data, input$obs)), y = head(y_data, input$obs))
  })

  output$table <- renderTable({
    data.frame(x = head(x_data, input$obs), y = head(y_data, input$obs))
  })
}
)
```

***

server.r (correct)


```r
slow = function(x) {
  Sys.sleep(1)
  x
}
x_data = rnorm(1000, 0, 5)
y_data = rnorm(1000, 0, 5)

shinyServer(
  function(input, output, session) {
    data <- reactive({
      x = slow(head(x_data, input$obs))
      y = head(y_data, input$obs)
      data.frame(x = x, y = y)
    })  

    output$plot <- renderPlot({
      qplot(x = x, y = y, data = data())
    })  

    output$table <- renderTable({
      data()
    })
  }
)
```

***

## Why use a reactive expression?
- Use a reactive expression when you would use a function in base R.
- Reactive expressions update when inputs change.
- Reactive expressions cache results!
- Cache expensive computations -- don't run operations more than necessary.
- Reactive expressions are basically functions with caching.

--- &vertical

## Functional Programming: Side effects
- A function that modifies the state outside the function.
- Pure functions return a value and make no changes to the outside state.
- Reasoning through code is easier with pure functions.  
- Reactive expressions are basically functions: avoid side effects

***

## Side effects (ANTI-Solutions)

- If your reactives have side effects then you're wrong


```r
#incorrect 
data <- reactive({
  x = slow(head(x_data, input$obs))
  y = head(y_data, input$obs)
  df = data.frame(x = x, y = y)

  output$table <- renderTable({
    df
  })

  df
})

#correct
data <- reactive({
  x = slow(head(x_data, input$obs))
  y = head(y_data, input$obs)
  data.frame(x = x, y = y)
})  

output$table <- renderTable({
  data()
})
```

***

## Side effects (ANTI-Solutions)

- If you set a reactive endpoint inside an observer you're probably wrong


```r
#incorrect
observe({
  output$table <- renderTable({
    data()
  })
})

#correct
output$table <- renderTable({
  data()
})
```

***

## Side effects (ANTI-Solutions)

- Use reactive expressions to model calculations instead of using observers to set variables


```r
#incorrect
data = reactiveValues(df = NA)
observe({
  x = slow(head(x_data, input$obs))
  y = head(y_data, input$obs)
  data$df = data.frame(x = x, y = y)
})

#correct
data <- reactive({
  x = slow(head(x_data, input$obs))
  y = head(y_data, input$obs)
  data.frame(x = x, y = y)
})  
```


--- &vertical

## More complicated example

ui.R


```r
shinyUI(
  fluidPage(
    titlePanel("Weather Plotter"),
    column(4,
      textInput(
        inputId = "location_id",
        label = "Enter location: ",
        value = "California/San_Diego"
      ),
      actionButton(
        inputId = "submit_loc",
        label = "Submit"
      )
    ),
    column(8,
      dygraphs::dygraphOutput("dygraph1")
    )
  )
)
```

***

## More complicated example

Server.R


```r
shinyServer(
  function(input, output, session) {
    rv_data = reactiveValues(
      forecast_xts = NULL
    )

    observeEvent(
      eventExpr = input[["submit_loc"]],
      handlerExpr = {
        data = rwunderground::hourly10day(input[["location_id"]])
        data_temp = data["temp"]
        forecast_xts = xts::xts(data_temp, order.by = data$date)
        rv_data$forecast_xts = forecast_xts
      }
    )

    rct_get_data = reactive({
      validate(
        need(rv_data$forecast_xts, "Please query data from server")
      )
      rv_data$forecast_xts
    })

    output[["dygraph1"]] = renderDygraph({
      dygraphs::dygraph(rct_get_data())
    })
  }
)
```

***

## Observers, what's the difference?
* In this case: using a GET request from an external resource.
* Not fetching data interally or getting input from UI (use reactive for this).
* Observers perform actions and don't return values.
* Observers are for performing actions with side effects.
* Care about code exeuction.
* No caching.

---

## Final
* Use reactive expressions for calculations.
* Use observers for actions (side effects).
* Keep your side effects outside of your reactives.
  - Joe Cheng threatened to kill anyone who does not follow this rule.

---

## END
