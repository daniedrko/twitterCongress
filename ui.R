library(shiny)
library(jsonlite)

leg <- fromJSON("https://www.govtrack.us/api/v2/role?current=true&limit=1000")
leg$objects$person$name <- as.factor(leg$objects$person$name)

twitter <- reactive({
  with(subset(leg$objects$person, name == input$account), tbl_df(map_df(userTimeline(twitterid, n = 3200), as.data.frame)))
})


shinyUI(fluidPage(
  sidebarLayout(
    sidebarPanel(
      selectInput("account",
                  "Select a Lawmaker:", 
                  levels(leg$objects$person$name)),
      HTML("This application uses two different API sources:
           <ul>
              <li><a href='https://www.govtrack.us/developers/api'>GovTrack's</a> Database of Legislators</li>
              <li><a href='https://dev.twitter.com/overview/api'>Twitter API data</a> obtained for each Congressional user</li>
           </ul>")
    ),
    mainPanel(
      fluidRow(
        plotOutput("wordPlot")
      ),
      fluidRow( tags$h2("Most Recent Tweets:"),
        column(6, textOutput("d1")
          
          
        ))
      )
    )
  )
  
)