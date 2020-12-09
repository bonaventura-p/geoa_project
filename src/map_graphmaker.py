import pandas as pd
import geopandas as gpd
import matplotlib.pyplot as plt
from filemanager import ChoroplethMaker


near_list = ['Niamey', 'Agadez', 'Maradi', 'Zinder', 'Diffa', 'Dosso', 'Tahoua',
             'Tillabéri']

file_path = '/Users/bonaventurapacileo/Documents/Freelance/GeoA/data/{}_geoqueries_{}.csv'

geo_df = pd.DataFrame()
ind = 'likes_count'

#append datasets from same city
for date in ['20201209','20201203']:
    print(date)
    for city in near_list:
        print(city)
        try:
            df = pd.read_table(file_path.format(city,date), sep=',') #all others are 1203

            if date == '20201203':

                df.rename(
                    columns=
                    {
                    'nreplies':"replies_count",  # nreplies
                    'nretweets':"retweets_count",  # nretweets
                    'nlikes':"likes_count"  # nlikes
                },
                    inplace=True)

            df.dropna(subset=['query'], inplace=True)

            mean = df.groupby('near')[ind].mean().reset_index()
            mean.rename(columns={ind: str(ind)+'_mean'}, inplace=True)
            df = df.merge(mean, on="near", how='left')
            if len(df) < 5:
                print("{} has less than five tweets".format(city))
                df[str(ind)+'_mean'] = 1

        except (pd.errors.EmptyDataError,FileNotFoundError) as e:
            print(e)
            df = pd.DataFrame(columns=geo_df.columns)
            df = df.append({'near':city}, ignore_index=True)
            df.fillna(1, inplace=True)

        geo_df = geo_df.append(df)

#drop duplicates
geo_df.drop_duplicates(inplace=True)

ChoroplethMaker(geo_df,'near',column=str(ind)+'_mean')



##{‘intersects’, ‘contains’, ‘within’}.

# #crs is epsg:4326
# app = Nominatim(user_agent='GeoA2')
# location2 = app.geocode("Niamey").raw #'Niamey, Niger'
#
# df['lat'] = location['lat']
# df['lon'] = location['lon']
# crs ='EPSG:4326'
#
#
# gdf = gpd.GeoDataFrame(
#      df, geometry=gpd.points_from_xy(df.lat, df.lon), crs=crs)

# #EPSG:4326
# niger = gpd.read_file('/Users/bonaventurapacileo/Documents/Freelance/GeoA/src/maps/shape_files_niger/adm01.shp')
# # niger_df = gpd.sjoin(niger,gdf,how='left',op='contains')


# {'place_id': 258620351,
#  'licence': 'Data © OpenStreetMap contributors, ODbL 1.0. https://osm.org/copyright',
#  'osm_type': 'relation',
#  'osm_id': 3218804,
#  'boundingbox': ['13.3829579', '13.6473395', '1.9609482', '2.264244'],
#  'lat': '13.524834',
#  'lon': '2.109823',
#  'display_name': 'Niamey, Niger',
#  'class': 'boundary',
#  'type': 'administrative',
#  'importance': 0.6616508055977213,
#  'icon': 'https://dulcy.openstreetmap.org/ui/mapicons//poi_boundary_administrative.p.20.png'}