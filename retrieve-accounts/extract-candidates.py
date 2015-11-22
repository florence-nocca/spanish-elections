#!/usr/bin/python
# -*- coding: utf-8 -*-

# Paquets
import codecs
from pyquery import PyQuery as pq

def xmltoDatabase():
# Open xml list and future candidates database .csv
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

# extracting informations
    for line in page("texto p"):
        name = 0
        if not line.text:
            continue
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
        if pq(line).attr("class")[:7] == "parrafo" and line.text[0] in "0123456789" and line.text != line.text.upper():
            position = line.text.strip().split(" ")[0][:-1]
            if line.text.split(" ")[1] == "Don":
                sex = 0
            else:
                sex = 1
            name = " ".join(line.text.strip().split(" ")[2:][:-1])
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
            name = 0
        if line.text[:8] == "Suplente":
            if line.text[-1] == ":":  
                substitute = True
            else:
                continue
        # writing informations in database
        if substitute == True:
            name = 0
        if checkParties(initials) == True and name != 0:
            candidates.write(('"%s","%s","%s","%s","%s","%s","%s"\n') % (name, sex, election_type, district, party, initials, position))
            
def checkParties(party):
    tab = [u"C's",u"ERC",u"IU",u"UNIO.CAT",u"PNV",u"PODEMOS",u"PP",u"PS",u"UPyD"]
    for line in tab:
        if line in party:
            return True
    return False

xmltoDatabase()
