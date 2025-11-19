# Use R to generate star maps of a given location, on a given date and time
# https://kimnewzealand.github.io/2019/02/21/celestial-maps/
# https://stackoverflow.com/questions/75064069/creating-star-map-visualizations-based-on-location-and-date

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

# Calculate Greenwich Sidereal Time (GST)
T <- (jd - 2451545.0) / 36525
gst <- 280.46061837 + 360.98564736629 * (jd - 2451545.0) + 
       0.000387933 * T^2 - T^3 / 38710000

# Calculate Local Sidereal Time
lst <- (gst + longitude) %% 360

# Hour angle offset in degrees (this rotates the projection)
ha_offset <- lst

# Create a custom projection centered on the location with time-based rotation
# The lon_0 parameter now includes the LST adjustment
queens_new_york <- sprintf("+proj=laea +x_0=0 +y_0=0 +lon_0=%.6f +lat_0=%.6f", 
                          ha_offset, latitude)

########################################
flip <- matrix(c(-1, 0, 0, 1), 2, 2)
########################################
hemisphere <- st_sfc(st_point(c(ha_offset, latitude)), crs = 4326) |>
              st_buffer(dist = 1e7) |>
              st_transform(crs = queens_new_york)
########################################
# Download data files first using R's download.file
temp_dir <- tempdir()
const_file <- file.path(temp_dir, "constellations.lines.json")
stars_file <- file.path(temp_dir, "stars.6.json")

# Try jsDelivr CDN as alternative
url1 <- "https://cdn.jsdelivr.net/gh/ofrohn/d3-celestial@master/data/constellations.lines.json"
url2 <- "https://cdn.jsdelivr.net/gh/ofrohn/d3-celestial@master/data/stars.6.json"

cat("Downloading constellation data...\n")
download.file(url1, const_file, mode = "wb", quiet = FALSE)
cat("Downloading star data...\n")
download.file(url2, stars_file, mode = "wb", quiet = FALSE)

########################################
# Determine which star to color in
url4 <- "https://raw.githubusercontent.com/cmutnik/star_map/main/data/neutron_star_PSR_J0740p6620_messier_format.json"
stars_sf_ns_j0740 <- st_read(url4,stringsAsFactors = FALSE) %>% 
  st_transform(crs = queens_new_york) %>%
  st_intersection(hemisphere) %>%
  mutate(geometry = geometry * flip) 
st_crs(stars_sf_ns_j0740) <- queens_new_york

# ################################################################################
# # Determine which constellation to color in
# # NOTE: Someone born at this time would be a Taurus,
# #         this means Taurus would be near the sun and 
# #         not visible in the night sky. The constellations
# #         overhead would be Leo/Virgo. So astronomically, 
# #         they were “born under” the portion of the sky near 
# #         Leo / Virgo — NOT Taurus
# # Using: https://raw.githubusercontent.com/ofrohn/d3-celestial/master/data/constellations.lines.json
# #         here are the json keys for the zodiac signs
# | Zodiac Sign | IAU Abbreviation (JSON `id`) |
# | ----------- | ---------------------------- |
# | Aries       | `Ari`                        |
# | Taurus      | `Tau`                        |
# | Gemini      | `Gem`                        |
# | Cancer      | `Cnc`                        |
# | Leo         | `Leo`                        |
# | Virgo       | `Vir`                        |
# | Libra       | `Lib`                        |
# | Scorpio     | `Sco`                        |
# | Sagittarius | `Sgr`                        |
# | Capricorn   | `Cap`                        |
# | Aquarius    | `Aqr`                        |
# | Pisces      | `Psc`                        |
# ################################################################################

# ########################################
# # # Option 1: Determine which constellation to color in
# url3 <- "https://raw.githubusercontent.com/cmutnik/star_map/main/data/cam.constellations.lines.json"
# constellation_lines_sf_tau <- st_read(url3, stringsAsFactors = FALSE) %>%
#   st_wrap_dateline(options = c("WRAPDATELINE=YES", "DATELINEOFFSET=90")) %>% 
#   st_transform(crs = queens_new_york) %>%
#   st_intersection(hemisphere) %>%
#   filter(!is.na(st_is_valid(.))) %>%
#   mutate(geometry = geometry * flip) 
# st_crs(constellation_lines_sf_tau) <- queens_new_york
# ########################################


# # ########################################
# # # Option 2: Determine which constellation to color in
# library(sf)

# # Read the full constellation lines
# const_all <- st_read("https://raw.githubusercontent.com/ofrohn/d3-celestial/master/data/constellations.lines.json")

# # Filter for Taurus (IAU abbreviation "Tau")
# constellation_lines_sf_tau <- const_all %>% filter(id == "Tau")

# # ####################
# # # Optionally: write constellations json out to a local file
# # st_write(constellation_lines_sf_tau, "tau.constellations.lines.json", driver = "GeoJSON")
# # ########################################

########################################
# # Option 3: Determine which constellation to color in
# # Choose to color in LEO not TAURUS due to note above
# # Leo layer (colored in green, cuz taurus was near sun at this time)
const_all <- st_read("https://raw.githubusercontent.com/ofrohn/d3-celestial/master/data/constellations.lines.json")
constellation_lines_sf_leo <- const_all %>%
  filter(id == "Leo") %>%
  st_wrap_dateline(options = c("WRAPDATELINE=YES", "DATELINEOFFSET=180")) %>%
  st_transform(crs = queens_new_york) %>%
  st_intersection(hemisphere) %>%
  mutate(geometry = geometry * flip)
st_crs(constellation_lines_sf_leo) <- queens_new_york

# # Choose to color in VIRGO not TAURUS due to note above
const_all <- st_read("https://raw.githubusercontent.com/ofrohn/d3-celestial/master/data/constellations.lines.json")
constellation_lines_sf_vir <- const_all %>%
  filter(id == "Vir") %>%
  st_wrap_dateline(options = c("WRAPDATELINE=YES", "DATELINEOFFSET=180")) %>%
  st_transform(crs = queens_new_york) %>%
  st_intersection(hemisphere) %>%
  mutate(geometry = geometry * flip)
st_crs(constellation_lines_sf_vir) <- queens_new_york

# # Choose to color in LIBRA not TAURUS due to note above
const_all <- st_read("https://raw.githubusercontent.com/ofrohn/d3-celestial/master/data/constellations.lines.json")
constellation_lines_sf_lib <- const_all %>%
  filter(id == "Lib") %>%
  st_wrap_dateline(options = c("WRAPDATELINE=YES", "DATELINEOFFSET=180")) %>%
  st_transform(crs = queens_new_york) %>%
  st_intersection(hemisphere) %>%
  mutate(geometry = geometry * flip)
st_crs(constellation_lines_sf_lib) <- queens_new_york

# # Choose to color in Scorpio not TAURUS due to note above
const_all <- st_read("https://raw.githubusercontent.com/ofrohn/d3-celestial/master/data/constellations.lines.json")
constellation_lines_sf_sco <- const_all %>%
  filter(id == "Sco") %>%
  st_wrap_dateline(options = c("WRAPDATELINE=YES", "DATELINEOFFSET=180")) %>%
  st_transform(crs = queens_new_york) %>%
  st_intersection(hemisphere) %>%
  mutate(geometry = geometry * flip)
st_crs(constellation_lines_sf_sco) <- queens_new_york

# # Choose to color in Gemini not TAURUS due to note above
const_all <- st_read("https://raw.githubusercontent.com/ofrohn/d3-celestial/master/data/constellations.lines.json")
constellation_lines_sf_gem <- const_all %>%
  filter(id == "Gem") %>%
  st_wrap_dateline(options = c("WRAPDATELINE=YES", "DATELINEOFFSET=180")) %>%
  st_transform(crs = queens_new_york) %>%
  st_intersection(hemisphere) %>%
  mutate(geometry = geometry * flip)
st_crs(constellation_lines_sf_gem) <- queens_new_york

# # Choose to color in CANCER not TAURUS due to note above
const_all <- st_read("https://raw.githubusercontent.com/ofrohn/d3-celestial/master/data/constellations.lines.json")
constellation_lines_sf_cnc <- const_all %>%
  filter(id == "Cnc") %>%
  st_wrap_dateline(options = c("WRAPDATELINE=YES", "DATELINEOFFSET=180")) %>%
  st_transform(crs = queens_new_york) %>%
  st_intersection(hemisphere) %>%
  mutate(geometry = geometry * flip)
st_crs(constellation_lines_sf_cnc) <- queens_new_york

#################################################
# # Will not be visible on this map
#################################################
# # Aries (will not be shown on this map)
const_all <- st_read("https://raw.githubusercontent.com/ofrohn/d3-celestial/master/data/constellations.lines.json")
constellation_lines_sf_ari <- const_all %>%
  filter(id == "Ari") %>%
  st_wrap_dateline(options = c("WRAPDATELINE=YES", "DATELINEOFFSET=180")) %>%
  st_transform(crs = queens_new_york) %>%
  st_intersection(hemisphere) %>%
  mutate(geometry = geometry * flip)
st_crs(constellation_lines_sf_ari) <- queens_new_york

# # Taurus (will not be shown on this map)
const_all <- st_read("https://raw.githubusercontent.com/ofrohn/d3-celestial/master/data/constellations.lines.json")
constellation_lines_sf_tau <- const_all %>%
  filter(id == "Tau") %>%
  st_wrap_dateline(options = c("WRAPDATELINE=YES", "DATELINEOFFSET=180")) %>%
  st_transform(crs = queens_new_york) %>%
  st_intersection(hemisphere) %>%
  mutate(geometry = geometry * flip)
st_crs(constellation_lines_sf_tau) <- queens_new_york

# # Sagittarius (will not be shown on this map)
const_all <- st_read("https://raw.githubusercontent.com/ofrohn/d3-celestial/master/data/constellations.lines.json")
constellation_lines_sf_sgr <- const_all %>%
  filter(id == "Sgr") %>%
  st_wrap_dateline(options = c("WRAPDATELINE=YES", "DATELINEOFFSET=180")) %>%
  st_transform(crs = queens_new_york) %>%
  st_intersection(hemisphere) %>%
  mutate(geometry = geometry * flip)
st_crs(constellation_lines_sf_sgr) <- queens_new_york

# # Capricorn (will not be shown on this map)
const_all <- st_read("https://raw.githubusercontent.com/ofrohn/d3-celestial/master/data/constellations.lines.json")
constellation_lines_sf_cap <- const_all %>%
  filter(id == "Cap") %>%
  st_wrap_dateline(options = c("WRAPDATELINE=YES", "DATELINEOFFSET=180")) %>%
  st_transform(crs = queens_new_york) %>%
  st_intersection(hemisphere) %>%
  mutate(geometry = geometry * flip)
st_crs(constellation_lines_sf_cap) <- queens_new_york

# # Aquarius (will not be shown on this map)
const_all <- st_read("https://raw.githubusercontent.com/ofrohn/d3-celestial/master/data/constellations.lines.json")
constellation_lines_sf_aqr <- const_all %>%
  filter(id == "Aqr") %>%
  st_wrap_dateline(options = c("WRAPDATELINE=YES", "DATELINEOFFSET=180")) %>%
  st_transform(crs = queens_new_york) %>%
  st_intersection(hemisphere) %>%
  mutate(geometry = geometry * flip)
st_crs(constellation_lines_sf_aqr) <- queens_new_york

# # Pisces (will not be shown on this map)
const_all <- st_read("https://raw.githubusercontent.com/ofrohn/d3-celestial/master/data/constellations.lines.json")
constellation_lines_sf_psc <- const_all %>%
  filter(id == "Psc") %>%
  st_wrap_dateline(options = c("WRAPDATELINE=YES", "DATELINEOFFSET=180")) %>%
  st_transform(crs = queens_new_york) %>%
  st_intersection(hemisphere) %>%
  mutate(geometry = geometry * flip)
st_crs(constellation_lines_sf_psc) <- queens_new_york

#################################################
#################################################


########################################
constellation_lines_sf <- st_read(const_file, stringsAsFactors = FALSE) %>%
  st_wrap_dateline(options = c("WRAPDATELINE=YES", "DATELINEOFFSET=180")) %>% 
  st_transform(crs = queens_new_york) %>%
  st_intersection(hemisphere) %>%
  filter(!is.na(st_is_valid(.))) %>%
  mutate(geometry = geometry * flip) 

st_crs(constellation_lines_sf) <- queens_new_york
########################################
stars_sf <- st_read(stars_file,stringsAsFactors = FALSE) %>% 
  st_transform(crs = queens_new_york) %>%
  st_intersection(hemisphere) %>%
  mutate(geometry = geometry * flip) 

st_crs(stars_sf) <- queens_new_york
########################################
library(grid)

mask <- polygonGrob(x = c(1, 1, 0, 0, 1, 1, 
                          0.5 + 0.46 * cos(seq(0, 2 *pi, len = 100))),
                    y =  c(0.5, 0, 0, 1, 1, 0.5, 
                           0.5 + 0.46 * sin(seq(0, 2*pi, len = 100))),
                    gp = gpar(fill = '#0E1423', col = '#0E1423'))
########################################
p <- ggplot() +
  geom_sf(data = stars_sf, aes(size = -exp(mag), alpha = -exp(mag)), color = "white") +
  geom_sf(data = constellation_lines_sf, linewidth = 1, color = "white", size = 2) +
  geom_sf(data = stars_sf_ns_j0740, aes(size = 20, alpha = 1), color = "#ff0000") + 
  geom_sf(data = constellation_lines_sf_sco, linewidth = 1, color = "#1eff00", size = 3) +
  geom_sf(data = constellation_lines_sf_lib, linewidth = 1, color = "#1eff00", size = 3) +
  geom_sf(data = constellation_lines_sf_vir, linewidth = 1, color = "#1eff00", size = 3) +
  geom_sf(data = constellation_lines_sf_leo, linewidth = 1, color = "#1eff00", size = 3) +
  geom_sf(data = constellation_lines_sf_cnc, linewidth = 1, color = "#1eff00", size = 3) +
  geom_sf(data = constellation_lines_sf_gem, linewidth = 1, color = "#1eff00", size = 3) +
  # Not going to be visible on this map
  geom_sf(data = constellation_lines_sf_ari, linewidth = 1, color = "#1eff00", size = 3) +
  geom_sf(data = constellation_lines_sf_sgr, linewidth = 1, color = "#1eff00", size = 3) +
  geom_sf(data = constellation_lines_sf_cap, linewidth = 1, color = "#1eff00", size = 3) +
  geom_sf(data = constellation_lines_sf_aqr, linewidth = 1, color = "#1eff00", size = 3) +
  geom_sf(data = constellation_lines_sf_psc, linewidth = 1, color = "#1eff00", size = 3) +
  geom_sf(data = constellation_lines_sf_tau, linewidth = 1, color = "#1eff00", size = 3) +
  annotation_custom(circleGrob(r = 0.46, gp = gpar(col = "white", lwd = 10, fill = NA))) +
  scale_y_continuous(breaks = seq(0, 90, 15)) +
  scale_size_continuous(range = c(0, 2)) +
  annotation_custom(mask) +
  labs(caption = 'DANIELLE PANARIELLO\nPSR J0740+6620\n12th May 1994\nQueens, NY') + #  at 5:30 PM
  theme_void() +
  theme(legend.position = "none",
        panel.grid.major = element_line(color = "grey35", linewidth = 1),  
        panel.grid.minor = element_line(color = "grey20", linewidth = 1),  
        panel.border = element_blank(),  
        plot.background = element_rect(fill = "#0E1423", color = "#0E1423"),
        plot.margin = margin(20, 20, 20, 20),
        plot.caption = element_text(color = 'white', hjust = 0.5, 
                                    face = 2, size = 25, 
                                    margin = margin(150, 20, 20, 20)))
########################################
ggsave('./figs/queens_new_york_time_with_star_and_zodiac_constellation.pdf', plot = p, width = unit(10, 'in'), 
       height = unit(15, 'in'))
