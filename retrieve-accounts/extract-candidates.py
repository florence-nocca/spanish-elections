#!/usr/bin/python
# -*- coding: utf-8 -*-

# Packages
import codecs
from pyquery import PyQuery as pq
import re

def xmltoDatabase():
# Open xml list and future candidates database .csv
# This is the updated list (nov 24), replacing the candidates-list_old.xml (nov 18) 
    candidates = codecs.open("candidates-database.csv", "w", "utf-8")
    candidates.write(('"%s","%s","%s","%s","%s","%s","%s"\n') % ("name", "sex", "election_type", "district", "party", "initials", "position"))
    page = pq(filename = "candidates-list.xml")
    district = ""
    election_type = ""
    party = ""
    initials = ""
    position = ""
    sex = ""
    substitute = False

# Extracting informations
    for line in page("texto p"):
        name = ""
        if not line.text:
            continue
# Differentiating section titles from candidates' name
        if line.text[:5] == "JUNTA":
            district = " ".join(line.text.strip().split(" ")[3:])
        if line.text[:8] == "CONGRESO":
            election_type = "congress"
        if line.text[:6] == "SENADO":
            election_type = "senate"
        if pq(line).attr("class") == "centro_redonda":
            party = line.text.split("(")[0]
            party = " ".join(party.strip().split(" ")[1:])
            substitute = False
            if "(" in line.text:
                initials = line.text.strip().split("(")[1][:-1]
            else:
                initials = ""
        # Extracting informations on candidates (name, sex, list position, party)        
        if pq(line).attr("class")[:7] == "parrafo" and line.text[0] in "0123456789" and line.text != line.text.upper():
            position = line.text.strip().split(" ")[0][:-1]
            if line.text.split(" ")[1] == "Don":
                sex = 0
                name = " ".join(line.text.strip().split(" ")[2:])[:-1]
            elif line.text.split(" ")[1] == u"Doña":
                sex = 1
                name = " ".join(line.text.strip().split(" ")[2:])[:-1]
            else:
                sex = ""
                name = " ".join(line.text.strip().split(" ")[1:])[:-1]
            if "Independiente" in name:
                party = "Independiente"
        elif line.text[0] in "0123456789" and line.text == line.text.upper():
            party = line.text.split("(")[0]
            party = " ".join(party.strip().split(" ")[1:])
            if "(" in line.text:
                initials = line.text.strip().split("(")[1][:-1]
            else:
                initials = ""
        else:
            name = ""
        if line.text[:8] == "Suplente":
            if line.text[-1] == ":":  
                substitute = True
            else:
                continue
        if "(U" in name:
            name = name.split("(")[0]
        if "(" in name.split("(")[:-1]:
            name = " ".join(name.split("(")[:-1])
        # Writing informations in database, putting aside substitutes candidates
        if substitute == True:
            name = ""
        if checkParties(initials) == True and name != "":
            if sex == "":
                sex = addInformations(name)
            candidates.write(('"%s","%s","%s","%s","%s","%s","%s"\n') % (cleanText(name), sex, election_type, district, party, initials, position))
    candidates.close()


# Keeping only candidates from selected parties 
def checkParties(party):
    tab = [u"C's",u"C´s",u"EN COMÚ",u"ERC",u"EUPV",u"EH Bildu",u"IU",u"UNIO.CAT",u"PNV",u"PODEMOS",u"PP",u"PS",u"UPyD"]
    for line in tab:
        if line in party:
            return True
    return False

# Adding informations from old database (where sex was specified using Don/Doña)
def addInformations(name):
    data = codecs.open("candidates-database_old.csv","r","utf-8")
    sex = ""
    for line in data:
        infos = line.strip().split(',')
        if not name in infos[0]:
            continue
        else:
            sex = infos[1][1:-1]
            break
    data.close()
    return(sex)

# Removing " from text (to avoid confusion with .csv separators)
def cleanText(text):
    text = re.sub('["]', " ", text)
    return(text)

xmltoDatabase()
