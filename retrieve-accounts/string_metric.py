#!/usr/bin/python
# -*- coding: utf-8 -*-

"""
Some basic utility functions to compute distance and similarity between strings
"""

def ratio(a, b):
    if not b or not a:
        return 0
    a = a.lower()
    b = b.lower()
    originsz = float(len(b))
    for word in a.split():
        if word in b:
            b = b.replace(word, "")
    return (originsz - len(b)) / originsz

def percentage(a, b):
    """ Matching percentage between strings a and b"""
    return ratio(a, b) * 100.
