### Load candidates' database
data = read.csv("Databases/database.csv", TRUE, stringsAsFactors = FALSE)
data = data[data$initials != "EN POSITIU",]

### Clean party initials
data$initials = gsub("[^a-zA-Z ]", "", data$initials, perl=TRUE) ## keep only alphanum and whitespace
data$initials = gsub(".*PSOE.*", "PSOE", data$initials, perl=TRUE) ## uniquify PSOE
data$initials = gsub(".*PP.*", "PP", data$initials, perl=TRUE) ## uniquify PP
data$initials = gsub("(^|[^TA]+)(E|I)U.*", "IU-UP", data$initials, perl=TRUE) ## uniquify IU-UP
data$initials = gsub("PODEMOS(AHAL DUGU)?", "PODEMOS", data$initials, perl=TRUE) ## PODEMOS
data$initials = gsub("PODEMOSCOMPROMS", "PODEMOS-COMPROMIS", data$initials, perl=TRUE) ## Valencian coalition Podemos/Compromis
data$initials = gsub(".*ANOVA.*", "PODEMOS-EU-En Marea-ANOVA", data$initials, perl=TRUE) ## Galician coalition Podemos/IU & others
data$initials = gsub("EN COM", "PODEMOS-EN COMU", data$initials, perl=TRUE) ## Catalan coalition Podemos/EU/ICV/Equo/BCN EN COMÚ
data$initials = gsub("ERC.*", "ERC", data$initials, perl=TRUE) ## uniquify ERC

### Clean party names 
data[data$party == "EN MAREA",]$party = "COALITION : PODEMOS-EU-ANOVA" ## Galician Podemos/IU's coalition
data[data$party == "SENADORES MAJOREROS",]$party = "PARTIDO POPULAR"
data$party = gsub(".*UNI(D|T)A(D|T).*", "IZQUIERDA UNIDA - UNIDAD POPULAR", data$party, perl=TRUE) ## uniquify IU-UP
data$party = gsub(".*((CIUDADANOS)|(CIUTADANS)).*", "CIUDADANOS", data$party, perl=TRUE) ## uniquify Cs
data$party = gsub("PARTIDO POPULAR(/PARTIT POPULAR)?", "PARTIDO POPULAR", data$party, perl=TRUE) ## uniquify PP
data$party = gsub("PODEMOS(-AHAL DUGU)?", "PODEMOS", data$party, perl=TRUE) ## uniquify PODEMOS
data$party = gsub("EN COMÚ PODEM", "COALITION : PODEMOS-EU-BCN EN COMÚ", data$party, perl=TRUE) ## Podemos/IU's Catalan coalition

region = data$district

region[region == "district"] = "region"

region[region == "ALMERÍA" | region == "CÁDIZ" | region == "CÓRDOBA" | region == "GRANADA" | region == "HUELVA" | region == "JAÉN" | region == "MÁLAGA" | region == "SEVILLA"] = "ANDALUCIA"

region[region == "HUESCA" | region == "TERUEL" | region == "ZARAGOZA"] = "ARAGON"

region[region == "LAS PALMAS" | region == "SANTA CRUZ DE TENERIFE"] = "CANARIAS"

region[region == "ALBACETE" | region == "CIUDAD REAL" | region == "CUENCA" | region == "GUADALAJARA" | region == "TOLEDO"] = "CASTILLA-LA MANCHA"

region[region == "ÁVILA" | region == "BURGOS" | region == "LEÓN" | region == "PALENCIA" | region == "SALAMANCA" | region == "SEGOVIA" | region == "SORIA" | region == "VALLADOLID" | region == "ZAMORA"] = "CASTILLA Y LEON"

region[region == "BARCELONA" | region == "GIRONA" | region == "LLEIDA" | region == "TARRAGONA"] = "CATALUNA"

region[region == "ALICANTE/ALACANT" | region == "CASTELLÓN/CASTELLÓ" | region == "VALENCIA/VALÈNCIA"] = "COMUNIDAD VALENCIANA"

region[region == "BADAJOZ" | region == "CÁCERES"] = "EXTREMADURA"

region[region == "CORUÑA (A)" | region == "LUGO" | region == "OURENSE" | region == "PONTEVEDRA"] = "GALICIA"

region[region == "ARABA/ÁLAVA" | region == "BIZKAIA" | region == "GIPUZKOA"] = "PAIS VASCO"

data = cbind(data, region)

### Write a new clean csv database
write.table(data, file = "Databases/clean_database.csv",row.names=FALSE, na="",col.names=TRUE, sep=",")

### Create function to clean text
cleanTweets = function(database)
    {
### Remove URLs, clean # and @
        database$content = gsub("[^ ]*htm[^ ]*", "", database$content, perl=TRUE, ignore.case=TRUE) ## remove html
        database$content = gsub("[0-9a-zA-Z]+\\-[0-9a-zA-Z]+\\-[^ ]*", "", database$content, perl=TRUE, ignore.case=TRUE)        
        database$content = gsub("https?[^ ]*", "", database$content, perl=TRUE, ignore.case=TRUE) ## remove https URLs
        database$content = gsub("(m\\.)?youtube\\.[^ ]*", "", database$content, perl=TRUE, ignore.case=TRUE) ## remove Youtube URLs
        database$content = gsub("(pic\\.)?twitter[^ ]*", "", database$content, perl=TRUE, ignore.case=TRUE) ## remove Twitter URLs
        database$content = gsub("[^ ]+=[^ ]+", "", database$content, perl=TRUE, ignore.case=TRUE) ## remove further URLs
        database$content = gsub("(#|@) ([^ ]+)", "\\1\\2", database$content, perl=TRUE, ignore.case=TRUE) ## remove whitespace in # and @
        database$content = gsub("fb.me[^ ]*", "", database$content, perl=TRUE, ignore.case=TRUE) ## remove Facebook URLs
        database$content = gsub("(https?)?www\\. ([^ ]*)", "", database$content, perl=TRUE, ignore.case=TRUE) ## remove www URLs
        database$content = gsub("[^ ]*/ ?[^ ]*", "", database$content, perl=TRUE, ignore.case=TRUE) ## remove text with /
        database$content = gsub("'", " ", database$content, perl=TRUE, ignore.case=TRUE) ## replace ' with whitespace
        database$content = gsub("[^-_a-zA-Z\u00C0-\u017F0-9#@ ]", "", database$content, perl=TRUE, ignore.case=TRUE) ## keep only alphanum, accents, # @ - _
        database$content = gsub("(^ *) | ( *$)","", database$content, perl=TRUE, ignore.case=TRUE) ## remove whitespace in at the begining/end of tweets
        database$content = gsub("^[-_#@0-9 ]*$","", database$content, perl=TRUE, ignore.case=TRUE) ## remove content containing only non alpha char 
        database$content = gsub("^..?.?.?$","", database$content, perl=TRUE, ignore.case=TRUE) ## remove content with less than 5 char
### Clean author_pseudo
        database$author_pseudo = gsub("@ ", "", database$author_pseudo, perl=TRUE, ignore.case=TRUE)
        return(database)
    }

### Load and clean candidates' data
tweets = read.csv("Databases/candidates_tweets.csv", TRUE, stringsAsFactors = FALSE)
colnames(tweets) = c("candidate", "pseudo", "author_name", "author_pseudo", "tweet_date", "content", "retrieve_date")

## Remove "EN POSITIU" candidates
tweets = tweets[tweets$candidate != "Ana Calatayud Tortosa" & tweets$candidate != "Emilio José Espert Navarro" & tweets$candidate != "María José Martínez Mas" & tweets$candidate != "Máximo Rueda Pitarque" & tweets$candidate != "Amparo Giner Lorenzo" & tweets$candidate != "Juan José Llopis Puig" & tweets$candidate != "Patricia Romero García" & tweets$candidate != "Antonio María Fornés Cervera" & tweets$candidate != "María Carmen Barba García" & tweets$candidate != "Ramón Cebriá Pascual" & tweets$candidate != "Rosario Navarro Sala" & tweets$candidate != "José Antonio García Maldonado" & tweets$candidate != "Rosa Guirolat Martínez" & tweets$candidate != "Emilio José Espert Clemente" & tweets$candidate != "Inmaculada Soto Ortega" & tweets$candidate != "Miquel García i Maldonado" & tweets$candidate != "Carolina Palmero Rovira" & tweets$candidate != "Vicente Boix Ferrandis",]

## Remove candidates with false accounts
tweets = tweets[tweets$candidate != "Miguel Angel Cuervo Santos" & tweets$candidate != "Matilde Isabel Rodríguez Castro" & tweets$candidate != "Marta Elena Miranda Muñoz" & tweets$candidate != "María del Henar Álvarez García" & tweets$candidate != "Núria Rodríguez i Olivé" & tweets$candidate != "Luz María Rodríguez Pérez" & tweets$candidate != "Isabel Antonia Piqueras Blas" & tweets$candidate != "José Carlos Iglesias Rodríguez",]

tweets$pseudo = tolower(tweets$pseudo)

## Remove wrong pseudos
tweets = tweets[tweets$pseudo != "teresajimenez64" & tweets$pseudo != "miguel_ce" & tweets$pseudo != "maquefernandez" & tweets$pseudo != "santiago_torres" & tweets$pseudo != "juanribas" & tweets$pseudo != "dominguezurbina" & tweets$pseudo != "veigacarmen" & tweets$pseudo != "j_asanchez" & tweets$pseudo != "_anapastor_" & tweets$pseudo != "mmontalvoc22" & tweets$pseudo != "arovirap" & tweets$pseudo != "teresarodr_" & tweets$pseudo != "paquiconde" & tweets$pseudo != "196193jose" & tweets$pseudo != "vazqueztoscano" & tweets$pseudo != "escribanojosem" & tweets$pseudo != "iolandapineda" & tweets$pseudo != "taniagonzalez73" & tweets$pseudo != "penalosveiga" & tweets$pseudo != "emilioruizmateo" & tweets$pseudo != "jcruizjoan" & tweets$pseudo != "viquimoreno" & tweets$pseudo != "fran_vazquez_" & tweets$pseudo != "daniel_herrero" & tweets$pseudo != "davidcar2" & tweets$pseudo != "jrmarting" & tweets$pseudo != "gilmariajo" & tweets$pseudo != "j10perez" & tweets$pseudo != "0seuba" & tweets$pseudo != "juan11967" & tweets$pseudo != "delallorens" & tweets$pseudo != "jorge76leont" & tweets$pseudo != "soniagomez81" & tweets$pseudo != "mjcastromateos" & tweets$pseudo != "rojopilar" & tweets$pseudo != "ccarlosrguez" & tweets$pseudo != "teresaro" & tweets$pseudo != "mariapilarpere4" & tweets$pseudo != "mariacruzg21" & tweets$pseudo != "martamgarcia" & tweets$pseudo != "mariaireal" & tweets$pseudo != "rosapromero" & tweets$pseudo != "mariobravo07" & tweets$pseudo != "pepeblancoep" & tweets$pseudo != "r_soraya" & tweets$pseudo != "pamartin63" & tweets$pseudo != "luciaog" & tweets$pseudo != "javiercaso" & tweets$pseudo != "tomascasas_1" & tweets$pseudo != "juanra__fdez" & tweets$pseudo != "carmen171258" & tweets$pseudo != "israpozogarcia" & tweets$pseudo != "marcbertomeu" & tweets$pseudo != "joseltj23" & tweets$pseudo != "mariarey_cs" & tweets$pseudo != "luismagf" & tweets$pseudo != "luismimontero" & tweets$pseudo != "segundogg" & tweets$pseudo != "seijodani" & tweets$pseudo != "alfonsoammar" & tweets$pseudo != "martinez101274" & tweets$pseudo != "carmenmoonn" & tweets$pseudo != "antonioperal" & tweets$pseudo != "adricano1990" & tweets$pseudo != "m__jimenez" & tweets$pseudo != "e_garciaserrano" & tweets$pseudo != "antoniormesa" & tweets$pseudo != "manuperez2002" & tweets$pseudo != "vallemiguelez" & tweets$pseudo != "antoniomiguelrr"  & tweets$pseudo != "raqueljimenez76" & tweets$pseudo != "mariavros" & tweets$pseudo != "marialopezperez" & tweets$pseudo != "elenagomezn" & tweets$pseudo != "enricruiz2011" & tweets$pseudo != "frandomenech" & tweets$pseudo != "aguilar_sanz" & tweets$pseudo != "belen091" & tweets$pseudo != "juanmjg" & tweets$pseudo != "martamescudero" & tweets$pseudo != "alfonadan" & tweets$pseudo != "juanjtortosa" & tweets$pseudo != "conpereznavas" & tweets$pseudo != "millanmiguel1" & tweets$pseudo != "mariahervas56" & tweets$pseudo != "jrmarting" & tweets$pseudo != "yolandafersan"& tweets$pseudo != "joantarres11" & tweets$pseudo != "rosaliatrainer" & tweets$pseudo != "felix_casanova" & tweets$pseudo != "jorgesanchezlop" & tweets$pseudo != "jantoniomilla" & tweets$pseudo != "aliciagarciappc" & tweets$pseudo != "rtorres_javier" & tweets$pseudo != "anamariamuoz20" & tweets$pseudo != "gballesterosw" & tweets$pseudo != "luzf" & tweets$pseudo != "maria_alcalde_" & tweets$pseudo != "fongonzalez" & tweets$pseudo != "anagmoreno" & tweets$pseudo != "sublascojordana" & tweets$pseudo != "julian711229" & tweets$pseudo != "ignaciogoq" & tweets$pseudo != "mantonialopez" & tweets$pseudo != "csaavedra68" & tweets$pseudo != "pilar10pilar1" & tweets$pseudo != "luisayllon" & tweets$pseudo != "maria30569" & tweets$pseudo != "mariluz099" & tweets$pseudo != "mariarosaalcaz1" & tweets$pseudo != "josemromero" & tweets$pseudo != "ana_analva" & tweets$pseudo != "mariasimonma" & tweets$pseudo != "sanjuanov" & tweets$pseudo != "mjmadridgarcia" & tweets$pseudo != "belenmrodriguez" & tweets$pseudo != "diazmarta6" & tweets$pseudo != "carmenvieites" & tweets$pseudo != "mfdezmiranda" & tweets$pseudo != "elenagonzalez" & tweets$pseudo != "gomezjuancar",]

tweets = tweets[tweets$pseudo != "mariajo0" & tweets$pseudo != "miguelcortizodp" & tweets$pseudo != "mariadiezsc" & tweets$pseudo != "contrerasbegona" & tweets$pseudo != "manuelfdezvega" & tweets$pseudo != "mariagomezgarc7" & tweets$pseudo != "isabelromanm" & tweets$pseudo != "carlosgomezgil" & tweets$pseudo != "belen_gdiaz" & tweets$pseudo != "_delmoral" & tweets$pseudo != "pinedopilar" & tweets$pseudo != "gomezant" & tweets$pseudo != "juliovicenteglz" & tweets$pseudo != "ruizruizfj" & tweets$pseudo != "cjimenezcruz" & tweets$pseudo != "coboortiz99" & tweets$pseudo != "sussuarez" & tweets$pseudo != "mariaje77" & tweets$pseudo != "luisagonzlez13" & tweets$pseudo != "luis_angel_sanz" & tweets$pseudo != "j_a_isla" & tweets$pseudo != "netmolina" & tweets$pseudo != "mararevaloa" & tweets$pseudo != "josefa_calzada" & tweets$pseudo != "santanagonalez",]

## Clean tweets' content
cleaned_tweets = cleanTweets(tweets)

### Write a new clean csv database
write.csv(cleaned_tweets, file = "Databases/clean_ctweets.csv", row.names=FALSE)

### Load parties' data
ptweets = read.csv("Databases/parties_tweets.csv", TRUE, stringsAsFactors = FALSE)
colnames(ptweets) = c("party", "pseudo", "author_name", "author_pseudo", "tweet_date", "content", "retrieve_date")

## Harmonize parties' names with the candidates' database
ptweets[ptweets$party == "Ciudadanos",]$party = "Cs"
ptweets[ptweets$party == "Podemos",]$party = "PODEMOS"

cleaned_ptweets = cleanTweets(ptweets)

### Write a new clean csv database
write.csv(cleaned_ptweets, file = "Databases/clean_ptweets.csv", row.names=FALSE)
