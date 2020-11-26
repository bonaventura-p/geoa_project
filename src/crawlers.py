import twint
import pandas as pd

#twint.run.Followers(c)
# c.Min_likes = 5
#twint.run.Lookup(c)
# c.Source = "Twitter Web Client"
# c.Members_list = "ph055a/osint"


def TweetSearcher(
        user:str,
        output:str,
        attrs: [] = []
):
    c = twint.Config()
    c.Username = user

    if len(attrs) == 0:
        attrs = ["id",
    "created_at",
    "user_id",
    "username",
    "tweet",
    "mentions",
    "urls",
    "replies_count",
    "retweets_count",
    "likes_count",
    "hashtags",
    "link",
    "near",
    "geo",
    "source"]
    c.Custom['tweet'] = attrs

    c.Output = output

    if output.endswith('csv'):
        c.Store_csv == True
    elif output.endswith('json'):
        c.Store_json == True
    else:
        c.Store_object == True

    c.Hide_output = True
    c.limit = 5
    return twint.run.Search(c)

