#!/usr/bin/python
# -*- coding: utf-8 -*-

# Packages
from pyquery import PyQuery as pq
import levenshtein as lev
import string_metric as strMetric
import unicodedata
import itertools
import urllib2
import codecs
import string
import math
import sys
import re

dictionary = [{"weight":4,  "word":u"El20Decido"},
              {"weight":4,  "word":u"EspañaEnSerio"},
              {"weight":4,  "word":u"Unpaiscontigo"},
              {"weight":4,  "word":u"Un6Dcontigo"},
              {"weight":4,  "word":u"SiSePuede"},
              {"weight":4,  "word":u"ElCambioQueUne"},
              {"weight":4,  "word":u"VotaPorUnFuturoParaLaMayoría"},
              {"weight":4,  "word":u"(Mariano )?Rajoy"}, # parties, candidates
              {"weight":4,  "word":u"Pedro S[aá]nchez"},
              {"weight":4,  "word":u"Pablo Iglesias"},
              {"weight":4,  "word":u"(Albert[-_ ]|\W)Rivera\W+"},
              {"weight":4,  "word":u"20-?D"},
              {"weight":4,  "word":u"Ciudadanos"},
              {"weight":4,  "word":u"C'?s"},
              {"weight":4,  "word":u"\W+CUP\W+"},
              {"weight":4,  "word":u"EN COMÚ"},
              {"weight":4,  "word":u"\W+ERC\W+"},
              {"weight":4,  "word":u"EUPV"},
              {"weight":4,  "word":u"EH Bildu"},
              {"weight":4,  "word":u"\W+IU\W+"},
              {"weight":4,  "word":u"\W+PNV\W+"},
              {"weight":4,  "word":u"PODEMOS"},
              {"weight":4,  "word":u"Partido ?Popular"},
              {"weight":4,  "word":u"PSOE"},
              {"weight":4,  "word":u"Unió Democràtica.*Catalunya"},
              {"weight":4,  "word":u"[uU]nio.*[cC]at"},
              {"weight":4,  "word":u"UPyD"},
              {"weight":1,  "word":u"[cC]ongres[^ ]+"}, # words that can be used in another context
              {"weight":1,  "word":u"[Cc]onstituci[^ ]*"},
              {"weight":1,  "word":u"diputad[^ ]+"},
              {"weight":1,  "word":u"gobierno[^ ]*"},
              {"weight":1,  "word":u"impuestos"},
              {"weight":1,  "word":u"presupuestos"},
              {"weight":1,  "word":u"[Pp]arlament[^ ]*"},
              {"weight":1,  "word":u"[Pp]resident[^ ]*"},
              {"weight":1,  "word":u"[rR]eferéndum"},
              {"weight":1,  "word":u"[sS]enad[^ ]+"},
              {"weight":1,  "word":u"[cC]ampaña"},
              {"weight":1,  "word":u"elecci[^ ]+"},
              {"weight":1,  "word":u"electoral[^ ]*"}
]
def selectAccounts(skipBeginning = False):
    cache = codecs.open("datafiles/cache_tweets.txt", "a+", "utf-8")
    data = codecs.open("datafiles/accounts_to_select.txt", "r", "utf-8")
    accounts = codecs.open("datafiles/selected_accounts.txt", "w", "utf-8")
    scoreTotal = 0
    pseudoMax = ""
    candidatesRegrets = {}
    pseudosRegrets = {}

    if skipBeginning:
        retrievedPseudos = ["" if ',' not in l else l.strip().split(',')[0].lower() for l in cache]

    counter = 0
    i = 100
    for line in data:
         infos = line.strip().split(",")
        if len(infos) == 2:
            continue
        name = infos[0]
        pseudos = [pseudo.split("'")[1] for pseudo in infos[1:]]
        for pseudo in pseudos:
            if not pseudo:
                continue
            if skipBeginning and pseudo.lower() in retrievedPseudos:
                continue
            tweets = retrieveTweets(pseudo, cache)
            total, scorePolitisation, scorePseudo = getScore(name, pseudo, tweets)
            # Threshold
            if scorePolitisation < 50 or scorePseudo < 40:
                continue

            if candidatesRegrets.get(name) == None:
                candidatesRegrets[name] = {"@max":0}
            candidatesRegrets[name][pseudo.lower()] = [total, total, scorePolitisation, scorePseudo]
            candidatesRegrets[name]["@max"] = max(candidatesRegrets[name]["@max"], total)
            if pseudosRegrets.get(pseudo.lower()) == None:
                pseudosRegrets[pseudo.lower()] = {"@max":0}
            pseudosRegrets[pseudo.lower()][name] = [total, total, scorePolitisation, scorePseudo]
            pseudosRegrets[pseudo.lower()]["@max"] = max(pseudosRegrets[pseudo.lower()]["@max"], total)
        print "%5d, %s" % (counter, name)
        counter += 1

    normaliseRegrets(candidatesRegrets)
    normaliseRegrets(pseudosRegrets)
    couples = createCouples(candidatesRegrets, pseudosRegrets)
    couples.sort(key = lambda x: x[2])

    outCandidates = {}
    outPseudos = {}
    for candidate, pseudo, regret, score, poliScore, pseudoScore in couples:
        if outCandidates.get(candidate) or outPseudos.get(pseudo):
            continue
        outCandidates[candidate] = (pseudo, regret)
        outPseudos[pseudo] = (candidate, regret)
        accounts.write('"%s","%s"\n' % (candidate, pseudo))
        print '"%s" x "%s" (Regret: %.2f, Score: %.2f, Politisation: %.2f, PseudoScore: %.2f)' % (candidate, pseudo, regret, score, poliScore, pseudoScore)

    data.close()
    cache.close()
    accounts.close()

def createCouples(candidatesRegrets, pseudosRegrets):
    couples = []
    for candidate in candidatesRegrets.keys():
        pseudos = candidatesRegrets[candidate]
        for pseudo in pseudos.keys():
            if pseudo == "@max":
                continue
            couples.append((candidate, pseudo, pseudos[pseudo][0] + pseudosRegrets[pseudo][candidate][0], pseudos[pseudo][1], pseudos[pseudo][2], pseudos[pseudo][3]))
    return couples

def normaliseRegrets(candidates):
    for candidate in candidates.keys():
        pseudos = candidates[candidate]
        cmax = pseudos["@max"]
        for pseudo in pseudos.keys():
            if pseudo == "@max":
                continue
            score = pseudos[pseudo][0]
            pseudos[pseudo][0] = cmax - score


def retrieveTweets(pseudo, cache = None):
    def loadIndex(cache, cacheIndex):
        for line in cache:
            if ',' not in line:
                continue
            line = line.strip()
            idx = line.index(',')
            cacheIndex[line[:idx].lower()] = line[idx + 1:]

    must_close = False
    if cache == None:
        cache = codecs.open("datafiles/cache_tweets.txt", "a+", "utf-8")
        must_close = True
    else:
        cache.seek(0, 0)
        if retrieveTweets.cacheIndex == None:
            retrieveTweets.cacheIndex = {}
            loadIndex(cache, retrieveTweets.cacheIndex)
        obj = retrieveTweets.cacheIndex.get(pseudo.lower())
        if obj != None:
            return obj

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

retrieveTweets.cacheIndex = None

def getScore(name, pseudo, tweets, politicThreshold = 20):
    scoreTotal = 0
    scorePseudo = 0
    scoreTweets = getScoreTweets(tweets)
    if scoreTweets > politicThreshold:
        scorePseudo = getScorePseudo(name, pseudo)
        scoreTotal = (scoreTweets + scorePseudo) / 2.
    return scoreTotal, scoreTweets, scorePseudo

def getScoreTweets(tweets):
    score = 0
    for word in dictionary:
        match = re.findall(word["word"], tweets)
        if match:
            score += float(word["weight"] * (0.5 ** len(match) - 1)/(0.5 - 1))
    steepness = 0.25
    center = 10                 # point at which f(x) = 50
    out = 100 / (1 + math.exp(-steepness * (score - center)))
    return out

def getScorePseudo(name, pseudo):
    partiesTwitter = codecs.open("datafiles/pseudo_parties.txt","r","utf-8")
    name = cleanText(name)
    pseudo = " ".join(cleanText(pseudo))

    for line in partiesTwitter:
        parties_pseudo = line.strip().split(",")[2]
        if parties_pseudo == "":
            continue
        if pseudo == parties_pseudo:
            return 0

    return strMetric.percentage(" ".join(name), pseudo)

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
