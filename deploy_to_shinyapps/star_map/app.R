library(shiny)
library(sf)
library(tidyverse)
library(lubridate)
library(jsonlite)
library(grid)

# Helper to create ordinal suffix for day
ordinal <- function(x) {
  if (x %% 100 %in% 11:13) {
    paste0(x, "th")
  } else {
    suffix <- c("th", "st", "nd", "rd", rep("th", 6))
    paste0(x, suffix[(x %% 10) + 1])
  }
}

ui <- fluidPage(
  titlePanel("Star Map Generator"),

  sidebarLayout(
    sidebarPanel(
      textInput("username", "Your Name:", value = "John Doe"),

      textInput("location_text", "City, State, Country:",
                value = "Dallas, Texas, USA"),

      numericInput("lat", "Latitude:", value = 32.7767),
      numericInput("lon", "Longitude:", value = -96.7970),

      textInput(
        "obs_date_local",
        "Local Observation Date & Time (YYYY-MM-DD HH:MM:SS):",
        value = "2021-01-23 00:00:00"
      ),

      selectInput(
        "tz",
        "Local Time Zone:",
        choices = OlsonNames(),
        selected = Sys.timezone()
      ),

      hr(),

      actionButton("go", "Generate Star Map", class = "btn-primary"),
      hr(),
      downloadButton("download_map", "Download PNG")
    ),

    mainPanel(
      plotOutput("starmap", height = "900px"),
      textOutput("utc_display")
    )
  )
)

server <- function(input, output, session) {

  generate_star_map <- eventReactive(input$go, {

    # -------------------------------------------------
    # Convert local time to UTC automatically for calculations
    # -------------------------------------------------
    req(input$obs_date_local, input$tz)
    local_dt <- ymd_hms(input$obs_date_local, tz = input$tz)
    observation_date_utc <- with_tz(local_dt, "UTC")  # use for star chart calculations

    # Display UTC for the user
    output$utc_display <- renderText({
      paste("UTC Time used for star chart calculations:", 
            format(observation_date_utc, "%Y-%m-%d %H:%M:%S"))
    })

    latitude <- input$lat
    longitude <- input$lon

    # -------------------------------------------------
    # SIDEREAL TIME CALCULATION
    # -------------------------------------------------
    jd <- as.numeric(observation_date_utc - ymd_hms("2000-01-01 12:00:00",
                                                tz = "UTC")) / 86400 + 2451545.0

    T <- (jd - 2451545.0) / 36525
    gst <- 280.46061837 + 360.98564736629 * (jd - 2451545.0) +
      0.000387933 * T^2 - T^3 / 38710000

    lst <- (gst + longitude) %% 360
    ha_offset <- lst

    # -------------------------------------------------
    # PROJECTION
    # -------------------------------------------------
    custom_proj <- sprintf(
      "+proj=laea +x_0=0 +y_0=0 +lon_0=%.6f +lat_0=%.6f",
      ha_offset, latitude
    )

    flip <- matrix(c(-1, 0, 0, 1), 2, 2)

    hemisphere <- st_sfc(st_point(c(ha_offset, latitude)), crs = 4326) |>
      st_buffer(dist = 1e7) |>
      st_transform(crs = custom_proj)

    # -------------------------------------------------
    # DOWNLOAD STAR DATA (TEMP DIR)
    # -------------------------------------------------
    temp_dir <- tempdir()
    const_file <- file.path(temp_dir, "constellations.json")
    stars_file <- file.path(temp_dir, "stars.json")

    url1 <- "https://cdn.jsdelivr.net/gh/ofrohn/d3-celestial@master/data/constellations.lines.json"
    url2 <- "https://cdn.jsdelivr.net/gh/ofrohn/d3-celestial@master/data/stars.6.json"

    download.file(url1, const_file, mode = "wb", quiet = TRUE)
    download.file(url2, stars_file, mode = "wb", quiet = TRUE)

    constellation_lines_sf <- st_read(const_file, quiet = TRUE) %>%
      st_wrap_dateline(options = c("WRAPDATELINE=YES", "DATELINEOFFSET=180")) %>%
      st_transform(crs = custom_proj) %>%
      st_intersection(hemisphere) %>%
      mutate(geometry = geometry * flip)

    st_crs(constellation_lines_sf) <- custom_proj

    stars_sf <- st_read(stars_file, quiet = TRUE) %>%
      st_transform(crs = custom_proj) %>%
      st_intersection(hemisphere) %>%
      mutate(geometry = geometry * flip)

    st_crs(stars_sf) <- custom_proj

    # -------------------------------------------------
    # VISUAL MASK
    # -------------------------------------------------
    mask <- polygonGrob(
      x = c(1,1,0,0,1,1,0.5 + 0.46 * cos(seq(0, 2 *pi, len = 100))),
      y = c(0.5,0,0,1,1,0.5,0.5 + 0.46 * sin(seq(0, 2*pi, len = 100))),
      gp = gpar(fill = '#0E1423', col = '#0E1423')
    )

    # -------------------------------------------------
    # CAPTION USES LOCAL TIME (DATE ONLY IN WORDS)
    # -------------------------------------------------
    day_ord <- ordinal(day(local_dt))
    month_name <- month(local_dt, label = TRUE, abbr = FALSE)
    year_num <- year(local_dt)

    date_text <- paste(day_ord, month_name, year_num)

    caption_text <- sprintf("%s\n%s\n%s",
                            input$username,
                            date_text,
                            input$location_text)

    p <- ggplot() +
      geom_sf(data = stars_sf,
              aes(size = -exp(mag), alpha = -exp(mag)),
              color = "white") +
      geom_sf(data = constellation_lines_sf,
              linewidth = 1, color = "white", size = 2) +
      annotation_custom(circleGrob(r = 0.46,
                                   gp = gpar(col = "white",
                                             lwd = 10, fill = NA))) +
      scale_size_continuous(range = c(0,2)) +
      annotation_custom(mask) +
      labs(caption = caption_text) +
      theme_void() +
      theme(
        legend.position = "none",
        plot.background = element_rect(fill = "#0E1423", color = "#0E1423"),
        plot.caption = element_text(color = "white",
                                    hjust = 0.5,
                                    face = 2,
                                    size = 20,
                                    margin = margin(150,20,20,20))
      )

    p
  })

  output$starmap <- renderPlot({
    generate_star_map()
  })

  output$download_map <- downloadHandler(
    filename = function() {
      paste0("star_map_", Sys.Date(), ".png")
    },
    content = function(file) {
      ggsave(file,
             plot = generate_star_map(),
             width = 10, height = 15, units = "in")
    }
  )
}

shinyApp(ui, server)
