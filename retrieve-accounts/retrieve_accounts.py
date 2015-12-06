#!/usr/bin/python
# -*- coding: utf-8 -*-

# Packages
from pyquery import PyQuery as pq
import itertools
import urllib2
import codecs
import time
import sys
import re

if len(sys.argv) <= 2:
    print "Usage: %s <database.csv> <accounts_list.txt>" % sys.argv[0]
    exit()

def retrieveAccounts():
    database = [l.strip() for l in codecs.open(sys.argv[1])][1:]
    accounts = codecs.open(sys.argv[2], "a+")
    accounts_lines = [l.strip() for l in accounts]
    previous_name = ""
    
    if len(accounts_lines):
        previous_name = accounts_lines[-1].split(",")[0]
        
    for line in database:
    # Retrieve columns
        columns = line.strip().split('","')
        names = columns[0][1:].split(" ")

        district = columns[3]
        party = columns[5]
        if party == "C's":
            party = "Ciudadanos"

        names = cleanNames(names)
        if previous_name:
            if " ".join(names) == previous_name:
                previous_name = ""
            continue
        
        # Separate first names and last names
        separator = 2
        if len(names) <= 2:
            separator = 1
        fname = names[:separator]
        lname = names[separator:]
    
        # Generate combinations of first and last names
        comb_fnames = allCombinations(fname)
        comb_lnames = allCombinations(lname)
        handle_list = []
        for fnames in comb_fnames:
            for lnames in comb_lnames:
                print " ".join([fnames, lnames, district, party])
                #getTwitters_ddg(" ".join([fnames, lnames, district, party]), 10, handle_list)
                getTwitters_Tw(" ".join([fnames, lnames]), 10, handle_list)
                # getTwitters_G(" ".join([fnames, lnames, district, party]), 10, handle_list)
                # Taking a brief break between each search in order not to be ejected by the website
                time.sleep(3)
        accounts.write (('%s, %s\n') % ((" ".join(names)), handle_list))
        print (" ".join(names))

def cleanNames(names):
# Remove particles and parenthesis in names
    filtered_names = []
    for word in names:
        if len(word) and word[0].lower() != word[0]:
            filtered_names.append(word)
    return filtered_names
    
def allCombinations(tab):
    out = []
    for n in range(1, len(tab) + 1):
        for comb in itertools.combinations(tab, n):
            out.append(" ".join(comb))
    return out

# Retrieving candidates twitters from DuckDuckGo
def getTwitters_ddg(query, nbAccounts, out):
    site = "site:twitter.com"
    lang = "es-es"
    base = "https://duckduckgo.com/html/"
    url = base + "?q=" + query + " " + site + "&kl=" + lang
    page = pq(url = url)

    counter = 0
    links = page("a.large")
    for link in links:
        twitter_url = pq(link).attr("href")
        if re.match('https?://twitter.com/[^/]+$', twitter_url):
            handle = twitter_url.split('/')[-1]
            if handle not in out:
                out.append(handle)
            # handle = handle.split("twitter.com/")[1]
            counter += 1
            if counter >= nbAccounts:
                break
    return out

# Retrieving candidates twitters from Twitter
def getTwitters_Tw(query, nbAccounts, out):
    base = "https://twitter.com/search?f=users&vertical=default"
    url = base + "&q=" + query + "&src=typd"
    page = pq(url = url)
    counter = 0
    links = page("a.ProfileCard-screennameLink")
    for link in links:
        handle = pq(link).attr("href")
        if "/" in handle:
            handle = handle.split('/')[-1]
        if handle not in out:
            out.append(handle)
        counter += 1
        if counter >= nbAccounts:
            break
    return out

# Retrieving candidates twitters from Google
def getTwitters_G(query, nbAccounts, out):
    site = "site:twitter.com"
    base = "https://encrypted.google.com/search?"
    url = base + "q=" + query + " " + site
    page = pq(url = url)
    counter = 0
    for link in page("cite"):
        twitter_url = pq(link).text().replace(" ", "")
        if re.match('https?://twitter.com/[^/]+$', twitter_url):
            handle = twitter_url.split('/')[-1]
            if '?' in handle:
                handle = handle.split('?')[0]
            if handle not in out:
                out.append(handle)
            counter += 1
            if counter >= nbAccounts:
                break
    return out

retrieveAccounts()
