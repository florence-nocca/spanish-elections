### Import packages
library(devtools)
## install_github("quanteda", username="kbenoit", dependencies=TRUE, quick=TRUE)
library(quanteda)
## install.packages("calibrate")
library(calibrate)
## install.packages("stringi")
library(stringi)
## install.packages("plotrix")
## library(plotrix)
## install.packages("FField")
## library(FField)

### Load databases
## Candidates
data = read.csv("clean_database.csv", TRUE, stringsAsFactors = FALSE)
## Candidates' tweets
tweets = read.csv("clean_ctweets.csv", TRUE, stringsAsFactors = FALSE)

## Parties
pdata = read.csv("pseudo_parties.csv", TRUE, stringsAsFactors = FALSE)
## Parties' tweets
ptweets = read.csv("clean_ptweets.csv", TRUE, stringsAsFactors = FALSE)

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

### 1st model: PSOE candidates compared to several parties at national level
psoecand_tweets = extractTweets(data, tweets, "initials", "PSOE", "candidate", "name")

## party_tweets = extractTweets(pdata, ptweets, "level", "NACIONAL", "party", "party")

parties = c("Ciudadanos","PSOE","PP","UPyD","Podemos","Izquierda Unida")
party_tweets_list = lapply(parties, function(name) return(paste(ptweets[ptweets$party == name,]$content, collapse=" ")))
## Convert the list to a vector
party_tweets = unlist(party_tweets_list)
party_tweets = party_tweets[party_tweets != ""]

### Quanteda
## Create a corpus
psoeCorpus = corpus(c(party_tweets, psoecand_tweets), enc="UTF-8")
### Predict wordscores
parties_scores = c(5, 7, 4, 2, 1, 6)
model1 = predictWordscores(psoeCorpus, parties_scores, psoecand_tweets)

### 2nd model: original tweets only
## Create retweet column and keep only original tweets
tweets["retweet"] = tolower(tweets$pseudo) != tolower(tweets$author_pseudo)
ortweets = tweets[(tweets$retweet == "FALSE"),]

ptweets["retweet"] = tolower(ptweets$pseudo) != tolower(ptweets$author_pseudo)
orptweets = ptweets[(ptweets$retweet == "FALSE"),]

## Generate documents
psoecand_ortweets = extractTweets(data, ortweets, "initials", "PSOE", "candidate", "name")
party_ortweets = extractTweets(pdata, orptweets, "level", "NACIONAL", "party", "party")

### Quanteda
### Create a corpus
orpsoeCorpus = corpus(c(party_ortweets, psoecand_ortweets), enc="UTF-8")
### Predict wordscores
model2 = predictWordscores(orpsoeCorpus, parties_scores, psoecand_ortweets)

### 3rd model: PSOE, PP, Cs and PDM candidates compared to parties at national level
party_list = c("Cs","PSOE", "PP", "UPyD", "PODEMOS", "IU-UP")
cand_tweets = lapply(party_list, function(party) return (extractTweets(data, tweets, "initials", party, "candidate", "name")))

candidates = unlist(cand_tweets)
candidates = gsub("^[^a-zA-Z]+$","", candidates, perl=TRUE)

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
parties_scores = c(5, 4, 7, 6, 2, 1) ## Left-Right scale

## Create the corpus
Corpus = corpus(c(party_tweets, candidates), enc="UTF-8")

## Predict wordscores
model3 = predictWordscores(Corpus, parties_scores, candidates)

## Graphical parameters
colors = c("darkorange","red","blue","deeppink","purple","darkred")
## Resolution options for plot
width = 1300 * 0.7
height = 768 * 0.7
dpi = 200
ratio = dpi / 72

## Histograms
scores = model3@textscores$textscore_raw
## Keep only from 7th element
cand_scores = scores[7:length(scores)]
## Extract parties' scores
pscores = scores[1:6]

colors = c("darkorange", "red", "blue", "deeppink", "purple", "darkred")

## list of scores by party
index = rep(1:length(cand_number), cand_number)
list_scores = lapply(1:6, function(party) return(cand_scores[index == party]))
party_number = (1:length(list_scores))

png("/home/noisette/Recherche memoire/Programming/spanish-elections/data-analysis/Graphs/histmodel3.png", width=width * ratio, height=height * ratio, res=dpi)
par(mfrow=c(3,3), oma = c(0, 0, 10, 0))
lapply(party_number, function(n) {
    hist = {hist(unlist(list_scores[n])[unlist(list_scores[n])>0], main=parties[n], xlab="", ylab="")
            abline(v=pscores[n], col=colors[n])
        }
    return(hist)
})
title("Positionnement des candidats sur l'échelle gauche-droite par rapport à leur parti", cex.main = 1.5, outer = TRUE)
dev.off()

### Plot
## y-axis
len = length(cand_scores[cand_scores>0])

png("/home/noisette/Recherche memoire/Programming/spanish-elections/data-analysis/Graphs/model3.png", width=width * ratio, height=height * ratio, res=dpi)
plot(x=cand_scores[cand_scores>0], y=1:len, col=rep(colors, cand_number)[cand_scores>0], xlab="Scores sur une échelle gauche-droite", ylab="Index des candidats", main="Positionnement des candidats par rapport aux partis", cex.main=1.5)
abline(v=pscores, col=colors)
legend(x=5.2, y=250, c("Cs", "PSOE", "PP", "UPyD", "Podemos", "IU-UP"), fill=colors)
dev.off()

### 4th model: PSOE candidates by region
## Generate documents
## Method 1 (slow)
## region_tweets = lapply(unique(data$initials), function(init) {
##     return (lapply(unique(data$region), function(reg) {
##         return (paste(lapply(data[data$initials == init & data$region == reg,]$name, function(name) {
##             return (tweets[tweets$candidate == name,]$content)
##         }), collapse=" "))
##     }))
## })

## Method 2
## Merge the two candidates databases data and tweets
merge_cand= merge(tweets, data, by.x="candidate", by.y="name")

region_tweets = aggregate(merge_cand$content, by=list(merge_cand$region, merge_cand$initials), FUN=function(x) return(paste(x, collapse=" ")))

## region_tweets$Group.1 -> Regions
## region_tweets$Group.2 -> Partis
## region_tweets$x       -> Tweets

psoeregion_docs = region_tweets[region_tweets$Group.2 == "PSOE",]$Group.1

### Quanteda
## Create a corpus
psoeregionCorpus = corpus(c(party_tweets, psoeregion_docs), enc="UTF-8")

### Predict wordscores
parties_scores = c(5, 7, 4, 2, 1, 6)
model4= predictWordscores(psoeregionCorpus, parties_scores, psoeregion_docs)

### Plot
scores = model4@textscores$textscore_raw
## Keep only from 7th element
psoe_scores = scores[7:length(scores)]
## Extract parties' scores
pscores = scores[1:6]
## Create labs for PSOE's regions
labs = unique(region_tweets[region_tweets$Group.2 == "PSOE" & region_tweets$Group.1 != "CATALUNA",]$Group.1)
png("/home/noisette/Recherche memoire/Programming/spanish-elections/data-analysis/Graphs/model4.png", width=800, height=600)
plot(psoe_scores[psoe_scores>0], xlab="Index des régions", ylab="Scores sur une échelle gauche-droite", main="Positionnement des candidats selon les régions", cex.main=1.5)
textxy(psoe_scores[psoe_scores>0], labs)
abline(h=pscores, col=colors)
dev.off()

## 5th model : candidates by region and by party
region_list = unique(region_tweets$Group.1)

region_docs = unlist(lapply(party_list, function(party) return(region_tweets[region_tweets$Group.2 == party,]$x)))

region_docs = gsub("^ +$","", region_docs, perl=TRUE)

##region_docs = region_docs[region_docs != ""]


### Quanteda
## Create a corpus
regionCorpus = corpus(c(party_tweets, region_docs), enc="UTF-8")

### Predict wordscores
## parties_scores = c(5, 4, 7, 6, 2, 1)
model5 = predictWordscores(regionCorpus, parties_scores, region_docs)

### Plot
scores = model5@textscores$textscore_raw
## Keep only from 7th element
region_scores = scores[7:length(scores)]
## Extract parties' scores
parties_scores = scores[1:6]
## Create a vector containing regions' number per party
reg_number = unlist(lapply(party_list, function(party) return(length(region_tweets[region_tweets$Group.2 == party,]$Group.2))))

## Set labels and legend options for plot
labs = unlist(lapply(party_list, function(party) return(region_tweets[region_tweets$Group.2 == party,]$Group.1)))
labs = gsub("^COM","VAL COM",labs)
labs = gsub("^LA ","RIO LA ",labs)
labs = gsub("^CANT","CNT CANT",labs) 
labs = gsub("C[^ ]* Y","CyL C[^ ]* Y",labs)
labs = gsub("^ILL","BAL ILL",labs)
labs = gsub("CASTILLA\\-","CLM CASTILLA-",labs)
labs = gsub("^CANA","CNR CANA",labs)
labels = stri_sub(labs,1,3)

reg_legend = paste(unique(labels), region_list, sep=" -> ")

## y-axis
len_reg = length(region_scores[region_scores>0])

## Resolution options for plot
width = 1300 * 0.7
height = 768 * 0.7
dpi = 200
ratio = dpi / 72

## Plot
png("/home/noisette/Recherche memoire/Programming/spanish-elections/data-analysis/Graphs/model5.png", width=width * ratio, height=height * ratio, res=dpi)
plot(x=region_scores[region_scores>0], y=1:len_reg, pch=1, cex=0, xlab="Scores sur une échelle gauche-droite", ylab="Index des documents", main="Positionnement des candidats par région par rapport aux partis", cex.main=1)
text(x=region_scores[region_scores>0], y=1:length(labels[region_scores>0]), labels=labels[region_scores>0], cex=0.5, col=rep(colors, reg_number)[region_scores>0])
abline(v=pscores, col=colors)
legend(x=3.25, y=50, party_list, col=colors, fill=colors, bg="white", cex=0.7)
legend(x=3.25, y=30, reg_legend, cex=0.6, pt.cex=1, bg="white", ncol=2)
dev.off()


## Plots for each party
reg_scores = cbind(rep(party_list, reg_number), region_scores)
sep_parties = lapply(party_list, function(party) return(reg_scores[reg_scores[,1] == party,][,2]))
party_number = (1:length(list_scores))
## Labels
tags = cbind(reg_scores,labels)
tags = tags[tags[,2] != "0",]

png("/home/noisette/Recherche memoire/Programming/spanish-elections/data-analysis/Graphs/model5allparties.png", width=width * ratio, height=height * ratio, res=dpi)
par(mfrow=c(3,3), oma = c(0, 0, 10, 0))
lapply(party_number, function(n) {
    x = as.numeric(unlist(sep_parties[n]))[unlist(sep_parties[n])>0]
    ylength = length(as.numeric(unlist(sep_parties[n]))[as.numeric(unlist(sep_parties[n]))>0])
    plot = {plot(x=x, y=1:ylength, xlim=c(min(pscores[n],x), max(pscores[n],x)), xlab="Scores sur l'échelle gauche-droite", ylab="Régions", main=parties[n], cex=0, col=colors[n])
            text(x=x, y=1:ylength, labels=tags[tags[,1] == party_list[n],][,3], cex=0.8, col=colors[n])
            points(x=pscores[n], y=10, col=colors[n], pch=16, cex=1.5)
        }
    return(plot)
})
dev.off()

png() 
lapply(party_number, function(n) {
    x = as.numeric(unlist(sep_parties[n]))[unlist(sep_parties[n])>0]
    ylength = length(as.numeric(unlist(sep_parties[n]))[as.numeric(unlist(sep_parties[n]))>0])
    plot = {plot(x=x, y=1:ylength, xlim=c(min(pscores[n],x), max(pscores[n],x)), xlab="Scores sur l'échelle gauche-droite", ylab="Régions", main=parties[n], cex=0, col=colors[n])
            text(x=x, y=1:ylength, labels=tags[tags[,1] == party_list[n],][,3], cex=0.8, col=colors[n])
            points(x=pscores[n], y=10, col=colors[n], pch=16, cex=1.5)
            legend(x=min(x,pscores[n]), y=3.4, pch=16, pt.cex=1.5, legend="score du parti", col=colors[n])
        }
    return(plot)
})
dev.off()
