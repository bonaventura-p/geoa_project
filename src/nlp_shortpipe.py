
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

import re
import random
from collections import Counter

import spacy
from spacy.lemmatizer import Lemmatizer
from spacy.lang.en.stop_words import STOP_WORDS
import fr_core_news_sm

import gensim
import gensim.corpora as corpora
from gensim.utils import simple_preprocess
from gensim.models import CoherenceModel

from wordcloud import WordCloud

from gsdmm import MovieGroupProcess

from filemanager import GSheetClient, Tokenizer, TopWordsPlotter, TopicsRunner, BarPlotter #CoherenceValuesComputer


# NLP pipeline
#
# For user_data, geodata and query_data

##USER DATA
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



tweets = pd.read_table('/Users/bonaventurapacileo/Documents/Freelance/GeoA/data/tweets_20201126.csv',sep=',')


# if user_Data merge gsheet to obtain By pre-selected/not selected:
print('Merging follow_df with df_gsheet to define group assignment...')
tweets = tweets.merge(df_gsheet[['tw_name','is_influencer', 'Background','préselection']],left_on="username",right_on='tw_name',how='inner')

tweets['presel'] = '0'
tweets.loc[tweets['préselection']==1,'presel'] = '1'


tweets.rename(
    columns=
    {
        'nreplies': "replies_count",  # nreplies
        'nretweets': "retweets_count",  # nretweets
        'nlikes': "likes_count",  # nlikes
        'presel':'group'
    },
    inplace=True)


# filter tweets in French;
tweets = tweets[tweets['language']=='fr'] #filtering out ~50k tweets

# Sample together all tweets
tweets = tweets.sample(frac=.05, random_state=1992)

print("Size after sampling {}".format(tweets.shape))


def NlpPipe(tweets_df,column, group,)

bar_df = pd.DataFrame()

# # Spacy pipeline:
for group in ['0','1']:
    tweets_series = tweets.loc[tweets['group']==group,'tweet']

    print("Tweets series length is {}".format(len(tweets_series)))
    print('NLP preprocessing....')
    tokenized_series = Tokenizer(tweets_series)

    #########lda
    print('LDA preprocessing (BOW)....')
    # Mapping of word IDs to words.
    words = corpora.Dictionary(tokenized_series)

    # Bag of words of documents
    corpus = [words.doc2bow(doc) for doc in tokenized_series]

    print('Training LDA model....')
    lda_model = gensim.models.ldamodel.LdaModel(corpus=corpus,
                                                id2word=words,
                                                num_topics=10,
                                                random_state=1992,
                                                update_every=1,
                                                passes=100,
                                                alpha=0.73,
                                                eta=0.97,
                                                per_word_topics=True)

    topic_words = lda_model.print_topics(num_topics=10, num_words=3)

    topicword_dict = {}

    p = re.compile(r'[a-zA-Z]+')

    for topic_word in topic_words:
        topicword_dict[str(topic_word[0])] = p.findall(topic_word[1])


    topics = lda_model.show_topics(formatted=False)

    def cmp_key(e):
        return e[1]

    doc_topic_max = []

    for d in range(len(corpus)):
        doc_topic_max.append(max(lda_model.get_document_topics(corpus[d]), key=cmp_key)[0])

    counter = Counter(doc_topic_max)

    most_occur = counter.most_common(3)

    for n in [0,1,2]:
        bar_df = bar_df.append(
            {'metric':str(most_occur[n][0]),
             'count':most_occur[n][1],
             'group':group},
            ignore_index=True)


    cloud = WordCloud(
        background_color='white',
        width=1600,
        height=600,
        max_words=10,
        colormap='tab10',
        prefer_horizontal=1.0)

    plt.style.use('seaborn-whitegrid')

    params = {'legend.fontsize': 'xx-large',
              'figure.figsize': (15, 10),
              'axes.labelsize': 'xx-large',
              'axes.titlesize': 'xx-large',
              'xtick.labelsize': 'xx-large',
              'ytick.labelsize': 'xx-large',
              'legend.title_fontsize': 'xx-large'
              }

    for key, val in params.items():
        plt.rcParams[key] = val

    fig, axes = plt.subplots(3, 3, figsize=(10, 10), sharex=True, sharey=True)

    for i, ax in enumerate(axes.flatten()):
        fig.add_subplot(ax)
        topic_words = dict(topics[i][1])
        cloud.generate_from_frequencies(topic_words, max_font_size=300)
        plt.gca().imshow(cloud)
        plt.gca().set_title('Topic ' + str(topics[i][0]), fontdict=dict(size=16))
        plt.gca().axis('off')

    plt.subplots_adjust(wspace=0, hspace=0)
    plt.axis('off')
    plt.margins(x=0, y=0)

    #adjust spacing between subplots to minimize the overlaps
    plt.tight_layout()

    # Save the plot
    path_name = '/Users/bonaventurapacileo/Documents/Freelance/GeoA/figures/'
    plot_name = group + '_wordcloud.png'

    plt.savefig(path_name + plot_name)
    print('Wordcloud saved as {}'.format(plot_name))


bar_df['presel'] = 'Not selected'
bar_df.loc[bar_df['group'] == '1', 'presel'] = 'Pre-selected'

BarPlotter(bar_df, 'metric', 'count', 'presel', 'Topics_barplot', dodge=False)

