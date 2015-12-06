#!/usr/bin/python
# -*- coding: utf-8 -*-

def mergeFiles():
    # Remove particles and parenthesis in names
    def cleanNames(names):
        filtered_names = []
        for word in names.split(" "):
            if (len(word) and word[0].lower() != word[0] and
                ord(word[0]) < 128 and u"ª" not in word):
                filtered_names.append(word)
        return filtered_names

    twitter = codecs.open("datafiles/accounts.txt","r","utf-8")
    searx = codecs.open("datafiles/accounts_searx.txt","r","utf-8")
    out = codecs.open("datafiles/accounts_to_select.txt","w","utf-8")

    for t in twitter:
        index_t = t.strip().split(",")
        name_t = " ".join(cleanNames(index_t[0]))
        pseudos_t = []
        if "'" in t and ("'" not in name_t or t.index("'") != name_t.index("'")):
            pseudos_t = [pseudos_t.split("'")[1] for pseudos_t in index_t[1:]]
        found = False

        for s in searx:
            index_s = s.strip().split(",")
            name_s = " ".join(cleanNames(index_s[0]))
            if name_s == name_t:
                pseudos_s = []
                if "'" in s and ("'" not in name_s or s.index("'") != name_s.index("'")):
                    pseudos_s = [pseudos_s.split("'")[1] for pseudos_s in index_s[1:]]
                pseudos = list(set(pseudos_s + pseudos_t))
                out.write("%s, %s\n" % (name_t, pseudos))
                found = True
                break

        if not found:
            print index_t[0], '->', name_t
            out.write("%s, %s\n" % (name_t, pseudos_t))

        searx.seek(0, 0)
        
    twitter.close()
    searx.close()
    out.close()
