# BTC Price Dashboard

## Overview
The BTC Price Dashboard is a Shiny application for monitoring Bitcoin (BTC) price data. The app provides an interactive interface to visualize Bitcoin prices, market capitalization, and moving averages over various time intervals. Users can fetch and update BTC data from a MySQL database and explore it through dynamic charts.

## Features
- **Data Refresh and Update**: Retrieve the latest Bitcoin price data from a MySQL database.
![Description GIF 1](https://github.com/aaronMulveyAI/Stock2Flow/blob/main/images/c3.png)  
- **Interactive Charts**: View BTC prices as candlestick charts and analyze market cap or moving averages.
![Description GIF 1](https://github.com/aaronMulveyAI/Stock2Flow/blob/main/images/c2.png)
- **Customizable Time Intervals**: Group data by hourly, daily, weekly, or monthly intervals.
![Description GIF 1](https://github.com/aaronMulveyAI/Stock2Flow/blob/main/images/c1.png)
- **Logarithmic Scale**: Toggle log scale for charts.
  
- **User Notes**: Add custom notes within the app.

## Prerequisites
1. **Environment**:
   - R version 4.0.0 or higher.
   - MySQL server (configured with a database named `btc_database`).
2. **R Libraries**:
   Install the following R libraries using:
   ```R
   install.packages(c("shiny", "DBI", "RMySQL", "dplyr", "dygraphs", "xts", "TTR"))
   ```
3. **Database Configuration**:
   - The MySQL database should include a table named `btc_prices` with the following fields: `id`, `slug`, `name`, `symbol`, `timestamp`, `ref_cur_id`, `ref_cur_name`, `time_open`, `time_close`, `time_high`, `time_low`, `open`, `high`, `low`, `close`, `volume`, `market_cap`.

## Installation
1. Clone the repository or copy the application code.
2. Ensure MySQL database credentials in the server code match your environment:
   ```R
   con <- dbConnect(
     RMySQL::MySQL(),
     dbname = "btc_database",
     host = "localhost",
     port = 3306,
     user = "root",
     password = "your_password"
   )
   ```

## Running the App
1. Open RStudio or an R console.
2. Set the working directory to the folder containing the app code.
3. Run the following command:
   ```R
   shiny::runApp()
   ```

## App Usage
1. **Refresh BTC Prices**: Click the "Refresh BTC Prices" button to load the latest data from the database.
2. **Update BTC Prices**: Click "Update BTC Prices" to fetch new data and merge it with existing records.
3. **Select Time Interval**: Use the dropdown to group data by hour, day, week, or month.
4. **Chart Type**: Choose between market cap and moving averages for additional insights.
5. **Log Scale**: Toggle the checkbox to switch between linear and logarithmic scales.
6. **Add Notes**: Use the notes section for annotations or observations.

## Code Highlights
### `group_data()`
- Groups BTC data by a specified time interval.
- Aggregates `open`, `high`, `low`, and `close` values.

### Reactive Values
- `btc_data`: Stores Bitcoin price data.
- `selected_range`: Tracks the selected date range on the charts.

### Dynamic Outputs
- `btc_plot`: Displays candlestick charts for Bitcoin prices.
- `btc_volume_plot`: Visualizes market cap or moving averages.

## Security Considerations
- Replace placeholder credentials with secure values.
- Avoid hardcoding sensitive information in the application.

## Future Improvements
- Implement authentication for secure access.
- Add support for other cryptocurrencies.
- Include more advanced analytics like RSI or Bollinger Bands.

## License
This project is open-source and available under the MIT License.

## Acknowledgments
- [Shiny](https://shiny.rstudio.com/)
- [RMySQL](https://cran.r-project.org/web/packages/RMySQL/index.html)
- [dygraphs](https://rstudio.github.io/dygraphs/)

