import twint
import pandas as pd

#create functions for 1) followers+ their tweers and 2) keywords based search

def KeywordSearcher(keywords:list):

    c = twint.Config()

    c.Search = user
    c.Pandas = True
    c.Hide_output = True
    c.Limit = 3000  # 1 = 100
    twint.run.Search(c)

    df_pd = twint_to_pandas(attrs)

    return df_pd


def TweetSearcher(user:str):

    attrs = ["id",
             "created_at",
             'language',
             "user_id",
             "username",
             "tweet",
             "urls",
             "nreplies",
             "nretweets",
             "nlikes",
             "hashtags",
             "link",
             "near",
             "geo",
             "source"]

    c = twint.Config()

    c.Username = user
    c.Pandas = True
    c.Hide_output = True
    c.Limit = 3000 #min 100
    twint.run.Search(c)

    df_pd = twint_to_pandas(attrs)

    return df_pd


def twint_to_pandas(columns):
    return twint.output.panda.Tweets_df[columns]






####Old
#buggy users:
# 113 @IyoNoma
# buggy_list = [113]

# for i, row in enumerate(df.tw_name):
#
#     #make it from a certain number up
#     if  i < n_users:
#         if (len(row) > 0) & (i is not in buggy_list):
#             print(i, row)
#             output_name = 'data/'+ row.replace("@","")+'_tweets.csv'
#             TweetSearcher(user=row.replace("@",""), output=output_name)
#
#         else:
#             pass
#     else:
#         break
# def TweetSearcher_old(
#         user:str,
#         output:str
# ):
#
#     attrs = ["id",
#         "created_at",
#         "user_id",
#         "username",
#         "tweet",
#         "mentions",
#         "urls",
#         "replies_count",
#         "retweets_count",
#         "likes_count",
#         "hashtags",
#         "link",
#         "near",
#         "geo",
#         "source"]
#
#     c = twint.Config()
#     c.Username = user
#     c.Custom["tweet"] = attrs
#
#     c.Output = output
#
#     # if output.endswith('csv'):
#     #     c.Store_csv == True
#     # elif output.endswith('json'):
#     #     c.Store_json == True
#     # else:
#     #     c.Store_object == True
#
#     c.Store_csv == True
#     c.Hide_output = True
#     c.Limit = 2 #increments of 100 so limit=1 retrieves 100
#
#     return twint.run.Search(c)
#
#
#
#
