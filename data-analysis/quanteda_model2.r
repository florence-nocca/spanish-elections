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

### 2nd model: candidates by party and by region
### Generate parties's documents
parties = c("Ciudadanos","PSOE","PP","UPyD","Podemos","Izquierda Unida")
party_tweets_list = lapply(parties, function(name) return(paste(ptweets[ptweets$party == name,]$content, collapse=" ")))
## Convert the list to a vector
party_tweets = unlist(party_tweets_list)
party_tweets = party_tweets[party_tweets != ""]

### Generate regions' documents
## Merge the two candidates databases data and tweets
merge_cand= merge(tweets, data, by.x="candidate", by.y="name")
## Regroup tweets by candidates from the same party and region
region_tweets = aggregate(merge_cand$content, by=list(merge_cand$region, merge_cand$initials), FUN=function(x) return(paste(x, collapse=" ")))
## region_tweets$Group.1 -> Regions
## region_tweets$Group.2 -> Partis
## region_tweets$x       -> Tweets
region_list = unique(region_tweets$Group.1)
region_docs = unlist(lapply(party_list, function(party) return(region_tweets[region_tweets$Group.2 == party,]$x)))
region_docs = gsub("^ +$","", region_docs, perl=TRUE)

### Quanteda
## Create a corpus
regionCorpus = corpus(c(party_tweets, region_docs), enc="UTF-8")

### Predict wordscores
parties_scores = c(5, 4, 7, 6, 2, 1)
model2 = predictWordscores(regionCorpus, parties_scores, region_docs)

### Graphical representation
## Graphical parameters
colors = c("darkorange","red","blue","deeppink","purple","darkred")
## Resolution options for plot
width = 1300 * 0.7
height = 768 * 0.7
dpi = 200
ratio = dpi / 72

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

### Scores for plot
scores = model2@textscores$textscore_raw
## Keep only from 7th element
region_scores = scores[7:length(scores)]
## Extract parties' scores
parties_scores = scores[1:6]
## Create a vector containing regions' number per party
party_list = c("Cs","PSOE", "PP", "UPyD", "PODEMOS", "IU-UP")
reg_number = unlist(lapply(party_list, function(party) return(length(region_tweets[region_tweets$Group.2 == party,]$Group.2))))

## Plot
png("/home/noisette/Recherche memoire/Programming/spanish-elections/data-analysis/Graphs/plotmodel2.png", width=width * ratio, height=height * ratio, res=dpi)
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

png("/home/noisette/Recherche memoire/Programming/spanish-elections/data-analysis/Graphs/plotmodel2byparty.png", width=width * ratio, height=height * ratio, res=dpi)
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
