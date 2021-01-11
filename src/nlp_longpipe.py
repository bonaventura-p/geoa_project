
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
#import plotly.graph_objects as go
import seaborn as sns
#plt.rcParams["figure.figsize"] = (25,10)

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

from filemanager import GSheetClient, Lemmatizer, LemmaCleaner, Tokenizer, TopWordsPlotter, TopicsRunner #CoherenceValuesComputer


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
tweets = tweets.sample(frac=.05, random_state=1992) #12143 tweets

print("Size after sampling {}".format(tweets.shape))

# # Spacy pipeline:
tweets_series = tweets['tweet']


#loop by group
#

# ####core preprocessing
# nlp = fr_core_news_sm.load()
#
# # My list of stop words.
# stop_list = ["n","l","y","d","qu","t"," ", "  "]
#
# # Updates spaCy's default stop words list with my additional words.
# nlp.Defaults.stop_words.update(stop_list)
#
# #customise pipeline
# nlp.remove_pipe("ner")
# nlp.add_pipe(Lemmatizer,name='Lemmatizer',after='parser')
# nlp.add_pipe(LemmaCleaner, name="LemmaCleaner", last=True)

#with new stop words
print('NLP preprocessing....')
tokenized_series=Tokenizer(tweets_series)
# tokenized_series = []
# for doc in tweets_series:
#     token = nlp(doc)
#     tokenized_series.append(token)


#########lda
print('LDA preprocessing (BOW)....')
# Mapping of word IDs to words.
words = corpora.Dictionary(tokenized_series)

#Bag of words of documents
corpus = [words.doc2bow(doc) for doc in tokenized_series]

print('Training LDA model....')
lda_model = gensim.models.ldamodel.LdaModel(corpus=corpus,
                                               id2word=words,
                                               num_topics=10,
                                               random_state=1992,
                                               update_every=1,
                                               passes=100,
                                               alpha=0.73,
                                                eta = 0.97,
                                               per_word_topics=True)

topics = lda_model.print_topics(num_topics=10, num_words=6)

t=0
for topic in topics:
    print ("Topic {} -> {}".format(t,topic))
    t+=1


######gsdmm
random.seed(1992)
# Init of the Gibbs Sampling Dirichlet Mixture Model algorithm
mgp = MovieGroupProcess(K=10, alpha=0.73, beta=0.97, n_iters=30)


vocab = set(x for doc in tokenized_series for x in doc)
n_terms = len(vocab)
n_docs = len(tokenized_series)

# Fit the model on the data given the chosen seeds
print('Training GSDMM model....')

y = mgp.fit(tokenized_series, n_terms)

#probability the doc belongs to the topic

print(sum([max(mgp.score(tokenized_series[n])) for n in range(len(tokenized_series))])/
      len([max(mgp.score(tokenized_series[n])) for n in range(len(tokenized_series))]))

doc_count = np.array(mgp.cluster_doc_count)

# Topics sorted by the number of document they are allocated to
top_index = doc_count.argsort()[-10:][::-1]

#top_index = doc_count.argsort()[-8:][::-1]

TopicsRunner(mgp.cluster_word_distribution, top_index, 10)



sort_dict_keeper = TopWordsPlotter(mgp.cluster_word_distribution, top_index, 10)

word_cluster = []
for cluster in top_index:
    sort_cluster=sorted(mgp.cluster_word_distribution[cluster].items(), key=lambda k: k[1], reverse=True)[:10]
    word_cluster.append((cluster,sort_cluster))

topics = lda_model.show_topics(formatted=False)


g = 0

for model in [topics, word_cluster]:

    print(model)


    cloud = WordCloud(
                      background_color='white',
                      width=1600,
                      height=600,
                      max_words=10,
                      colormap='tab10',
                      prefer_horizontal=1.0)


    fig, axes = plt.subplots(3, 3, figsize=(10,10), sharex=True, sharey=True)

    for i, ax in enumerate(axes.flatten()):
        fig.add_subplot(ax)
        topic_words = dict(model[i][1])
        cloud.generate_from_frequencies(topic_words, max_font_size=300)
        plt.gca().imshow(cloud)
        plt.gca().set_title('Topic ' + str(model[i][0]), fontdict=dict(size=16))
        plt.gca().axis('off')


    plt.subplots_adjust(wspace=0, hspace=0)
    plt.axis('off')
    plt.margins(x=0, y=0)
    plt.tight_layout()
    #plt.show()
    plt.savefig('wordcloud_'+str(g)+".png")
    g +=1
    print('..........................................................................')







#
# #loading english model from spacy
# nlp = fr_core_news_sm.load()
#
# #customise pipeline
# nlp.remove_pipe("ner")
# nlp.add_pipe(Lemmatizer,name='Lemmatizer',after='parser')
# nlp.add_pipe(LemmaCleaner, name="LemmaCleaner", last=True)
#
# tokenized_series = Tokenizer(tweets_series)
#
# unnested_list = sum(tokenized_series,[])
#
# counter = Counter(unnested_list)
#
# most_occur = counter.most_common(10)
#
# all_occur = counter.most_common()

#
# fig, ax = plt.subplots()
#
# bar=ax.bar(*zip(*most_occur))
# plt.xticks(rotation=90, fontSize=16)
# plt.yticks(fontSize=14)
# plt.ylabel('Count', fontSize=16)
# plt.title('Most frequent words in the collection', fontSize=23)
#
# plt.show()