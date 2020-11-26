import os
print(os.getcwd())

from crawlers import TweetSearcher
from filemanager import GSheetClient

gsheet_dict = {
    'gref' : "1nL0xjCK2fZSRpqddJ35ZkyqW4gT1aN6PTqWit6k03bc",
'creds_path' : 'keys/geoa-1606313966220-f112d82d3a5d.json',
'gmethod' : 'key'
}

df = GSheetClient(
    gref= gsheet_dict['gref'],
    creds_path = gsheet_dict['creds_path'],
    gmethod=gsheet_dict['gmethod']
)

n_users = 500

for i, row in enumerate(df.tw_name):

    if i < n_users:
        if (len(row) > 0) & (row != "@oumou_kane"):
            print(i, row)
            output_name = 'data/'+ row.replace("@","")+'_tweets.csv'
            TweetSearcher(user=row.replace("@",""), output=output_name)

        else:
            pass
    else:
        break




#tweets from users in list
# tweets on topics (and then time/zone restriction)

#count tweets from users
#count topics from topics
