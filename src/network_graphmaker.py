import pandas as pd
import numpy as np
from filemanager import GSheetClient, GraphInputMaker, GraphMaker, NodeColorMaker, NodeSizeMaker, NetworkGraphMaker
import sys
import os

ind=sys.argv[1]

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

df_gsheet['tw_name'] = [field.replace('@','') for field in df_gsheet['tw_name']]

print('Google Sheet converted to dataframe.....')

#
print('Importing Twitter data and engineering features...')
mention_df = pd.read_table('/Users/bonaventurapacileo/Documents/Freelance/GeoA/data/mention_reply_20201202.csv',
                           sep=',')
follow_df = pd.read_table('/Users/bonaventurapacileo/Documents/Freelance/GeoA/data/follows_20201207.csv', sep=',')

follow_df['tw_followers_std'] = (follow_df['tw_followers'] - follow_df['tw_followers'].mean()) / follow_df[
    'tw_followers'].var() ** .5
# follow_df['tw_followers_log'] = np.log(follow_df['tw_followers']).replace(-np.inf, 0)

for action in mention_df.action.unique().tolist():
    #print(action)
    mention_df['logcnt_' + str(action)] = np.log(mention_df[mention_df.action == action]['count']).replace(-np.inf, 0)
    mention_df['invlogcnt_' + str(action)] = (1/(np.log(mention_df[mention_df.action==action]['count']).replace(-np.inf,0)))*100
    #remember to invert the stdcount as count represents weight/cost/distance
    # mention_df['stdcount_' + str(action)] = (mention_df[mention_df.action == action]['count'] -
    #                                          mention_df[mention_df.action == action]['count'].mean()) / \
    #                                         mention_df[mention_df.action == action]['count'].var() ** .5


print('Merging follow_df with df_gsheet to define group assignment...')
follow_df = follow_df.merge(df_gsheet[['tw_name','is_influencer', 'Background','préselection']],left_on="tw_name",right_on='tw_name')

follow_df['presel'] = '0'
follow_df.loc[follow_df['préselection']==1,'presel'] = '1'

follow_df['group'] = follow_df['presel']

# takes a while to run
print('Running check of authors in tw_name....')

mention_df = mention_df[mention_df['author'].isin(follow_df.tw_name.unique())]
mention_df = mention_df[mention_df['target'].isin(follow_df.tw_name.unique())]

print("Creating graph objects....")

df_nodes, df_edges = GraphInputMaker(follow_df, mention_df.loc[mention_df['action'] == ind],
                                     'tw_name', 'group', 'tw_followers_std', 'author', 'target', 'invlogcnt_'+ind)
G = GraphMaker(df_nodes, df_edges)

df_nodes['nodesize'] = df_nodes['nodesize']*1000

group_dict = {'0':'Not Pre-selected','1':'Pre-selected'}

NetworkGraphMaker(
        G,
        df_nodes,
        ind,
    group_dict
)


colors = NodeColorMaker(G, df_nodes)
sizes = NodeSizeMaker(G, df_nodes, k=1000)

# options = {
#     'edge_color': '#555555',
#     'width': 1,
#     'with_labels': True,
#     'font_weight': 'regular',
# }

# NetworkGraphMaker(G, colors, sizes, ind, options)