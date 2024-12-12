library(shiny)
library(DBI)
library(RMySQL)
library(dplyr)
library(dygraphs)
library(xts)
library(TTR)

group_data <- function(data, interval = "day") {
  data %>%
    mutate(
      timestamp = case_when(
        interval == "day" ~ as.Date(timestamp),
        interval == "week" ~ as.Date(cut(as.Date(timestamp), "week")),
        interval == "hour" ~ as.POSIXct(cut(as.POSIXct(timestamp), "hour")),
        interval == "month" ~ as.Date(cut(as.Date(timestamp), "month"))
      )
    ) %>%
    group_by(timestamp) %>%
    summarise(
      open = first(open),
      high = max(high),
      low = min(low),
      close = last(close)
    ) %>%
    ungroup()
}


ui <- fluidPage(
  titlePanel("BTC Price Dashboard"),
  sidebarLayout(
    sidebarPanel(
      tags$div(
        actionButton("refresh_btn", "Refresh BTC Prices"),
        style = "margin-bottom: 15px;" 
      ),
      tags$div(
        actionButton("update_btn", "Update BTC Prices"),
        style = "margin-bottom: 15px;"
      ),
      tags$div(
        selectInput("interval", 
                    "Select Time Interval:",
                    choices = c("Hourly" = "hour", 
                                "Daily" = "day", 
                                "Weekly" = "week", 
                                "Monthly" = "month"),
                    selected = "month"),
        style = "margin-bottom: 15px;"
      ),
      tags$div(
        selectInput("chart_type", 
                    "Select Chart Type:",
                    choices = c("Market Cap" = "market_cap", "Moving Averages" = "moving_avg"),
                    selected = "market_cap"),
        style = "margin-bottom: 15px;"
      ),
      tags$div(
        checkboxInput("logscale_toggle", "Log Scale", value = FALSE),
        style = "margin-bottom: 15px;"
      ),
      tags$div(
        textAreaInput("notes", "Notes:", "", width = "100%", height = "300px"),
        style = "margin-bottom: 15px;"
      )
    ),
    mainPanel(
      dygraphOutput("btc_plot", height = "350px"), 
      dygraphOutput("btc_volume_plot", height = "350px")
    )
  )
)


server <- function(input, output, session) {
  
  btc_data <- reactiveVal()
  selected_range <- reactiveVal(NULL) 
  
  
  observeEvent(input$refresh_btn, {
    tryCatch({
      
      con <- dbConnect(
        RMySQL::MySQL(),
        dbname = "btc_database",    
        host = "localhost",         
        port = 3306,                
        user = "root",        
        password = "judizmendi1"
      )
      
      btc_price <- dbGetQuery(con, "SELECT * FROM btc_prices ORDER BY timestamp;")
      btc_price <- na.omit(btc_price)
      btc_price <- btc_price[!duplicated(btc_price$timestamp), ]
      
      dbDisconnect(con)
      
      btc_data(btc_price)
      showNotification("Data refreshed successfully!", type = "message")
    }, error = function(e) {
      showNotification("Error while refreshing data: Verify the database.", type = "error")
    })
  })
  
  
  observeEvent(input$update_btn, {
    tryCatch({
      con <- dbConnect(
        RMySQL::MySQL(),
        dbname = "btc_database",    
        host = "localhost",         
        port = 3306,                
        user = "root",        
        password = "judizmendi1"  
      )
      
      btc_old <- dbGetQuery(con, "SELECT * FROM btc_prices ORDER BY timestamp;")
      btc_old <- na.omit(btc_old)
      
      btc_old$timestamp <- as.POSIXct(btc_old$timestamp, 
                                      format = "%Y-%m-%d %H:%M:%S",
                                      tz = "UTC")
      
      latest_date <- max(btc_old$timestamp, na.rm = TRUE)
      
      start_date <- format(latest_date, "%Y%m%d")  
      
      end_date <- format(Sys.time(), "%Y%m%d")  
      
      
      
      if (start_date != end_date) {
        coins <- crypto_list(only_active = TRUE)
        btc_new <- crypto_history(coins, 
                                  limit = 1, 
                                  start_date = start_date, 
                                  end_date = end_date, 
                                  interval = "1h", 
                                  finalWait = FALSE)
        btc_combined <- rbind(
          btc_old, 
          btc_new)
        
      } else {
        btc_combined <- btc_old
      }
      
      
      btc_combined <- btc_combined[!duplicated(btc_combined$timestamp), ]
      
      
      apply(btc_combined, 1, function(row) {
        
        row <- lapply(row, function(x) {
          if (is.na(x)) {
            "NULL"  
          } else if (is.character(x) || is.factor(x)) {
            sprintf("'%s'", gsub("'", "\\'", x))  
          } else if (inherits(x, "POSIXct") || inherits(x, "Date")) {
            sprintf("'%s'", format(x, "%Y-%m-%d %H:%M:%S"))  
          } else if (is.numeric(x)) {
            x  
          } else {
            sprintf("'%s'", x)  
          }
        })
        
        query <- sprintf(
          "INSERT INTO btc_prices VALUES 
          (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)",
          row['id'], 
          row['slug'], 
          row['name'], 
          row['symbol'], 
          row['timestamp'], 
          row['ref_cur_id'],
          row['ref_cur_name'], 
          row['time_open'], 
          row['time_close'], 
          row['time_high'], 
          row['time_low'], 
          row['open'], 
          row['high'], 
          row['low'], 
          row['close'], 
          row['volume'], 
          row['market_cap']
        )
        
        dbExecute(con, query)
        
      })
      
      dbDisconnect(con)
    })
  })
  
  output$btc_plot <- renderDygraph({
    req(btc_data()) 
    
    btc_price <- btc_data()
    btc_price$timestamp <- as.POSIXct(btc_price$timestamp, format = "%Y-%m-%d %H:%M:%S", tz = "UTC")
    
    
    btc_grouped <- group_data(btc_price, interval = input$interval)
    
  
    btc_xts_grouped <- xts(
      btc_grouped[, c("open", "high", "low", "close")],
      order.by = btc_grouped$timestamp
    )
    

    dygraph(btc_xts_grouped, main = "BTC Prices") %>%
      dyCandlestick() %>%    
      dyRangeSelector() %>%  
      dyAxis("x") %>%        
      dyAxis("y", logscale = input$logscale_toggle)
  })
  
  
  output$btc_volume_plot <- renderDygraph({
    req(btc_data()) 
    
    btc_price <- btc_data()
    btc_price$timestamp <- as.POSIXct(btc_price$timestamp, format = "%Y-%m-%d %H:%M:%S", tz = "UTC")
    
    if (input$chart_type == "market_cap") {
      
      btc_grouped <- group_data(btc_price, interval = input$interval)
      btc_volume_xts <- xts(btc_grouped$close, order.by = btc_grouped$timestamp)
      
      dygraph(btc_volume_xts, main = "Bitcoin Market Cap Over Time") %>%
        dyAxis("y") %>%
        dyRangeSelector(dateWindow = selected_range()) %>%
        dyOptions(
          colors = "blue",
          stepPlot = TRUE,      
          fillGraph = TRUE,     
          strokeWidth = 0       
        )
    } else if (input$chart_type == "moving_avg") {
      
      btc_grouped <- group_data(btc_price, interval = input$interval)
      btc_ohlc_xts <- xts(
        btc_price[, c("open", "high", "low", "close")],
        order.by = btc_price$timestamp
      )
      
      btc_xts_ma20 <- SMA(btc_ohlc_xts$close, n = 20)
      btc_xts_ma50 <- SMA(btc_ohlc_xts$close, n = 50)
      btc_xts_ma100 <- SMA(btc_ohlc_xts$close, n = 100)
      btc_xts_ma200 <- SMA(btc_ohlc_xts$close, n = 200)
      
      btc_combined_xts <- cbind(btc_ohlc_xts, btc_xts_ma20, btc_xts_ma50, btc_xts_ma100, btc_xts_ma200)
      colnames(btc_combined_xts) <- c("Open", "High", "Low", "Close", "MA20", "MA50", "MA100", "MA200")
      
      dygraph(btc_combined_xts, main = "Bitcoin Price and Moving Averages") %>%
        dyCandlestick() %>%
        dySeries("MA20", label = "20-Period MA", color = "blue") %>%
        dySeries("MA50", label = "50-Period MA", color = "green") %>%
        dySeries("MA100", label = "100-Period MA", color = "orange") %>%
        dySeries("MA200", label = "200-Period MA", color = "red") %>%
        dyAxis("y", label = "Price (USD)") %>%
        dyRangeSelector(dateWindow = selected_range())
    }
  })
  
  observeEvent(input$btc_plot_date_window, {
    selected_range(input$btc_plot_date_window)
  })
}

shinyApp(ui = ui, server = server)
