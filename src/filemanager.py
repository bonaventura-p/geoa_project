import gspread
from oauth2client.service_account import ServiceAccountCredentials
import pandas as pd
import twint
from crawlers import TweetSearcher, FollowerCounter, QueryRunner
# import inspect as i
# import sys
#
# sys.stdout.write(i.getsource(MyFunction))


def available_columns():
    return twint.output.panda.Tweets_df.columns

def GSheetClient(
        gref:str,
        creds_path:str,
        gmethod: str = 'key'
):
    '''add range selecctor and sheets !=1 option'''
    gclient = gspread.service_account(filename=creds_path)

    if gmethod == 'key':
        gsheet = gclient.open_by_key(gref)
    elif gmethod == 'url':
        gsheet = gclient.open_by_url(gref)
    elif gmethod == 'name':
        gsheet = gclient.open(gref)
    else:
        print("Please provide a valid gmethod entry. \
        Accepted values are ['key','url','name'] ")

    data = gsheet.worksheet('Db_influencers').get_all_records()

    return pd.DataFrame(data)

def UsersTweetFetcher(user_list:list,
                      buggy_list:list=[],
                      n_users:int=500,
                      store_csv=True
):
    df_tweets = pd.DataFrame()

    print('Retrieving user tweets.....')
    for i, user in enumerate(user_list):

        print(i, user)

        if  i < n_users:
            if (len(user) > 0) & (user not in buggy_list):

                user_df = TweetSearcher(user=user.strip("@"))

                df_tweets = df_tweets.append(user_df)
            else:
                pass
        else:
            break
    if store_csv:
        csv_name = 'data/tweets_'+str(datetime.date.today()).strip("-")+'.csv'

        print("Exporting to csv {}, with shape {}".format(csv_name, df_tweets.shape))

        df_tweets.to_csv(csv_name,index=False)
    else:
        return df_tweets