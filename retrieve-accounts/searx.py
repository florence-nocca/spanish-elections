#!/usr/bin/python
# -*- coding: utf-8 -*-

import unicodedata
from urlparse import urlparse
from threading import Thread
import httplib, sys
from Queue import Queue
import itertools
import codecs
import csv
import sys
import ssl
import re

if len(sys.argv) < 3:
    print "Usage: %s <csv database> <out csv>" % (sys.argv[0])
    exit()

# Unicode CSV reader
# http://stackoverflow.com/a/6187936
class UnicodeCsvReader(object):
    def __init__(self, f, encoding="utf-8", **kwargs):
        self.csv_reader = csv.reader(f, **kwargs)
        self.encoding = encoding

    def __iter__(self):
        return self

    def next(self):
        # read and split the csv row into fields
        row = self.csv_reader.next()
        # now decode
        return [unicode(cell, self.encoding) for cell in row]

    @property
    def line_num(self):
        return self.csv_reader.line_num

class UnicodeDictReader(csv.DictReader):
    def __init__(self, f, encoding="utf-8", fieldnames=None, **kwds):
        csv.DictReader.__init__(self, f, fieldnames=fieldnames, **kwds)
        self.reader = UnicodeCsvReader(f, encoding=encoding, **kwds)


# Remove particles and parenthesis in names
def cleanNames(names):
    filtered_names = []
    for word in names:
        if len(word) and word[0].lower() != word[0]:
            filtered_names.append(word)
    return filtered_names

# Strips accents from a unicode string
def stripAccents(s):
    return ''.join(c for c in unicodedata.normalize('NFD', s) if unicodedata.category(c) != 'Mn')

# Generates all 2+ permutations of the given array
def allCombinations(tab):
    out = []
    for n in range(2, len(tab) + 1):
        for comb in itertools.combinations(tab, n):
            out.append(" ".join(comb))
    return out

# Cycles through available urls and returns the next one in the list
def getNextBaseURL():
    out = getNextBaseURL.urllist[getNextBaseURL.counter % len(getNextBaseURL.urllist)]
    getNextBaseURL.counter += 1
    return out

getNextBaseURL.counter = 0
getNextBaseURL.urllist = [l.strip() for l in open("urls.txt", "r")]

def fetchHandles(ourl, handles):
    try:
        url = urlparse(ourl)
        conn = httplib.HTTPSConnection(url.netloc, context=ssl._create_unverified_context())
        conn.request("GET", ourl)
        res = conn.getresponse()
        if res.status != 200:
            print res.reason, ourl
            return
        for line in csv.reader((l for l in res.read().split("\n")[1:])):
            if len(line) < 2:
                continue
            match = re.match('https?://twitter.com/(\w+)[^/]*$', line[1])
            if match:
                handle = match.group(1)
                if handle not in handles:
                    handles.append(handle)
    except Exception, e:
        print "Error(%s): %s" % (ourl, e)
        exit()
        return

def doQueries():
    base = getNextBaseURL()
    while True:
        names, region, party = q.get()
        clean_names = cleanNames(stripAccents(names).split(" "))
        handles = []
        for comb in allCombinations(clean_names):
            query = comb.replace(" ", "+") + "+" + region + "+" + party + "+site:twitter.com"
            url = base + "/?format=csv&q=" + query
            fetchHandles(url, handles)
        with codecs.open(sys.argv[2], "a", "utf-8") as out:
            out.write("%s, %s\n" % (names, handles))
        print "%s, %s" % (names, handles)
        q.task_done()

concurrent = 50
q = Queue(concurrent * 2)
for i in range(concurrent):
    t = Thread(target=doQueries)
    t.daemon = True
    t.start()
try:
    with open(sys.argv[1], 'rb') as csvfile:
        first = True
        for line in UnicodeCsvReader(csvfile):
            if first:
                first = False
                continue
            names = line[0]
            region = stripAccents(line[3]).replace(" ", "+")
            party = stripAccents(line[5]).replace(" ", "+")
            if party == "C's" or party == u"C´s":
                party = "Ciudadanos"
            q.put((names, region, party))
    q.join()
except KeyboardInterrupt:
    sys.exit(1)
