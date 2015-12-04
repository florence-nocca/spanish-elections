#!/usr/bin/python
# -*- coding: utf-8 -*-

# Packages
from pyquery import PyQuery as pq
import levenshtein as lev
import itertools
import unicodedata
import urllib2
import codecs
import string
import sys
import re

dictionary = [{"poids":1,  "mot":u"[cC]ampaña"},
              {"poids":1,  "mot":u"[cC][aA][mM][bB][iI][^ ]+"},
              {"poids":1,  "mot":u"[Cc]andidat[^ ]*"},
              {"poids":1,  "mot":u"[cC]iudadan[^ ]+"},
              {"poids":1,  "mot":u"[cC]ongres[^ ]+"},
              {"poids":1,  "mot":u"[Cc]onstituci[^ ]*"},
              {"poids":1,  "mot":u"[dD]ebate"},
              {"poids":1,  "mot":u"democr.{1},}"},
              {"poids":1,  "mot":u"derecha"},
              {"poids":1,  "mot":u"diputad[^ ]+"},
              {"poids":1,  "mot":u"elecci[^ ]+"},
              {"poids":1,  "mot":u"electoral[^ ]*"},
              {"poids":1,  "mot":u"El20Decido"},
              {"poids":1,  "mot":u"EspañaEnSerio"},
              {"poids":1,  "mot":u"Unpaiscontigo"},
              {"poids":1,  "mot":u"Un6Dcontigo"},
              {"poids":1,  "mot":u"SiSePuede"},
              {"poids":1,  "mot":u"gobierno[^ ]*"},
              {"poids":1,  "mot":u"impuestos"},
              {"poids":1,  "mot":u"[iI]ndependen[^ ]*"},
              {"poids":1,  "mot":u"izquierda"},
              {"poids":1,  "mot":u"[Pp]arlament[^ ]*"},
              {"poids":1,  "mot":u"[Pp]resident[^ ]*"},
              {"poids":1,  "mot":u"[Pp]rograma"},
              {"poids":1,  "mot":u"[pP]ol.tic[^ ]+"},
              {"poids":1,  "mot":u"[rR]eferéndum"},
              {"poids":1,  "mot":u"[sS]enad[^ ]+"},
              {"poids":1,  "mot":u"(Mariano )?Rajoy"},
              {"poids":1,  "mot":u"Pedro S[aá]nchez"},
              {"poids":1,  "mot":u"Pablo Iglesias"},
              {"poids":1,  "mot":u"(Albert[-_ ])?Rivera"},
              {"poids":1,  "mot":u"20-?D"},
              {"poids":1,  "mot":u"C'?s"},
              {"poids":1,  "mot":u"CUP$"},
              {"poids":1,  "mot":u"EN COMÚ"},
              {"poids":1,  "mot":u"ERC"},
              {"poids":1,  "mot":u"EUPV"},
              {"poids":1,  "mot":u"EH Bildu"},
              {"poids":1,  "mot":u"IU"},
              {"poids":1,  "mot":u"PNV"},
              {"poids":1,  "mot":u"PODEMOS"},
              {"poids":1,  "mot":u"PP"},
              {"poids":1,  "mot":u"Partido ?Popular"},
              {"poids":1,  "mot":u"PS[^ ]+"},
              {"poids":1,  "mot":u"Unió Democràtica.*Catalunya"},
              {"poids":1,  "mot":u"[uU]nio.*[cC]at"},
              {"poids":1,  "mot":u"UPyD"}]

def selectAccounts(skipBeginning = False):
    cache = codecs.open("cache_tweets.txt", "a+", "utf-8")
    data = codecs.open("accounts.txt","r","utf-8")

    if skipBeginning:
        retrivedPseudos = ["" if ',' not in l else l.strip().split(',')[0].lower() for l in cache]

    for line in data:
        infos = line.strip().split(",")
        if len(infos) == 2:
            continue
        name = infos[0]
        pseudos = [pseudo.split("'")[1] for pseudo in infos[1:]]
        for pseudo in pseudos:
            if not pseudo:
                continue
            if skipBeginning and pseudo.lower() in retrivedPseudos:
                continue
            tweets = retrieveTweets(pseudo, cache)
            scoreTweets = getScoreTweets(tweets)
            scorePseudo = getScorePseudo(name, pseudo)
            print "%s(%s): %d%% politicized, name matching at %d%%" % (name, pseudo, scoreTweets, scorePseudo)
    data.close()
    cache.close()
    
def retrieveTweets(pseudo, cache = None):
    must_close = False
    if cache == None:
        cache = codecs.open("cache_tweets.txt", "a+", "utf-8")
        must_close = True
    else:
        cache.seek(0, 0)

    # Search for the tweets in the cache file
    for line in cache:
        if ',' not in line:
            continue
        line = line.strip()
        idx = line.index(',')
        if line[:idx].lower() == pseudo.lower():
            if must_close:
                cache.close()
            return line[idx + 1:]

    # Not found in the cache, search on twitter
    url = "https://twitter.com/" + pseudo
    headers = {'Accept-Language': 'en-US,en;q=0.5'}
    page = pq(url, headers=headers)
    tweets = page("div.stream div.tweet")
    content = ""
    # Retrieve informations from each tweet
    for tweet in tweets:
        tweetdom = pq(tweet)
        tweets = tweetdom("p.tweet-text").text()
        if tweets:
            tweets = re.sub("\s+", " ", tweets)
            content += tweets + " "
    cache.write("%s,%s\n" % (pseudo, content))
    if must_close:
        cache.close()
    return content
        
def getScoreTweets(tweets):
    score = 0
    for word in dictionary:
        match = re.findall(word["mot"], tweets)
        if match:
            score += word["poids"]*len(match)
    return score

def getScorePseudo(name, pseudo):
    name = cleanText(name)
    pseudo = " ".join(cleanText(pseudo))
    percentage = 0
    # Generate combinations of all words in name
    comb_names = []
    for n in range(1, len(name) + 1):
        for comb in itertools.combinations(name, n):
            comb_names.append("".join(comb))
            
    for comb_name in comb_names:
        percentage = max(percentage, lev.percentage(comb_name, pseudo))
    return percentage
        
def cleanText(s):
# Removes accents, deletes numbers and special characters, turns all characters to lowercase
    s = s.split(" ")
    clean_s = []
    
    for i in s:
        # Adapted from Abhijit, http://stackoverflow.com/a/8695067
        i = "".join(x for x in unicodedata.normalize('NFKD', i) if x in string.ascii_letters).lower()
        clean_s.append(i)
    return clean_s

selectAccounts(len(sys.argv) > 1 and sys.argv[1] == "--skip")
