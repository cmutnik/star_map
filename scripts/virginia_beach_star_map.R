# Use R to generate star maps of a given location, on a given date
# https://kimnewzealand.github.io/2019/02/21/celestial-maps/
# https://stackoverflow.com/questions/75064069/creating-star-map-visualizations-based-on-location-and-date

library(sf)
library(tidyverse)


virginia_beach <- "+proj=laea +x_0=0 +y_0=0 +lon_0=36.8516 +lat_0=-75.9792"

########################################
flip <- matrix(c(-1, 0, 0, 1), 2, 2)
########################################
hemisphere <- st_sfc(st_point(c(36.8516, -75.9792)), crs = 4326) |>
              st_buffer(dist = 1e7) |>
              st_transform(crs = virginia_beach)
########################################
# # https://dieghernan.github.io/projects/celestial-data/
# url1 <- "https://raw.githubusercontent.com/dieghernan/celestial_data/main/data/mw.min.geojson"
# url1 <- "https://dieghernan.github.io/celestial_data/data/mw.min.geojson"
# url1 <- "https://cdn.jsdelivr.net/gh/dieghernan/celestial_data@main/data/mw.min.geojson"

# # https://stackoverflow.com/questions/75064069/creating-star-map-visualizations-based-on-location-and-date
url1 <- "https://raw.githubusercontent.com/ofrohn/d3-celestial/master/data/constellations.lines.json"
url2 <- "https://raw.githubusercontent.com/ofrohn/d3-celestial/master/data/stars.6.json"
########################################
constellation_lines_sf <- st_read(url1, stringsAsFactors = FALSE) %>%
  st_wrap_dateline(options = c("WRAPDATELINE=YES", "DATELINEOFFSET=180")) %>% 
  st_transform(crs = virginia_beach) %>%
  st_intersection(hemisphere) %>%
  filter(!is.na(st_is_valid(.))) %>%
  mutate(geometry = geometry * flip) 

st_crs(constellation_lines_sf) <- virginia_beach
########################################
stars_sf <- st_read(url2,stringsAsFactors = FALSE) %>% 
  st_transform(crs = virginia_beach) %>%
  st_intersection(hemisphere) %>%
  mutate(geometry = geometry * flip) 

st_crs(stars_sf) <- virginia_beach
########################################
library(grid)

mask <- polygonGrob(x = c(1, 1, 0, 0, 1, 1, 
                          0.5 + 0.46 * cos(seq(0, 2 *pi, len = 100))),
                    y =  c(0.5, 0, 0, 1, 1, 0.5, 
                           0.5 + 0.46 * sin(seq(0, 2*pi, len = 100))),
                    gp = gpar(fill = '#191d29', col = '#191d29'))
########################################
p <- ggplot() +
  geom_sf(data = stars_sf, aes(size = -exp(mag), alpha = -exp(mag)),
          color = "white")+
  geom_sf(data = constellation_lines_sf, linewidth = 1, color = "white",
          size = 2) +
  annotation_custom(circleGrob(r = 0.46, 
                               gp = gpar(col = "white", lwd = 10, fill = NA))) +
  scale_y_continuous(breaks = seq(0, 90, 15)) +
  scale_size_continuous(range = c(0, 2)) +
  annotation_custom(mask) +
  labs(caption = 'STRONG SAUCE\nVirginia Beach, VA, USA\n9th January 2023') +
  theme_void() +
  theme(legend.position = "none",
        panel.grid.major = element_line(color = "grey35", linewidth = 1),  
        panel.grid.minor = element_line(color = "grey20", linewidth = 1),  
        panel.border = element_blank(),  
        plot.background = element_rect(fill = "#191d29", color = "#191d29"),
        plot.margin = margin(20, 20, 20, 20),
        plot.caption = element_text(color = 'white', hjust = 0.5, 
                                    face = 2, size = 25, 
                                    margin = margin(150, 20, 20, 20)))
########################################
ggsave('./figs/virginia_beach.png', plot = p, width = unit(10, 'in'), 
       height = unit(15, 'in'))
