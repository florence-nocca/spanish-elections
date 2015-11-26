#!/usr/bin/python
# -*- coding: utf-8 -*-

# Packages
import codecs
import sys

# The present programme adds to a selection of candidates their corresponding Twitter account and writes the new informations in  database selected-accounts.csv
# It is obtained by launching the following command: "python select-accounts.py candidates-database.csv twitter-accounts provincias > selected-accounts.csv" 

# Specifying 4 arguments when launching the command in order not to have to open all files within the programme. If incorrectly specified, a help message appears 
if len(sys.argv) < 4:
    print "Usage: %s <database.csv> <accounts_list.txt> <regions_list>" % sys.argv[0]
    exit()

# Removing blank space at the beginning and the end of each line of the files
database = [l.strip() for l in codecs.open(sys.argv[1])][1:]
accounts = [l.strip() for l in codecs.open(sys.argv[2])]
provincias = [l.strip() for l in codecs.open(sys.argv[3])]

# Error message if files do not have the same length
if len(database) != len(accounts):
    print "The database should have one line for each twitter account"
    exit()
    
print '"name", "sex", "election_type", "party", "initials", "position", "account"'
# zip permits to associate database and accounts files line by line
for line, account in zip(database, accounts):
    name,sex,election_type,district,party,initials,position = line.split('","')
    # Removing quotes
    name = name[1:]
    position = position[:-1]
    # Extracting selected candidates and writing their informations with associated Twitter account in a new csv database (specified in the command line)
    if election_type == "congress" and district in provincias:
        print (6 * '"%s", ' + '%s') % (name, sex, election_type, party, initials, position, account)
