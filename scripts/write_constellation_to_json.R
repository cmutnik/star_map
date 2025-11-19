# Load libraries
library(sf)
library(tidyverse)
library(lubridate)
library(jsonlite)

# Date and time specification
observation_date <- ymd_hms("1994-05-12 17:30:00", tz = "America/New_York")

# lat/long for Long Island Jewish Hospital, New York City, Queens: 40.7546,-73.7077
latitude <- 40.7546
longitude <- -73.7077

# Calculate Local Sidereal Time (LST) to rotate the star field appropriately
# This accounts for Earth's rotation and shows the correct stars for the given time

# Julian Date calculation
jd <- as.numeric(observation_date - ymd_hms("2000-01-01 12:00:00", tz = "UTC")) / 86400 + 2451545.0

# Read the full constellation lines
const_all <- st_read("https://raw.githubusercontent.com/ofrohn/d3-celestial/master/data/constellations.lines.json")

# Filter for Taurus (IAU abbreviation "Tau")
constellation_lines_sf_tau <- const_all %>% filter(id == "Tau")

# Write constellations json out to a local file
st_write(constellation_lines_sf_tau, "tau.constellations.lines.json", driver = "GeoJSON")
