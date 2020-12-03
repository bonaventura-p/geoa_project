



if arg1 == 'm':

    custom_query = ""
    mentioned = {}
    replied = {}
    mentions = []
    replies = []
    for user in df_gsheet.tw_name:
        mentions.append(user)
        replies.append(user)

    for m in mentions:
        mentioned.update({m: {}})
        custom_query += "@{} OR ".format(m)
    custom_query = custom_query[:-3]  # -3 because we want to leave a space for replies

    for r in replies:
        replied.update({r: {}})
        custom_query += "to:{} OR ".format(r)
    custom_query = custom_query[:-4]


    query_list = [custom_query]

    query_dict = {
        'limit' : int(500000/len(query_list)),
        'date' : '2020-01-01'
    }

    buggy_list = ['Lumana']

    print('Retrieving tweets based on query.....')

    df_mentions = pd.DataFrame()

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

            df_mentions = df_mentions.append(query_df)
        else:
            pass

    for t in df_mentions:
        for m in t.mentions:
            print(m['screen_name'])
            try:
                mentioned[m['screen_name']]['count'] += 1
            except KeyError:
                mentioned.update({m['screen_name']: {'by': t.username, 'count': 1}})

        # from the URL we extract the username of the user the tweet replied to
        _reply_to = requests.get(t.link).request.path_url.split('/')[1]
        try:
            replied[_reply_to]['count'] += 1
        except KeyError:
            replied.update({_reply_to: {'by': t.username, 'count': 1}})
        print('.', end='', flush=True)

    actions = {'mentioned': mentioned, 'replied': replied}
    for a in actions:
        action = actions[a]
        with open('{}.csv'.format(a), 'w') as output:
            output.write('author,{},count\n'.format(a))
            for user in action:
                output.write('{},{},{}\n'.format(action[user]['by'], user, action[user]['count']))
        print("Saved {}.csv with length of {}".format(a,len(a)))


# csv_name = 'data/mentions_'+str(datetime.date.today()).replace("-","")+'.csv'
#
# print("Exporting to csv {}, with shape {}".format(csv_name, df_mentions.shape))
#
# df_mentions.to_csv(csv_name,index=False)
