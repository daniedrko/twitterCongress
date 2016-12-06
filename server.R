library(shiny)
library(dplyr)
library(purrr)
library(twitteR)
library(lubridate)
library(ggplot2)
library(scales)
library(tidytext)
library(stringr)
library(jsonlite)

leg <- fromJSON("https://www.govtrack.us/api/v2/role?current=true&limit=1000")
leg$objects$person$name <- as.factor(leg$objects$person$name)

setup_twitter_oauth(consumer_key = XXXXXXX, 
                    consumer_secret = XXXXXXX,
                    access_token = XXXXXXX,
                    access_secret = XXXXXXX)

shinyServer(function(input, output) {
  
  twitter <- reactive({
    with(subset(leg$objects$person, name == input$account), tbl_df(map_df(userTimeline(twitterid, n = 3200), as.data.frame)))
  })
  
  obama <- tbl_df(map_df(userTimeline("POTUS", n = 3200), as.data.frame))
  
  
#  twitter <- reactive({
#    if(input$account == "Donald Trump") return(tbl_df(map_df(userTimeline("realDonaldTrump", n = 3200), as.data.frame))) 
#    if(input$account == "Reince Preibus") return(tbl_df(map_df(userTimeline("Reince", n = 3200), as.data.frame)))
#  })
  
  output$wordPlot <- renderPlot({
    
    reg <- "([^A-Za-z\\d#@']|'(?![A-Za-z\\d#@]))"
    
    tweet_words <- twitter() %>%
      filter(!str_detect(text, '^"')) %>%
      mutate(text = str_replace_all(text, "https://t.co/[A-Za-z\\d]+|&amp;", "")) %>%
      unnest_tokens(word, text, token = "regex", pattern = reg) %>%
      filter(!word %in% stop_words$word,
             str_detect(word, "[a-z]"))
    
    tweet_words <- mutate(tweet_words, ID = rownames(tweet_words))
    
    sent1 <- tweet_words %>%
      group_by(word) %>%
      summarize(words = length(unique(ID)))
    
    nrc <- sentiments %>%
      filter(lexicon == "nrc") %>% 
      dplyr::select(word, sentiment)
    
    sent1 <- inner_join(sent1, nrc, by = "word")
    
    sent2 <- sent1 %>%
      group_by(sentiment) %>%
      summarize(total_words = sum(words))
    
    ggplot(sent2, aes(sentiment, total_words)) +
      geom_bar(stat = "identity") +
      geom_text(aes(label = total_words, vjust = -.2)) +
      ggtitle(paste("Sentiments Detected in Tweets From", input$account))
    
  })
  
  output$d1 <- renderText({
    
    
    
    if(input$account == "President Barack Obama [D]") {
      obama$text[1,]
    } else {
      with(twitter()[1,], text)
    }
    })
  
})