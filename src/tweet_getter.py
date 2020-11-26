import os
print(os.getcwd())

from crawlers import TweetSearcher
from filemanager import GSheetClient
import pandas as pd


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

n_users = 500
df_tweets = pd.DataFrame()
buggy_list = ['@IyoNoma']

for i, user in enumerate(df_gsheet.tw_name):

    print(i, user)

    if  i < n_users:
        if (len(user) > 0) & (user not in buggy_list):

            user_df = TweetSearcher(user=user.replace("@",""))

            df_tweets = df_tweets.append(user_df)
        else:
            pass
    else:
        break

print("length is {}".format(df_tweets.shape))
df_tweets.to_csv('data/df_tweets.csv',index=False)

#if too big write every single to csv and then append

#tweets from users in list
# tweets on topics (and then time/zone restriction)

#count tweets from users
#count topics from topics
# #manually treat mentions




