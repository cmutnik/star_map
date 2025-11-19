library(dplyr)
library(sf)

# Read all constellations
const_all <- st_read("https://raw.githubusercontent.com/ofrohn/d3-celestial/master/data/constellations.lines.json")

# List of zodiac constellation IDs
zodiac_ids <- c("Ari", "Tau", "Gem", "Cnc", "Leo", "Vir",
                "Lib", "Sco", "Sgr", "Cap", "Aqr", "Psc")

# Filter only zodiac constellations
zodiac_constellations <- const_all %>%
  filter(id %in% zodiac_ids) %>%
  select(id) %>%   # only 'id' exists in this JSON
  st_as_sf()

# Optional: create a lookup table for full names
zodiac_names <- tibble(
  id = zodiac_ids,
  full_name = c("Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo",
                "Libra", "Scorpius", "Sagittarius", "Capricornus", "Aquarius", "Pisces")
)

# Join to add full names
zodiac_constellations <- zodiac_constellations %>%
  left_join(zodiac_names, by = "id")

# View the table
print(zodiac_constellations)
