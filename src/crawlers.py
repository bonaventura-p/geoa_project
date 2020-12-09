import twint
import pandas as pd

#conda update -n base -c defaults conda


def TwitterLookup(
        user:str,
        ind:int
):

    c = twint.Config()
    c.Username = user
    c.Hide_output = True
    c.Store_object = True

    try:
        twint.run.Lookup(c)
        return (twint.output.users_list[ind].tweets,twint.output.users_list[ind].followers,twint.output.users_list[ind].following)
    except ValueError:
        return (0,0,0)


def QueryRunner(
        query:str,
        limit:int,
        date:str,
        near = False
):
    attrs = ["id",
             "created_at",
             'language',
             "user_id",
             "username",
             "tweet",
             "urls",
             "replies_count", #nreplies
             "retweets_count", #nretweets
             "likes_count", #nlikes
             "hashtags",
             "link",
             'reply_to', #and then screen_name
             "near",
             "geo",
             "source"]

    c = twint.Config()

    c.Search = query
    c.Pandas = True
    c.Hide_output = True
    c.Limit = limit  # 1 = 100
    c.Near = near
    c.Since = date #yyyy-mm-dd

    twint.run.Search(c)

    if twint.output.panda.Tweets_df.shape[0] == 0:
        print("No tweets retrieved for {}. Returning an empty dataframe".format(query))
        df_pd = pd.DataFrame()
    else:
        df_pd = twint_to_pandas(attrs)

    return df_pd


def TweetSearcher(
        user:str
):

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
             'reply_to',
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



