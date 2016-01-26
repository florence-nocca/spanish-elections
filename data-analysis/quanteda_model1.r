### Import packages
library(devtools)
## install_github("quanteda", username="kbenoit", dependencies=TRUE, quick=TRUE)
library(quanteda)
library(calibrate)
library(stringi)


### Load databases
## Candidates
data = read.csv("Databases/clean_database.csv", TRUE, stringsAsFactors = FALSE)
## Candidates' tweets
tweets = read.csv("Databases/clean_ctweets.csv", TRUE, stringsAsFactors = FALSE)

## Parties
pdata = read.csv("Databases/pseudo_parties.csv", TRUE, stringsAsFactors = FALSE)
## Parties' tweets
ptweets = read.csv("Databases/clean_ptweets.csv", TRUE, stringsAsFactors = FALSE)

### Create a function to extract tweets
extractTweets = function(x, tweets, member, criteria, tweets_member, data_member)
{
    func = function(name) {
        return (paste(tweets[tweets[,tweets_member] == name,]$content, collapse=" "))
    }
    sep = lapply(x[x[,member] == criteria,data_member], func)
    ## Convert the list to a vector
    tweets = unlist(sep);
    return (tweets[tweets != ""])
}

### Create a function to predict wordscores
predictWordscores = function(corpus, ref_scores, virgin_docs)
{
    dfm_doc = dfm(corpus, ignoredFeatures=stopwords("spanish"), stem=TRUE)
    scores = c(ref_scores, rep(NA, length(virgin_docs)))
    ws = textmodel_wordscores(dfm_doc, scores = scores)
    pred = predict(ws)
    return (pred)
}

### 1st model: PSOE, PP, Cs and PDM candidates compared to parties at national level
## Candidates' documents
party_list = c("Cs","PSOE", "PP", "UPyD", "PODEMOS", "IU-UP")
cand_tweets = lapply(party_list, function(party) return (extractTweets(data, tweets, "initials", party, "candidate", "name")))

candidates = unlist(cand_tweets)
candidates = gsub("^[^a-zA-Z]+$","", candidates, perl=TRUE)

## Parties' documents
parties = c("Ciudadanos","PSOE","PP","UPyD","Podemos","Izquierda Unida")
party_tweets_list = lapply(parties, function(name) return(paste(ptweets[ptweets$party == name,]$content, collapse=" ")))
## Convert the list to a vector
party_tweets = unlist(party_tweets_list)
party_tweets = party_tweets[party_tweets != ""]


## Some basic description of documents
nchar_candidates = lapply(candidates, nchar)
range_ncharc = range(nchar_candidates[nchar_candidates>0]) ## 115 to 1 086 828
nchar_parties = lapply(party_tweets, nchar)
range_ncharp = range(nchar_parties) ## 4 599 279 to 21 217 429

### Quanteda
## Create a vector containing candidates' number per party
cand_number = unlist(lapply(cand_tweets, length))
## Repeat party_list conformingly 
cand_parties = rep(party_list, cand_number)

## Set parties' scores
## parties = c("Ciudadanos","PSOE","PP","UPyD","Podemos","Izquierda Unida")
parties_scoresLR = c(5, 4, 7, 6, 2, 1) ## Left-Right scale

## Create the corpus
Corpus = corpus(c(party_tweets, candidates), enc="UTF-8")

## Predict wordscores
model1 = predictWordscores(Corpus, parties_scoresLR, candidates)


### Graphical representations
## Graphical parameters
colors = c("darkorange","red","blue","deeppink","purple","darkred")
## Resolution options for plot
width = 1300 * 0.7
height = 768 * 0.7
dpi = 200
ratio = dpi / 72

## Scores to plot
scores = model1@textscores$textscore_raw
## Keep only from 7th element
cand_scores = scores[7:length(scores)]
## Extract parties' scores
pscores = scores[1:6]

### Plot
## y-axis
len = length(cand_scores[cand_scores>0])

png("/home/noisette/Recherche memoire/Programming/spanish-elections/data-analysis/Graphs/plotmodel1.png", width=width * ratio, height=height * ratio, res=dpi)
plot(x=cand_scores[cand_scores>0], y=1:len, col=rep(colors, cand_number)[cand_scores>0], xlab="Scores sur une échelle gauche-droite", ylab="Index des candidats", main="Positionnement des candidats par rapport aux partis", cex.main=1.5)
abline(v=pscores, col=colors)
legend(x=5.2, y=250, c("Cs", "PSOE", "PP", "UPyD", "Podemos", "IU-UP"), fill=colors)
dev.off()

### Histograms
## list of scores by party
index = rep(1:length(cand_number), cand_number)
list_scores = lapply(1:6, function(party) return(cand_scores[index == party]))
party_number = (1:length(list_scores))

## Histograms by party
png("/home/noisette/Recherche memoire/Programming/spanish-elections/data-analysis/Graphs/histmodel1.png", width=width * ratio, height=height * ratio, res=dpi)
par(mfrow=c(3,3), oma = c(0, 0, 10, 0))
lapply(party_number, function(n) {
    hist(unlist(list_scores[n])[unlist(list_scores[n])>0], main=parties[n], xlab="", ylab="")
    abline(v=pscores[n], col=colors[n])
})
title("Positionnement des candidats sur l'échelle gauche-droite par rapport à leur parti", cex.main = 1.5, outer = TRUE)
dev.off()

## Regions ordered as candidates
parties_cand = unlist(lapply(party_list, function(party) return(data[data$initials == party,]$name)))
ordered_regions = data[match(parties_cand[parties_cand %in% tweets$candidate], data$name),]$region
## Create a data frame containing scores, party and region
index = rep(1:length(cand_number), cand_number)
dfcand = data.frame(score=cand_scores, party=index, region=ordered_regions)

### Hist by party and by region
pdf("/home/noisette/Recherche memoire/Programming/spanish-elections/data-analysis/Graphs/histmodel1byregion.pdf")
par(mfrow=c(3,3), oma = c(0, 0, 0, 0))
lapply(party_number, function(n) {
    lapply(as.character(unique(dfcand[dfcand$party == n & dfcand$score > 0,]$region)), function(region) {
        minxlim = min(pscores[n],dfcand[dfcand$party == n & dfcand$region == region & dfcand$score>0,]$score)
        maxxlim = max(pscores[n],dfcand[dfcand$party == n & dfcand$region == region & dfcand$score>0,]$score)
        hist(dfcand[dfcand$party == n & dfcand$region == region & dfcand$score>0,]$score, main=c(parties[n],region),col.main=colors[n], xlim=c(minxlim,maxxlim), xlab="", ylab="")
        abline(v=pscores[n], col=colors[n])
    })})
dev.off()

### Variations (scores on other dimensions)
## Set parties' scores
## parties = c("Ciudadanos","PSOE","PP","UPyD","Podemos","Izquierda Unida")
parties_scoresREG = c(7, 4, 7.5, 8, 2.5, 3) ## Decentralisation scale

## Predict wordscores
model1a = predictWordscores(Corpus, parties_scoresREG, candidates)

## Scores to plot
scores = model1a@textscores$textscore_raw
## Keep only from 7th element
cand_scores = scores[7:length(scores)]
## Extract parties' scores
pscores = scores[1:6]

### Plot
## y-axis
len = length(cand_scores[cand_scores>0])

png("/home/noisette/Recherche memoire/Programming/spanish-elections/data-analysis/Graphs/plotmodel1a.png", width=width * ratio, height=height * ratio, res=dpi)
plot(x=cand_scores[cand_scores>0], y=1:len, col=rep(colors, cand_number)[cand_scores>0], xlab="Scores", ylab="Index des candidats", main="Positionnement des candidats sur la décentralisation par rapport aux partis", sub="(0 = favorable à la décentralisation, 10 = opposé)", cex.main=1.5)
abline(v=pscores, col=colors)
legend(x=6.5, y=250, c("Cs", "PSOE", "PP", "UPyD", "Podemos", "IU-UP"), fill=colors)
dev.off()

### Histograms
## list of scores by party
index = rep(1:length(cand_number), cand_number)
list_scores = lapply(1:6, function(party) return(cand_scores[index == party]))
party_number = (1:length(list_scores))

## Histograms by party
png("/home/noisette/Recherche memoire/Programming/spanish-elections/data-analysis/Graphs/histmodel1a.png", width=width * ratio, height=height * ratio, res=dpi)
par(mfrow=c(3,3), oma = c(0, 0, 10, 0))
lapply(party_number, function(n) {
    xlim_min = min(pscores[n],unlist(list_scores[n])[unlist(list_scores[n])>0])
    xlim_max = max(pscores[n],unlist(list_scores[n])[unlist(list_scores[n])>0])
    hist(unlist(list_scores[n])[unlist(list_scores[n])>0], main=parties[n], xlab="", ylab="", xlim=c(xlim_min,xlim_max))
    abline(v=pscores[n], col=colors[n])
})
title("Positionnement des candidats sur la décentralisation par rapport à leur parti (0 = favorable, 10 = opposé)", cex.main = 1.5, outer = TRUE)
dev.off()
