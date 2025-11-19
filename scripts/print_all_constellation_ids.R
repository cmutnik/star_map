library(dplyr)
library(sf)

# Read all constellations from the GeoJSON
const_all <- st_read("https://raw.githubusercontent.com/ofrohn/d3-celestial/master/data/constellations.lines.json")

# Check columns
colnames(const_all)
# Only 'id' and 'geometry' exist

# Create a table of all constellation IDs
constellation_table <- const_all %>%
  st_drop_geometry() %>%   # remove geometry
  distinct(id) %>%         # get unique IDs
  arrange(id)              # optional: sort alphabetically

# View the table
print(constellation_table)

# Optionally, write to CSV
write.csv(constellation_table, "all_constellations.csv", row.names = FALSE)
