import gspread
from oauth2client.service_account import ServiceAccountCredentials
import pandas as pd
import twint
from crawlers import TweetSearcher, QueryRunner
import networkx as nx
import matplotlib.pyplot as plt
import random
import seaborn as sns
import geopandas as gpd

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




def GraphInputMaker(df_nodes, df_edges,
                    name, node_group, nodesize, source, target, value):
    df_nodes.rename(columns={name: 'name', node_group: 'group', nodesize: 'nodesize'}, inplace=True)
    df_edges.rename(columns={source: 'source', target: 'target', value: 'value'}, inplace=True)

    return df_nodes, df_edges


def GraphMaker(df_nodes, df_edges):
    G = nx.Graph(g_node="Graph")

    for index, row in df_nodes.iterrows():
        # print('nodes:{}'.format(row['name']))
        G.add_node(row['name'], group=row['group'], nodesize=row['nodesize'])
    for index, row in df_edges.iterrows():
        # print('edges:{}'.format(row['source']))
        G.add_weighted_edges_from([(row['source'], row['target'], row['value']/1000)])

    return G


# function to create color_map and one for sizes

def NodeColorMaker(G, df_nodes):
    colors = []

    r = lambda: random.randint(0, 255)
    color_map = {}

    for group in df_nodes.group.unique():
        color_map[group] = '#{:02x}{:02x}{:02x}'.format(r(), r(), r())

    for node in G:
        colors.append(color_map[G.nodes[node]['group']])

    return colors


def NodeSizeMaker(G, df_nodes, k):
    return [G.nodes[node]['nodesize'] * k for node in G]


# def NetworkGraphMaker(
#         G,
#         colors,
#         sizes: list,
#         ind,
#         options={},
# ):
#     """
#     Using the spring layout :
#     - k controls the distance between the nodes and varies between 0 and 1
#     - iterations is the number of times simulated annealing is run
#     default k=0.1 and iterations=50
#     """
#     plt.figure(figsize=(15, 10))
#
#     if len(options) == 0:
#         print('Using default options for NetworkGraphMaker...')
#         options = {
#             'edge_color': '#555555',
#             'width': 1,
#             'with_labels': True,
#             'font_weight': 'regular',
#         }
#
#     if ind == 'mentioned':
#         k = 0.5
#     elif ind == 'replied_to':
#         k = 0.95
#     else:
#         print('default k value is 0.1')
#         k = 0.1
#
#     iterations = 100
#
#     fig = nx.draw(G, node_color=colors, node_size=sizes, pos=nx.spring_layout(G, k=k, iterations=iterations), **options)
#
#     ax = plt.gca()
#     ax.collections[0].set_edgecolor("#555555")
#     path_name = '/Users/bonaventurapacileo/Documents/Freelance/GeoA/figures/'
#     plot_name = 'ntw_k'+ str(k) +ind + '.png'
#
#     plt.savefig(path_name + plot_name)
#     print('Network graph saved as {}'.format(plot_name))
#
#     return fig


def NetworkGraphMaker(
        G,
        df_nodes,
        ind,
        group_dict
):
    """
    Using the spring layout :
    - k controls the distance between the nodes and varies between 0 and 1
    - iterations is the number of times simulated annealing is run
    default k=0.1 and iterations=50
    """
    if ind == 'mentioned':
        k = 0.5
    elif ind == 'replied_to':
        k = 0.95
    else:
        print('default k value is 0.1')
        k = 0.1

    iterations = 100

    r = lambda: random.randint(0, 255)

    fig = plt.figure(figsize=(15, 10))
    ax = fig.add_subplot(1, 1, 1)

    pos = nx.spring_layout(G)

    for group in df_nodes.group.unique():
        nx.draw_networkx_nodes(G, ax=ax, pos=pos, node_size=df_nodes.loc[df_nodes['group'] == group, 'nodesize'],
                               nodelist=df_nodes.loc[df_nodes['group'] == group, 'name'],
                               node_color='#{:02x}{:02x}{:02x}'.format(r(), r(), r()), label=group_dict[group])

    nx.draw_networkx_labels(G, pos, ax=ax, font_size=8, font_color='k', font_weight='regular')
    nx.draw_networkx_edges(G, ax=ax, pos=pos, edge_color='#000000', width=1)

    ax.legend(markerscale=.25)

    path_name = '/Users/bonaventurapacileo/Documents/Freelance/GeoA/figures/'
    plot_name = 'ntw_k'+ str(k) +ind + '.png'

    plt.savefig(path_name + plot_name)
    print('Network graph saved as {}'.format(plot_name))

    return fig


def BarDfMaker(
        file_path: str,
        df_gsheet,
        name: str,
        gs_name:str
):
    df = pd.read_table(file_path, sep=',')

    print('Merging df with df_gsheet to define group assignment...')
    df = df.merge(df_gsheet[[gs_name, 'préselection']], left_on=name, right_on=gs_name)

    df['presel'] = 'Not selected'
    df.loc[df['préselection'] == 1, 'presel'] = 'Pre-selected'

    df['group'] = df['presel']
    df.drop(['préselection', 'presel'], axis=1, inplace=True)

    if gs_name !="tw_name":
        df.drop(gs_name,axis=1, inplace=True)

    return df


def BarPlotter(
        df,
        name: str,
        posts: str,
        followers: str,
        following: str,
        platform: str,
):
    if platform == 'Twitter':
        post = 'Tweets'
        palette = 'Blues'
    else:
        post = 'Posts'
        palette = 'Reds'

    df.rename(
        columns={followers: 'Followers', posts: post, following: 'Following'},
        inplace=True)

    melt_df = df.melt(id_vars=[name, 'group'], var_name='metric', value_name='count')

    plt.style.use('ggplot')
    plt.figure(figsize=(15, 10))

    fig = sns.barplot(x='metric',
                      y='count',
                      data=melt_df,
                      hue='group',
                      palette=palette,
                      ci=0)

    # Save the plot
    path_name = '/Users/bonaventurapacileo/Documents/Freelance/GeoA/figures/'
    plot_name = platform + '_barplot.png'

    plt.savefig(path_name + plot_name)
    print('Barplot saved as {}'.format(plot_name))

    return fig


def ChoroplethMaker(df,left_on,column):


    niger = gpd.read_file('/Users/bonaventurapacileo/Documents/Freelance/GeoA/src/maps/shape_files_niger/adm01.shp')


    #choropleth
    niger_df = gpd.GeoDataFrame(df.merge(niger,right_on='adm_01',left_on = left_on,how='outer'))

    fig, ax = plt.subplots(1, 1)

    niger_df.plot(ax=ax, column=column,cmap="autumn_r", scheme='natural_breaks',alpha=0.7,
                  figsize=(35, 20),
                  legend=True,
                legend_kwds={
                    'title':'Average {}'.format(column.replace('_mean',"")),
            # 'labels': ["horizontal",'2','3','4','5'],
                            'loc': "upper left"},
                  linewidth=.1) #k for quantiles

    # Save the plot
    path_name = '/Users/bonaventurapacileo/Documents/Freelance/GeoA/figures/'
    plot_name =  column + '_choropleth.png'

    plt.savefig(path_name + plot_name)
    print('Choropleth saved as {}'.format(plot_name))
