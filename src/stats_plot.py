import seaborn as sns
import matplotlib.pyplot as plt
import pandas as pd
from filemanager import GSheetClient, BarDfMaker, BarPlotter

gsheet_dict = {
    'gref' : "1nL0xjCK2fZSRpqddJ35ZkyqW4gT1aN6PTqWit6k03bc",
'creds_path' : 'keys/geoa-1606313966220-f112d82d3a5d.json',
'gmethod' : 'key'
}

df_gsheet = GSheetClient(
    gref= gsheet_dict['gref'],
    creds_path = gsheet_dict['creds_path'],
    gmethod=gsheet_dict['gmethod']
)

df_gsheet['tw_name'] = [field.replace('@','') for field in df_gsheet['tw_name']]

print('Google Sheet converted to dataframe.....')


df_instrs= pd.DataFrame({'name':['user','tw_name'],
                         'posts':['numberOfPosts','tweets'],
                         'followers':['numberOfFollowers','tw_followers'],
                         'following':['numberOfFollowing','tw_following'],
                         'platform':['Instagram','Twitter'],
                         'file_path':[
                            '/Users/bonaventurapacileo/Documents/Freelance/GeoA/data/igstats_20201203.csv',
                             '/Users/bonaventurapacileo/Documents/Freelance/GeoA/data/follows_20201207.csv'
                         ],
                         'gs_name':['ig_name','tw_name']
                         })

for index, row in df_instrs.iterrows():

    df = BarDfMaker(row['file_path'], df_gsheet,row['name'],row['gs_name'])

    if row['platform'] == 'Twitter':
        post = 'Tweets'
        palette = 'Blues'
    else:
        post = 'Posts'
        palette = 'Reds'

    df.rename(
    columns={row['followers']: 'Followers', row['posts']: post, row['following']: 'Following'},
    inplace=True)

    melt_df = df.melt(id_vars=[row['name'], 'group'], var_name='metric', value_name='count')

    BarPlotter(melt_df, 'metric', 'count', 'group', row['platform']+"_barplot", palette)