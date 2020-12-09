import os
import sys
import requests
from crawlers import TweetSearcher, TwitterLookup, QueryRunner
from filemanager import GSheetClient, UsersTweetFetcher
import pandas as pd
import datetime
import re

arg1 = sys.argv[1]

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

query_list = ['presidentielles', 'CSRD', 'parti Justice et Progrès', 'Génération Doubara', 'Salou Djibo',
              'Issoufou', 'PNDS', 'Parti Nigérien pour la Démocratie et le Socialisme', 'Tarayya', 'Bazoum',
              'Lumana', 'Mouvement démocratique nigérien pour une fédération africain', 'MODEN-FA', 'Amadou',
              'Nassara', 'Mouvement National pour la Société du Développement', 'MNSD', 'Oumarou', 'Tandja']

query_dict = {
    'limit': int(50000 / len(query_list)),
    'date': '2020-01-01'
}


if arg1 == 'u':
    # Task 1
    buggy_list = ['@IyoNoma']
    user_list = df_gsheet.tw_name
    n_users = 500
    UsersTweetFetcher(user_list=df_gsheet.tw_name,buggy_list=buggy_list,n_users=500,store_csv=True)


if arg1 == 'q':
    #bazoum from libya?



    buggy_list = ['Lumana']

    print('Retrieving tweets based on query.....')

    df_queries = pd.DataFrame()

    for q in query_list:

        print(q)
        if q not in buggy_list:

            query_df = QueryRunner(
                query = q,
                limit = query_dict['limit'],
                date = query_dict['date']
            )
            if len(query_df) > 0:
                query_df.loc[:,'query'] = q

            print("Retrieved {}/{} tweets".format(len(query_df),query_dict['limit']))

            df_queries = df_queries.append(query_df)
        else:
            pass


    csv_name = 'data/queries_'+str(datetime.date.today()).replace("-","")+'.csv'

    print("Exporting to csv {}, with shape {}".format(csv_name, df_queries.shape))

    df_queries.to_csv(csv_name,index=False)



if arg1 == 'f':

    n_users = 500

    df_follow = pd.DataFrame(columns=['tw_name','tweets', 'tw_followers','tw_following'])
    buggy_list = []
    n=0

    print('Retrieving user followers.....')
    for i, user in enumerate(df_gsheet.tw_name):

        print(i, user)

        if i < n_users:
            if (len(user) > 0) & (user not in buggy_list):
                #strip fine because @ is at the beginning
                tweets,followers,following = TwitterLookup(user=user.strip("@"),ind=n)

                df_follow = df_follow.append({'tw_name':user.strip("@"),'tweets':tweets,'tw_followers': followers, 'tw_following':following}, ignore_index= True)
                if (tweets > 0)|(followers > 0)|(following > 0):
                    n += 1
            else:
                pass
        else:
            break

    csv_name = 'data/follows_' + str(datetime.date.today()).replace("-","") + '.csv'

    print("Exporting to csv {}, with shape {}".format(csv_name, df_follow.shape))

    df_follow.to_csv(csv_name, index=False)


if arg1 == 'm':

    custom_query = ""
    mentioned = {}
    replied = {}
    mentions = []
    replies = []
    query_list = []

    for user in df_gsheet.tw_name:
        mentions.append(user.strip("@"))
        replies.append(user.strip("@"))

    query_list.extend(mentions)
    query_list.extend(replies)

    # now replies are the same as mentions so we take a set
    query_list = set(query_list)

    query_dict = {
        'limit' : int(500000/len(query_list)),
        'date' : '2020-01-01'
    }

    buggy_list = ['ABDialloCheikh']

    print('Retrieving tweets based on query.....')

    df_mentions = pd.DataFrame()

    for q in query_list:

        print(q)
        if (len(q)>0) & (q not in buggy_list):

            query_df = QueryRunner(
                query = q,
                limit = query_dict['limit'],
                date = query_dict['date']
            )
            if len(query_df) > 0:
                query_df.loc[:,'query'] = q

            print("Retrieved {}/{} tweets".format(len(query_df),query_dict['limit']))

            df_mentions = df_mentions.append(query_df)
        else:
            pass

    print('Calculating replies and mentions...')
    for i,t in df_mentions.iterrows():

        reply_list = []
        for r in t.reply_to:
            #print('Reply to is {}'.format(r['screen_name']))
            reply_list.append(r['screen_name'])
            try:
                replied[r['screen_name']]['count'] +=1
            except KeyError:
                replied.update({r['screen_name']:{'by':t.username,'count':1}})

        mentions = re.findall("@\w+",t.tweet)
        mentions = [m.strip('@') for m in mentions]

        for m in mentions:
            #print('Mentions is {}'.format(m))
            if m not in reply_list:
                try:
                    mentioned[m]['count'] += 1
                except KeyError:
                    mentioned.update({m:{'by': t.username, 'count': 1}})
            else:
                #print("Mention {} was a reply_to".format(m))
                pass

        #print('.', end='', flush=True)

    print('Writing  output file...')
    actions = {'mentioned': mentioned, 'replied_to': replied}
    mention_reply_df = pd.DataFrame(columns=['author','action','target','count'])
    for a in actions:
        action = actions[a]
        for user in action:
            #by is the author of the tweet, user is the repliedto/mentioned, count is the number of times across tweets
            mention_reply_df = mention_reply_df.append(
                {'author':action[user]['by'], 'action':a, 'target':user, 'count':action[user]['count']},
                ignore_index=True)

    csv_name = 'data/mention_reply_' + str(datetime.date.today()).replace("-","") + '.csv'
    mention_reply_df.to_csv(csv_name, index=False)
    print("Saved {} with length of {}".format(csv_name,len(mention_reply_df)))


if arg1 == 'geo':

    # near_list = ['Niger','Niamey','Agadez','Maradi', 'Zinder']
    near_list = ['Niger','Niamey', 'Agadez', 'Maradi', 'Zinder', 'Diffa', 'Dosso', 'Tahoua',
       'Tillabéri']


    buggy_list = ['Lumana']

    print('Retrieving tweets based on query with geo info.....')
    for near in near_list:

        print(near)

        df_queries = pd.DataFrame()

        for q in query_list:

            print(q)
            if q not in buggy_list:

                query_df = QueryRunner(
                    query = q,
                    limit = query_dict['limit'],
                    date = query_dict['date'],
                    near = near
                )
                if len(query_df) > 0:
                    query_df.loc[:,'query'] = q

                print("Retrieved {}/{} tweets".format(len(query_df),query_dict['limit']))

                df_queries = df_queries.append(query_df)
            else:
                pass


        csv_name = 'data/{}_geoqueries_'.format(near) + str(datetime.date.today()).replace("-","")+'.csv'

        print("Exporting to csv {}, with shape {}".format(csv_name, df_queries.shape))

        df_queries.to_csv(csv_name,index=False)




#how to write to gsheet


# tweets on topics (and then time/zone restriction)

#count tweets from users
#count topics from tweets




