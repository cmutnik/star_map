#%%
from datetime import datetime
from geopy import Nominatim
from tzwhere import tzwhere
from pytz import timezone, utc

import numpy as np
import matplotlib.pyplot as plt
from matplotlib.collections import LineCollection
from matplotlib.patches import Circle

from skyfield.api import Star, load, wgs84
from skyfield.data import hipparcos, mpc, stellarium
from skyfield.projections import build_stereographic_projection
from skyfield.constants import GM_SUN_Pitjeva_2005_km3_s2 as GM_SUN

import warnings
warnings.filterwarnings("ignore")


def load_data():
    # load celestial data
    # de421 shows position of earth and sun in space
    eph = load('de421.bsp')

    # hipparcos dataset contains star location data
    with load.open(hipparcos.URL) as f:
        stars = hipparcos.load_dataframe(f)

    # And the constellation outlines come from Stellarium.  We make a list
    # of the stars at which each edge stars, and the star at which each edge
    # ends.

    url = ('https://raw.githubusercontent.com/Stellarium/stellarium/master'
           '/skycultures/modern_st/constellationship.fab')

    with load.open(url) as f:
        constellations = stellarium.parse_constellations(f)
        
    return eph, stars, constellations

def load_data_cam(url_path="../data/cam.constellationship.fab"):
    # # load celestial data
    # # de421 shows position of earth and sun in space
    # eph = load('de421.bsp')

    # # hipparcos dataset contains star location data
    # with load.open(hipparcos.URL) as f:
    #     stars = hipparcos.load_dataframe(f)

    # # And the constellation outlines come from Stellarium.  We make a list
    # # of the stars at which each edge stars, and the star at which each edge
    # # ends.

    url = (url_path)

    with load.open(url) as f:
        constellations_cam = stellarium.parse_constellations(f)
        
    return constellations_cam


def collect_celestial_data(location, when):
    # get latitude and longitude of our location 
    locator = Nominatim(user_agent='myGeocoder')
    location = locator.geocode(location)
    lat, long = location.latitude, location.longitude
    
    # convert date string into datetime object
    dt = datetime.strptime(when, '%Y-%m-%d %H:%M')

    # define datetime and convert to utc based on our timezone
    timezone_str = tzwhere.tzwhere().tzNameAt(lat, long)
    local = timezone(timezone_str)

    # get UTC from local timezone and datetime
    local_dt = local.localize(dt, is_dst=None)
    utc_dt = local_dt.astimezone(utc)

    # load celestial data
    # eph, stars, constellations = load_data()

    # find location of earth and sun and set the observer position
    sun = eph['sun']
    earth = eph['earth']

    # define observation time from our UTC datetime
    ts = load.timescale()
    t = ts.from_datetime(utc_dt)

    # define an observer using the world geodetic system data
    observer = wgs84.latlon(latitude_degrees=lat, longitude_degrees=long).at(t)

    # define the position in the sky where we will be looking
    position = observer.from_altaz(alt_degrees=90, az_degrees=0)
    # center the observation point in the middle of the sky
    ra, dec, distance = observer.radec()
    center_object = Star(ra=ra, dec=dec)

    # find where our center object is relative to earth and build a projection with 180 degree view
    center = earth.at(t).observe(center_object)
    projection = build_stereographic_projection(center)
    field_of_view_degrees = 180.0

    # calculate star positions and project them onto a plain space
    star_positions = earth.at(t).observe(Star.from_dataframe(stars))
    stars['x'], stars['y'] = projection(star_positions)
    
    edges = [edge for name, edges in constellations for edge in edges]
    edges_star1 = [star1 for star1, star2 in edges]
    edges_star2 = [star2 for star1, star2 in edges]

    
    return stars, edges_star1, edges_star2

def create_star_chart(location, when, chart_size_dim0, chart_size_dim1, max_star_size, eph, stars, constellations, lines_xy_cam):
    stars, edges_star1, edges_star2 = collect_celestial_data(location, when)
    limiting_magnitude = 10
    bright_stars = (stars.magnitude <= limiting_magnitude)
    magnitude = stars['magnitude'][bright_stars]
    fig, ax = plt.subplots(figsize=(chart_size, chart_size))
    
    #use the night sky color code
    border = plt.Circle((0, 0), 1, color='#041A40', fill=True) 
    ax.add_patch(border)

    marker_size = max_star_size * 10 ** (magnitude / -2.5)

    ax.scatter(stars['x'][bright_stars], stars['y'][bright_stars],
               s=marker_size, color='white', marker='.', linewidths=0,
               zorder=2)
    # Draw the constellation lines.
    xy1 = stars[['x', 'y']].loc[edges_star1].values
    xy2 = stars[['x', 'y']].loc[edges_star2].values
    lines_xy = np.rollaxis(np.array([xy1, xy2]), 1)

    ax.add_collection(LineCollection(lines_xy, colors='#ffff', linewidths=0.15))

    # if lines_xy_cam != None:
    ax.add_collection(LineCollection(lines_xy_cam, colors='#ff0000', linewidths=0.15))

    horizon = Circle((0, 0), radius=1, transform=ax.transData)
    for col in ax.collections:
        col.set_clip_path(horizon)

    # other settings
    ax.set_xlim(-1, 1)
    ax.set_ylim(-1, 1)
    plt.axis('off')
    when_datetime = datetime.strptime(when, '%Y-%m-%d %H:%M')
    plt.title(f"Observation Location: {location}, Time: {when_datetime.strftime('%Y-%m-%d %H:%M')}", loc='right', fontsize=10)
   

    plt.savefig("../figs/pythonic_star_map.png")


if __name__ == '__main__':
    # load celestial data
    eph, stars, constellations = load_data()

    location = 'Virginia Beach, VA'
    when = '2021-05-17 00:00'
    chart_size=12
    max_star_size=500
    # create_star_chart(location, when, chart_size, chart_size, max_star_size, eph, stars, constellations, lines_xy_cam=lines_xy_cam)
    print(constellations)

# # %%
# # def colored_constellation_info():
# """ Colored constellations. """
# Cam_9 = [23040, 23522, 23522, 22783, 22783, 29997, 29997, 33694, 33694, 29997, 29997, 22783, 22783, 17959, 17959, 17884, 17884, 16228]
# cam_idx1_list, cam_idx2_list = [], []

# for hip_num in Cam_9:
#     if hip_num in edges_star1:
#         idx1 = np.where(np.array(edges_star1) == hip_num)[0][0]
#         print(f"hip_num: {hip_num} at edges_star1[{idx1}]")
#         cam_idx1_list.append(idx1)
#     if hip_num in edges_star2:
#         idx2 = np.where(np.array(edges_star2) == hip_num)[0][0]
#         print(f"hip_num: {hip_num} at edges_star2[{idx2}]")
#         cam_idx2_list.append(idx2)
    # %%
    stars, edges_star1, edges_star2 = collect_celestial_data(location, when)
    constellations_cam = load_data_cam(url_path="./constellationship_cam.fab")
    edges_cam = [edge for name, edges in constellations_cam for edge in edges]
    edges_star1_cam = [star1 for star1, star2 in edges_cam]
    edges_star2_cam = [star2 for star1, star2 in edges_cam]

    xy1_cam = stars[['x', 'y']].loc[edges_star1_cam].values
    xy2_cam = stars[['x', 'y']].loc[edges_star2_cam].values
    lines_xy_cam = np.rollaxis(np.array([xy1_cam, xy2_cam]), 1)
    # ax.add_collection(LineCollection(lines_xy_cam, colors='#ff0000', linewidths=0.15))
    # return lines_xy_cam

    # lines_xy_cam = colored_constellation_info()

    # %%
    create_star_chart(location, when, chart_size, chart_size, max_star_size, eph, stars, constellations, lines_xy_cam=lines_xy_cam)

