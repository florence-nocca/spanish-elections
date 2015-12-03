#!/usr/bin/python
# -*- coding: utf-8 -*-

import numpy as np

"""
Some basic utility function to compute distance and similarity between strings
based on Levenshtein distance
"""

def distance(a, b):
    """Levenshtein distance between strings a and b"""
    
    # Variable creation
    m, n = len(a), len(b)
    d = np.zeros((m + 1, n + 1))

    # Initialisation
    for i in xrange(1, m + 1):
        d[i, 0] = i
    for j in xrange(1, n + 1):
        d[0, j] = j

    # Computation
    for i in xrange(1, m + 1):
        for j in xrange(1, n + 1):
            deletion = d[i - 1, j] + 1
            addition = d[i, j - 1] + 1
            substitution = d[i - 1, j - 1] + (a[i - 1] != b[j - 1])
            d[i, j] = min(deletion, addition, substitution)

    return d[-1, -1]

def ratio(a, b):
    """Levenshtein-based matching ratio between strings a and b"""
    total = len(a) + len(b)
    d = distance(a, b)
    return float(total - d) / total

def percentage(a, b):
    """Levenshtein-based matching percentage between strings a and b"""
    return ratio(a, b) * 100.
