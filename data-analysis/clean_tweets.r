### Load and clean candidates' data
tweets = read.csv("Databases/candidates_tweets.csv", FALSE, stringsAsFactors = FALSE)
colnames(tweets) = c("candidate", "pseudo", "author_name", "author_pseudo", "tweet_date", "content", "retrieve_date")

### Remove URLs, clean # and @
tweets$content = gsub("https?[^ ]*", "", tweets$content, perl=TRUE) ## remove https URLs
tweets$content = gsub("(m\\.)?youtu[^ ]*", "", tweets$content, perl=TRUE) ## remove Youtube URLs
tweets$content = gsub("(pic\\.)?twitter[^ ]*", "", tweets$content, perl=TRUE) ## remove Twitter URLs
tweets$content = gsub("(#|@) ([^ ]+)", "\\1\\2", tweets$content, perl=TRUE) ## remove whitespace in # and @
tweets$content = gsub("fb.me[^ ]*", "", tweets$content, perl=TRUE) ## remove Facebook URLs
tweets$content = gsub("(https?)?www\\. ([^ ]*)", "", tweets$content, perl=TRUE) ## remove www URLs
tweets$content = gsub("[^ ]*/ ?[^ ]*", "", tweets$content, perl=TRUE) ## remove text with /
tweets$content = gsub("'", " ", tweets$content, perl=TRUE) ## replace ' with whitespace
tweets$content = gsub("[^-_a-zA-Z\u00C0-\u017F0-9#@ ]", "", tweets$content, perl=TRUE) ## keep only alphanum, accents, # @ - _

### Clean author_pseudo
tweets$author_pseudo = gsub("@ ", "", tweets$author_pseudo, perl=TRUE)

### Write a new clean csv database
write.csv(tweets, file = "Databases/clean_ctweets.csv", row.names=FALSE)

### Load parties' data
ptweets = read.csv("Databases/parties_tweets.csv", FALSE, stringsAsFactors = FALSE)
colnames(ptweets) = c("party", "pseudo", "author_name", "author_pseudo", "tweet_date", "content", "retrieve_date")

### Remove URLs, clean # and @
ptweets$content = gsub("https?[^ ]*", "", ptweets$content, perl=TRUE) ## remove https URLs
ptweets$content = gsub("(m\\.)?youtu[^ ]*", "", ptweets$content, perl=TRUE) ## remove Youtube URLs
ptweets$content = gsub("(pic\\.)?twitter[^ ]*", "", ptweets$content, perl=TRUE) ## remove Twitter URLs
ptweets$content = gsub("(#|@) ([^ ]+)", "\\1\\2", ptweets$content, perl=TRUE) ## remove whitespace in # and @
ptweets$content = gsub("fb.me[^ ]*", "", ptweets$content, perl=TRUE) ## remove Facebook URLs
ptweets$content = gsub("(https?)?www\\. ([^ ]*)", "", ptweets$content, perl=TRUE) ## remove www URLs
ptweets$content = gsub("[^ ]*/ ?[^ ]*", "", ptweets$content, perl=TRUE) ## remove text with /
ptweets$content = gsub("'", " ", ptweets$content, perl=TRUE) ## replace ' with whitespace
ptweets$content = gsub("[^-_a-zA-Z\u00C0-\u017F0-9#@ ]", "", ptweets$content, perl=TRUE) ## keep only alphanum, accents, # @ - _

### Clean author_pseudo
ptweets$author_pseudo = gsub("@ ", "", ptweets$author_pseudo, perl=TRUE)

### Write a new clean csv database
write.csv(ptweets, file = "Databases/clean_ptweets.csv", row.names=FALSE)

### Load candidates' database
data = read.csv("Databases/database.csv", FALSE, stringsAsFactors = FALSE)
colnames(data) = c("name","sex","election_type","district","party","initials","position")

### Clean party initials
data$initials = gsub("[^a-zA-Z ]", "", data$initials, perl=TRUE) ## keep only alphanum and whitespace
data$initials = gsub(".*PSOE.*", "PSOE", data$initials, perl=TRUE) ## uniquify PSOE
data$initials = gsub(".*PP.*", "PP", data$initials, perl=TRUE) ## uniquify PP
data$initials = gsub(".*(E|I)U.*", "IU-UP", data$initials, perl=TRUE) ## uniquify IU-UP
data$initials = gsub("ERC.*", "ERC", data$initials, perl=TRUE) ## uniquify ERC
data$initials = gsub("(PODEMOS.*)|EN COM", "PODEMOS", data$initials, perl=TRUE) ## uniquify PODEMOS
data[data$party == "EN POSITIU",]$initials = "EN POSITIU"
data[data$party == "EN MAREA",]$initials = "PODEMOS + IU-UP" ## coalition Podemos/IU


### Clean party names 
data[data$party == "EN MAREA",]$party = "PODEMOS + IU-UP" ## coalition Podemos/IU
data[data$party == "SENADORES MAJOREROS",]$party = "PARTIDO POPULAR"

data$party = gsub(".*UNI(D|T)A(D|T).*", "IZQUIERDA UNIDA - UNIDAD POPULAR", data$party, perl=TRUE) ## uniquify IU-UP
data$party = gsub(".*((CIUDADANOS)|(CIUTADANS)).*", "CIUDADANOS", data$party, perl=TRUE) ## uniquify Cs
data$party = gsub(".*PARTIDO POPULAR.*", "PARTIDO POPULAR", data$party, perl=TRUE) ## uniquify PP
data$party = gsub(".*SOCIALIST.*", "PARTIDO SOCIALISTA OBRERO ESPANOL", data$party, perl=TRUE) ## uniquify PSOE
data$party = gsub(".*PODEMOS[^\\+]*", "PODEMOS", data$party, perl=TRUE) ## uniquify PSOE
data$party = gsub("PODEMOS\\+ IU-UP", "PODEMOS + IU-UP", data$party, perl=TRUE) ## coalition Podemos/IU
data$party = gsub("EN COM.*", "PODEMOS", data$party, perl=TRUE) ## uniquify Podemos

### Write a new clean csv database
write.table(data, file = "Databases/clean_database.csv",row.names=FALSE, na="",col.names=FALSE, sep=",")

clean_data= read.csv("Databases/clean_database.csv", FALSE, stringsAsFactors = FALSE)
region = data$district

region[region == "district"] = "region"

region[region == "ALMERÍA" | region == "CÁDIZ" | region == "CÓRDOBA" | region == "GRANADA" | region == "HUELVA" | region == "JAÉN" | region == "MÁLAGA" | region == "SEVILLA"] = "ANDALUCIA"

region[region == "HUESCA" | region == "TERUEL" | region == "ZARAGOZA"] = "ARAGON"

region[region == "LAS PALMAS" | region == "SANTA CRUZ DE TENERIFE"] = "CANARIAS"

region[region == "ALBACETE" | region == "CIUDAD REAL" | region == "CUENCA" | region == "GUADALAJARA" | region == "TOLEDO" | region == "ÁVILA" | region == "BURGOS" | region == "LEÓN"] = "CASTILLA-LA MANCHA"

region[region == "PALENCIA" | region == "SALAMANCA" | region == "SEGOVIA" | region == "SORIA" | region == "VALLADOLID" | region == "ZAMORA"] = "CASTILLA Y LEON"

region[region == "BARCELONA" | region == "GIRONA" | region == "LLEIDA" | region == "TARRAGONA"] = "CATALUNA"

region[region == "ALICANTE/ALACANT" | region == "CASTELLÓN/CASTELLÓ" | region == "VALENCIA/VALÈNCIA"] = "COMUNIDAD VALENCIANA"

region[region == "BADAJOZ" | region == "CÁCERES"] = "EXTREMADURA"

region[region == "CORUÑA (A)" | region == "LUGO" | region == "OURENSE" | region == "PONTEVEDRA"] = "GALICIA"

region[region == "ARABA/ÁLAVA" | region == "BIZKAIA" | region == "GIPUZKOA"] = "PAIS VASCO"


clean_data = cbind(clean_data, region)

write.table(clean_data, file = "Databases/clean_database.csv",row.names=FALSE, na="",col.names=FALSE, sep=",")
