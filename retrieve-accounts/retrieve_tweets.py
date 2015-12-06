#!/usr/bin/python
# -*- coding: utf-8 -*-

from pyquery import PyQuery as pq
import calendar
import urllib2
import codecs
import time
import re
import os, os.path

def shouldRetrieve(pseudoToCheck):
    try:
        if os.stat("tweets_generales.csv").st_size == 0:
            print "return because file empty"
            return True
    except:
        print "return because file does not exist"
        return True
    tweets = codecs.open("datafiles/tweets_generales.csv", "r", "utf-8")
    for line in reversed(tweets.readlines()):
        line = line.strip()
        fields = line.split(',')
        pseudo = fields[1][1:-1]
        if pseudo.lower() == pseudoToCheck.lower():
            oneDay = 60 * 60 * 24
            timeElapsed = int(time.time()) - int(fields[6][1:-1])
            tweets.close()
            return timeElapsed > oneDay
    tweets.close()
    return True

def getLineFromDatabase(name):
    with codecs.open("datafiles/candidates_database.csv","r","utf-8") as database:
        header = True
        for line in database:
            if header:
                header = False
                continue
            fullname = line.strip().split(",")[0][1:-1]
            cleanFullname = " ".join(cleanNames(fullname))
            if cleanFullname == name:
                return fullname, line.strip()
    return None, None

def retrieveFromList(date_min = "", date_max = ""):
    candidates = codecs.open("datafiles/selected_accounts.txt", "r", "utf-8") # Canditates + pseudos
    for candidate in candidates:
        fields = candidate.strip().split(",")
        name = " ".join(cleanNames(fields[0][1:-1]))
        pseudo = fields[1][1:-1]
        fullname, databaseLine = getLineFromDatabase(name)
        if not fullname:
            print "Error: couldn't find name '%s' in database" % name
            continue
        print "Retrieving tweets for", fullname
        if shouldRetrieve(pseudo):
            retrievePages(databaseLine, fullname, pseudo, date_min, date_max)
    candidates.close()

def cleanNames(names):
    filtered_names = []
    for word in names.split(" "):
        if (len(word) and word[0].lower() != word[0] and
            ord(word[0]) < 128 and u"ª" not in word):
            filtered_names.append(word)
    return filtered_names

def writeAccounts(page, databaseLine, pseudo):
    with codecs.open("datafiles/candidates_accounts.csv","a+","utf-8") as accounts:
        for line in accounts:
            foundPseudo = line.strip().split(',')[7][1:-1]
            if foundPseudo == pseudo:
                return
        
        location = cleanText(page(".ProfileHeaderCard-location").text())
        biography = cleanText(page(".ProfileHeaderCard-bio").text())
        subscription_ini = page(".ProfileHeaderCard-joinDateText").attr("title")
        subscription = ""
        if subscription_ini:
            subscription = strToTimestamp(subscription_ini.split(" - ")[1])
        accounts.write('%s,"%s","%s","%s","%s"\n' % (databaseLine, pseudo, location, subscription, biography))    

def retrievePages(databaseLine, name, pseudo, date_min = "", date_max = ""):
    data = codecs.open("datafiles/tweets_generales.csv", "a", "utf-8")

    # If no minimal date is specified, the program searches in the file the last tweets written
    if date_min == "":
        timestamp_min = findTimestampMax(pseudo)
    else:
        timestamp_min = strToTimestamp(date_min)

    # Max. date by default is the date at which the program is launched
    if date_max == "":
        timestamp_max = int(time.time())
    else:
        timestamp_max = strToTimestamp(date_max)

    # Retrieve informations about the candidate
    page = pq("https://twitter.com/" + pseudo, headers={'Accept-Language': 'en-US,en;q=0.5'})
    writeAccounts(page, databaseLine, pseudo)
    ret = retrieveTweets(name, pseudo, page, timestamp_min, timestamp_max, 0)
    if len(ret) == 0:
        t = int(time.time())
        ret = ((6 * '"%s",' + '"%d"\n') % (name, pseudo, "", "", t, "", t))
    data.write(ret)
    data.close()
    
def retrieveTweets(name, pseudo, page, timestamp_min, timestamp_max, timestamp_old, first_page = True, has_more_items = True):
    if first_page:
        css = "div.stream div.tweet"
    else:
        css = "div.tweet"
    tweets = page(css)
    params = ""
    tweet_id = ""
    
    # Retrieve information for each tweet
    for tweet in tweets:
        tweetdom = pq(tweet)
        content = cleanText(tweetdom("p.tweet-text").text())
        tweet_author = cleanText(tweetdom("strong.fullname").eq(0).text())
        tweet_pseudo = tweetdom("span.username").eq(0).text()

        # If tweet is a retweet, its timestamp is modified in order for the program to continue
        if tweet_pseudo.lower() == '@ ' + pseudo.lower():
            timestamp = int(tweetdom("span._timestamp").attr("data-time"))
        else:
            timestamp = timestamp_old

        # Retrieve page's last tweet id to create next page's url later
        tweet_id = tweetdom.attr("data-item-id")
        # Do not take into account pinned tweets
        if tweetdom("span.js-pinned-text"):
            print "Pinned tweet found. Continue."
            continue
        # Skip tweets until date_max, and then retrieve them until date_min
        if timestamp == 0:
            continue
        if timestamp >= timestamp_max:
            continue
        if timestamp > 0 and timestamp <= timestamp_min:
            return params
        timestamp_old = timestamp
        params += ((6 * '"%s",' + '"%d"\n') % (name, pseudo, tweet_author, tweet_pseudo, timestamp, content, int(time.time())))

    if not has_more_items:
        return params
    
    # Create next page's url and open it
    base = "https://twitter.com/i/profiles/show/"
    parameters = "/timeline?include_available_features=1&include_entities=1&max_position="
    url = base + pseudo + parameters + tweet_id
    req = urllib2.urlopen(url)
    # Read code in utf-8
    obj = unicode(req.read(), "utf-8")
    # Transform next page's json code (obtained using Live HTTP Headers) into html
    obj = obj.decode("unicode_escape").replace('\\/', '/')
    more_items = (obj.split("\"has_more_items\":")[1].split(',')[0] == "true")
    obj = obj.split("\"items_html\":\"")[1][:-2]
    if not obj.strip():
        print "No tweets available"
        return params
    
    # Recall function with first page option set to "False"
    params += retrieveTweets(name, pseudo, pq(obj), timestamp_min, timestamp_max, timestamp_old, False, more_items)
    return params

# Convert date to timestamp
def strToTimestamp(date_min):
    time_struct = time.strptime(date_min, "%d %b %Y")
    timestamp = calendar.timegm(time_struct)
    return(timestamp)

# Find last tweet retrieved's date
def findTimestampMax(pseudo):
    try:
        csv = codecs.open("datafiles/tweets_generales.csv", "r", "utf-8")
    except:
        print "File not found"
        return 0
    # Create a table containing timestamps for each line of the csv file
    tab = [int(line.strip().split(",")[7][1:-1]) if line.strip().split(",")[1][3:-1] == pseudo else 0 for line in csv]
    csv.close()
    # Returns greater timestamp (hence the more recent)
    return max(tab)

# Remove quotes and \n in data
def cleanText(text):
    if not text:
        return ""
    text = re.sub('[\s,"]', " ", text)
    return text

retrieveFromList("04 Dec 2015")

