library(sf)
library(dplyr)
library(lubridate)

# Date/time and location
observation_date <- ymd_hms("1994-05-12 17:30:00", tz = "America/New_York")
latitude <- 40.7546
longitude <- -73.7077

# Julian date and sidereal time
jd <- as.numeric(observation_date - ymd_hms("2000-01-01 12:00:00", tz="UTC"))/86400 + 2451545
T <- (jd - 2451545)/36525
gst <- (280.46061837 + 360.98564736629*(jd - 2451545) + 0.000387933*T^2 - T^3/38710000) %% 360
lst <- (gst + longitude) %% 360

# Projection
queens_proj <- sprintf("+proj=laea +x_0=0 +y_0=0 +lon_0=%.6f +lat_0=%.6f", lst, latitude)

# Hemisphere polygon
hemisphere <- st_sfc(st_point(c(lst, latitude)), crs=4326) %>% 
  st_buffer(dist = 1e7) %>%
  st_transform(crs = queens_proj)  # transform after buffer

# Load constellations
const_file <- "https://raw.githubusercontent.com/ofrohn/d3-celestial/master/data/constellations.lines.json"
const_all <- st_read(const_file, stringsAsFactors = FALSE) %>%
  st_wrap_dateline(options=c("WRAPDATELINE=YES","DATELINEOFFSET=180")) %>% 
  st_transform(crs = queens_proj)  # transform after wrap_dateline

# Intersection
visible_constellations <- st_intersection(const_all, hemisphere)

# Optionally flip geometry after intersection
visible_constellations <- visible_constellations %>% mutate(geometry = geometry * matrix(c(-1,0,0,1),2,2))

# Extract visible constellation IDs
visible_ids <- visible_constellations$id
print(visible_ids)
