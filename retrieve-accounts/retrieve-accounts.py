#!/usr/bin/python
# -*- coding: utf-8 -*-

# Packages
import codecs
import time
import calendar
import urllib2
from pyquery import PyQuery as pq

# Retrieving candidates' pseudo on Twitter from the csv list
def retrievePseudo():
    candidates = codecs.open("candidates-database.csv", "r", "utf-8")
    accounts = codecs.open("twitter-accounts", "w", "utf-8")
    results = ""
    # Creating a table containing candidates' names from the csv list
    index = 0
    # Skipping the first line (header)
    for line in candidates:
        if index == 0:
            index +=1
            continue
        # Retrieving names and corresponding districts for all candidates
        name = line.split(",")[0][1:-1]
        district = line.split(",")[3][1:-1]
        party = line.split(",")[5][1:-1]
        # Launching a web search on DuckDuckGo name + district + Twitter (+ options language = Spanish, country = Spain)
        page = pq(url = "https://duckduckgo.com/html/?q=" + name + " " + district + " twitter" + "&kl=es-es")
# Retrieving results' links (href) (from Mozilla's option "Inspect element") 
        links = page("a.large")
        for link in links:
            results = pq(link).attr("href")
            # Keeping the first link containing "twitter.com"
            if "twitter.com/" in results:
                # If the link is a tweet (status), we only keep the account's address
                if "/status/" in results:
                    results = results.split("/status")[0]
                # If the link is only the main Twitter page, we display an error
                test_link = results.split("twitter.com/")[1]
                if test_link == "":
                    results = "No result found for " + name + " of " +  party + " in " + district
                break
            else:
                results = "No result found for " + name + " of " +  party + " in " + district
        print results
        # Writing for each candidate the address or the error in the results file
        accounts.write(('"%s"\n') % (results))
        # Taking a brief break between each search in order not to be ejected by the website
        time.sleep(3)
    candidates.close()
    accounts.close()

retrievePseudo()
