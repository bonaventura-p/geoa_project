#didierdrogba,  leomessi, lanadelrey, paulpogba, mb459, mileycyrus
from ig.insta_bot import InstagramBot
import json
import os
import sys
import requests
from filemanager import GSheetClient, UsersTweetFetcher
import pandas as pd
import datetime
import re

print("Working directory is {}".format(os.getcwd()))

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
print('Google Sheet converted to dataframe.....')


creds = json.load(open('keys/ig_credentials.json'))
path = '/Users/bonaventurapacileo/Documents/Freelance/GeoA/src/ig/'

bot = InstagramBot(email=creds['username'], password=creds['password'], path = path)

bot.signIn()

df_igstats = pd.DataFrame(columns=['user','numberOfPosts', 'numberOfFollowers', 'numberOfFollowing'])

buggy_list =['diraf.puma']
n_users = 500

for i,user in enumerate(df_gsheet.ig_name):
    print(user)
    if i < n_users:
        if (len(user) > 0 ) & (user not in buggy_list):
            df_igstats= df_igstats.append(bot.getUserStats(username=user), ignore_index=True)
        else:
            pass

bot.closeBrowser()

csv_name = 'data/igstats_' + str(datetime.date.today()).strip("-") + '.csv'

print("Exporting to csv {}, with shape {}".format(csv_name, df_igstats.shape))

df_igstats.to_csv(csv_name, index=False)

# ig_name