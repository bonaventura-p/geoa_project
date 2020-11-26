#####Bruno book IO chapter
####JOFRE ROCABERT IP2

#DATA PREPARATION

class(corpus$Entity_Name)
# Is there anything getting entities by IP project? No but there is a script that soes separate analysis by entities.

unique(corpus$Entity_Name)
unique(corpus$Media_Language) #what values does language have?
unique(corpus$Media_Country) #what values does country have?

corpus <- corpus[corpus$Media_Language=="EN",] #take only English articles
unique(corpus$Entity_Name) #what entities are present in the English sample?
corpus <- corpus[!is.na(corpus$Entity_Name),] #remove articles that are "NA" for entity name (~6)
unique(corpus$Tonality_Verbalized)
corpus <- corpus[!is.na(corpus$Tonality_Verbalized),] #remove articles that are "NA" for Tonality (~3), otherwise the following 
#loop doesn't work (i.e. the cbind command at the end)


#recode several independent variables (basically: generate dummies from character vectors of interest)
vars <- c("Entity_Name",
          "Media_Type",
          "Media_Country",
          "Media_Source",
          "Tonality_Verbalized",
          "actor.type",
          "policy.scope",
          "territorial.scope",
          "policy.output"
)

for (var in vars){
  corpus[,c(var)] <- factor(corpus[,c(var)])
  tmp_vars <- as.data.frame(model.matrix(~ corpus[,c(var)] - 1))
  tmp_vars[,c("(Intercept)")] <- NULL
  colnames(tmp_vars) <- gsub("corpus[, c(var)]", "", colnames(tmp_vars), fixed = T)
  colnames(tmp_vars) <- paste(var, colnames(tmp_vars), sep = "_")
  corpus <- cbind(corpus, tmp_vars)
}

colnames(corpus) <- tolower(colnames(corpus))

corpus$functional_scope_informative <- corpus$functional.scope..new..informative
corpus$functional_scope_informative[corpus$functional_scope_informative == "yes"] <- "1"
corpus$functional_scope_informative[corpus$functional_scope_informative == "no"] <- "0"
corpus$functional_scope_informative <- as.numeric(corpus$functional_scope_informative)

corpus$functional_scope_implementing <- corpus$functional.scope..new..implementing
corpus$functional_scope_implementing[corpus$functional_scope_implementing == "yes"] <- "1"
corpus$functional_scope_implementing[corpus$functional_scope_implementing == "no"] <- "0"
corpus$functional_scope_implementing <- as.numeric(corpus$functional_scope_implementing)

corpus$functional_scope_decisive <- corpus$functional.scope..new..decisive
corpus$functional_scope_decisive[corpus$functional_scope_decisive == "yes"] <- "1"
corpus$functional_scope_decisive[corpus$functional_scope_decisive == "no"] <- "0"
corpus$functional_scope_decisive <- as.numeric(corpus$functional_scope_decisive)

corpus <- corpus[order(corpus$entity_id),]
unique(corpus[c("entity_id","entity_name")])


# aggregate number of articles per week (or day, or month? and weight by number of words? if yes, how?)
min(corpus$article_date)
max(corpus$article_date)

require(lubridate)
days <- data.frame(days = seq(as.Date("2005-01-01"), as.Date("2016-01-03"), by="days")) #the period for which articles are available for the three entities
days$weeks <- week(days$days)
days$years <- year(days$days)

corpus$article_date <- as.Date(corpus$article_date)
corpus$n <- 1

# take the logged number of words for the weighted aggregation (?!)
hist(corpus$article_word_count)
corpus$n_w <- log1p(corpus$article_word_count) 
hist(corpus$n_w)
dat_base <- merge(corpus, days, by.x = "article_date", by.y = "days", all = T) #we use this dataset as a starting point for 
#the following analyses, in which we subset the data for each individual governor to have the timeline and the peak times

#add zeros for days without coverage
dat_base$n[is.na(dat_base$n)] <- 0
dat_base$n_w[is.na(dat_base$n_w)] <- 0
dat_base$tonality_verbalized_negative[is.na(dat_base$tonality_verbalized_negative)] <- 0

### SALIENCE ANd TONALITY GRAPHS BY INDIVIDUAL GOVERNOR ###

install.packages("forecast")
install.packages("smooth")
install.packages("plyr")
install.packages("tseries")
install.packages("forecast")

library(forecast)
library(smooth)
library(plyr)
library(tseries)
library(forecast)

#commonwealth of nations
#----------
dat_6 <- dat_base[dat_base$entity_id==6,]
require(plyr)
dat_6 <- ddply(dat_6, .(weeks, years), function (x) {
  data.frame(n = sum(x$n), n_w = sum(x$n_w), ton_neg=sum(x$tonality_verbalized_negative))})
dat_6 <- dat_6[order(dat_6$year, dat_6$weeks),]

# week 53 is odd as well, so lets get rid of it as well
dat_6 <- dat_6[dat_6$week != 53,]
dat_6 <- dat_6[!is.na(dat_6$week),]


#do we have censored data?
hist(dat_6$n, breaks = 100)
hist(dat_6$n_w, breaks = 100)
hist(dat_6$ton_neg, breaks=100)

# QUESTION: How does that check for censored data?

# check for unit roots (stationarity) with Augmented Dickey-Fowler test
require(tseries)
adf.test(dat_6$n) #non-stationary
adf.test(dat_6$n_w) #non-stationary
adf.test(dat_6$ton_neg)
# p-value is smaller than 0.01 => stationary time series

# check whether and if yes, which seasonality dominates the data
require(forecast)
findfrequency(dat_6$n) # monthly seasonality (seas = 1; weekly); 
findfrequency(dat_6$n_w) # monthly seasonality (seas = 1; weekly); 
findfrequency(dat_6$ton_neg) # monthly seasonality (seas = 1; weekly); 

#Build a time series
dat_6$n_ts <- ts(dat_6$n)
dat_6$n_w_ts <- ts(dat_6$n_w)
dat_6$ton_neg_ts <- ts(dat_6$ton_neg)

#smooth with monthly moving average (4 is rather arbitrary, but automated
# detection yields 59 which clearly is nonsense!) to see trends better
require(smooth)
dat_6$n_ts_sm <- sma(dat_6$n_ts, order = 4)$fitted
dat_6$n_w_ts_sm <- sma(dat_6$n_w_ts, order = 4)$fitted
dat_6$ton_neg_ts_sm <- sma(dat_6$ton_neg_ts, order = 4)$fitted

# create starting date of every week
dat_6$week <- as.Date(paste(dat_6$years, dat_6$weeks, 1, sep="-"), "%Y-%U-%u")

# illustrate peaks and slumps
#Salience
png(filename=paste("./Prototype_UK/Results/Graphs/timeline_6.png", sep=""), width=9, height=6, units="in", res=600)
plot(dat_6$week, dat_6$n_ts_sm, type = "l",xlab="Weeks",ylab="Number of Articles",
     main="commonwealth of nations")
abline(h = mean(dat_6$n_ts_sm))
abline(h = mean(dat_6$n_ts_sm)+sd(dat_6$n_ts_sm), lty = "dashed") #Standard Deviation lines
abline(h = mean(dat_6$n_ts_sm)-sd(dat_6$n_ts_sm), lty = "dashed")
dev.off()

#Tonality
png(filename=paste("./Prototype_UK/Results/Graphs/timeline_ton_6.png", sep=""), width=9, height=6, units="in", res=600)
plot(dat_6$week, dat_6$ton_neg_ts_sm, type = "l",xlab="Weeks",ylab="Number of Negative Articles",
     main="commonwealth of nations")
abline(h = mean(dat_6$ton_neg_ts_sm))
abline(h = mean(dat_6$ton_neg_ts_sm)+sd(dat_6$ton_neg_ts_sm), lty = "dashed") #Standard Deviation lines
abline(h = mean(dat_6$ton_neg_ts_sm)-sd(dat_6$ton_neg_ts_sm), lty = "dashed")
dev.off()

#Variable for peak and low times
#Salience
dat_6$peak <- 0
dat_6$peak[dat_6$n_ts_sm>mean(dat_6$n_ts_sm)+sd(dat_6$n_ts_sm)] <- 1
dat_6$peak[dat_6$n_ts_sm<mean(dat_6$n_ts_sm)-sd(dat_6$n_ts_sm)] <- -1
#Tonality
dat_6$peak_neg <- 0
dat_6$peak_neg[dat_6$ton_neg_ts_sm>mean(dat_6$ton_neg_ts_sm)+sd(dat_6$ton_neg_ts_sm)] <- 1
dat_6$peak_neg[dat_6$ton_neg_ts_sm<mean(dat_6$ton_neg_ts_sm)-sd(dat_6$ton_neg_ts_sm)] <- -1


#Entity-Identifier for merging
dat_6$entity_id <- 6

#Remove these variables: same names in dat_base (initial corpus); later we will merge them
dat_6$n <- NULL
dat_6$n_w <- NULL


#council of europe
#----------
dat_7 <- dat_base[dat_base$entity_id==7,]
require(plyr)
dat_7 <- ddply(dat_7, .(weeks, years), function (x) {
  data.frame(n = sum(x$n), n_w = sum(x$n_w), ton_neg=sum(x$tonality_verbalized_negative))})
dat_7 <- dat_7[order(dat_7$year, dat_7$weeks),]

# week 53 is odd as well, so lets get rid of it as well
dat_7 <- dat_7[dat_7$week != 53,]
dat_7 <- dat_7[!is.na(dat_7$week),]


#do we have censored data?
hist(dat_7$n, breaks = 100)
hist(dat_7$n_w, breaks = 100)
hist(dat_7$ton_neg, breaks=100)

# QUESTION: How does that check for censored data?

# check for unit roots (stationarity) with Augmented Dickey-Fowler test
require(tseries)
adf.test(dat_7$n)
adf.test(dat_7$n_w)
adf.test(dat_7$ton_neg)
# p-value is smaller than 0.01 => stationary time series

# check whether and if yes, which seasonality dominates the data
require(forecast)
findfrequency(dat_7$n) # monthly seasonality (seas = 21; 5 months); 
findfrequency(dat_7$n_w) # monthly seasonality (seas = 20; 5 months); 
findfrequency(dat_7$ton_neg) # monthly seasonality (seas = 1; weekly); 

#Build a time series
dat_7$n_ts <- ts(dat_7$n)
dat_7$n_w_ts <- ts(dat_7$n_w)
dat_7$ton_neg_ts <- ts(dat_7$ton_neg)

#smooth with monthly moving average (4 is rather arbitrary, but automated
# detection yields 59 which clearly is nonsense!) to see trends better
require(smooth)
dat_7$n_ts_sm <- sma(dat_7$n_ts, order = 4)$fitted
dat_7$n_w_ts_sm <- sma(dat_7$n_w_ts, order = 4)$fitted
dat_7$ton_neg_ts_sm <- sma(dat_7$ton_neg_ts, order = 4)$fitted

# create starting date of every week
dat_7$week <- as.Date(paste(dat_7$years, dat_7$weeks, 1, sep="-"), "%Y-%U-%u")

# illustrate peaks and slumps
#Salience
# png(filename=paste("./Prototype_UK/Results/Graphs/timeline_7.png", sep=""), width=9, height=6, units="in", res=600)
plot(dat_7$week, dat_7$n_ts_sm, type = "l",xlab="Weeks",ylab="Number of Articles",
     main="council of europe")
abline(h = mean(dat_7$n_ts_sm))
abline(h = mean(dat_7$n_ts_sm)+sd(dat_7$n_ts_sm), lty = "dashed") #Standard Deviation lines
abline(h = mean(dat_7$n_ts_sm)-sd(dat_7$n_ts_sm), lty = "dashed")
dev.off()

#Tonality
# png(filename=paste("./Prototype_UK/Results/Graphs/timeline_ton_7.png", sep=""), width=9, height=6, units="in", res=600)
plot(dat_7$week, dat_7$ton_neg_ts_sm, type = "l",xlab="Weeks",ylab="Number of Negative Articles",
     main="council of europe")
abline(h = mean(dat_7$ton_neg_ts_sm))
abline(h = mean(dat_7$ton_neg_ts_sm)+sd(dat_7$ton_neg_ts_sm), lty = "dashed") #Standard Deviation lines
abline(h = mean(dat_7$ton_neg_ts_sm)-sd(dat_7$ton_neg_ts_sm), lty = "dashed")
dev.off()

#Variable for peak and low times
#Salience
dat_7$peak <- 0
dat_7$peak[dat_7$n_ts_sm>mean(dat_7$n_ts_sm)+sd(dat_7$n_ts_sm)] <- 1
dat_7$peak[dat_7$n_ts_sm<mean(dat_7$n_ts_sm)-sd(dat_7$n_ts_sm)] <- -1
#Tonality
dat_7$peak_neg <- 0
dat_7$peak_neg[dat_7$ton_neg_ts_sm>mean(dat_7$ton_neg_ts_sm)+sd(dat_7$ton_neg_ts_sm)] <- 1
dat_7$peak_neg[dat_7$ton_neg_ts_sm<mean(dat_7$ton_neg_ts_sm)-sd(dat_7$ton_neg_ts_sm)] <- -1

#Entity-Identifier for merging
dat_7$entity_id <- 7

#Remove these variables: same names in dat_base (initial corpus); later we will merge them
dat_7$n <- NULL
dat_7$n_w <- NULL

#european parliament
#----------
dat_17 <- dat_base[dat_base$entity_id==17,]
require(plyr)
dat_17 <- ddply(dat_17, .(weeks, years), function (x) {
  data.frame(n = sum(x$n), n_w = sum(x$n_w), ton_neg=sum(x$tonality_verbalized_negative))})
dat_17 <- dat_17[order(dat_17$year, dat_17$weeks),]

# week 53 is odd as well, so lets get rid of it as well
dat_17 <- dat_17[dat_17$week != 53,]
dat_17 <- dat_17[!is.na(dat_17$week),]


#do we have censored data?
hist(dat_17$n, breaks = 100)
hist(dat_17$n_w, breaks = 100)
hist(dat_17$ton_neg, breaks=100)

# QUESTION: How does that check for censored data?

# check for unit roots (stationarity) with Augmented Dickey-Fowler test
require(tseries)
adf.test(dat_17$n)
adf.test(dat_17$n_w)
adf.test(dat_17$ton_neg)
# p-value is smaller than 0.01 => stationary time series

# check whether and if yes, which seasonality dominates the data
require(forecast)
findfrequency(dat_17$n) # monthly seasonality (seas = 1; weekly); 
findfrequency(dat_17$n_w) # monthly seasonality (seas = 1; weekly); 
findfrequency(dat_17$ton_neg) # monthly seasonality (seas = 5; +/- monthly); 

#Build a time series
dat_17$n_ts <- ts(dat_17$n)
dat_17$n_w_ts <- ts(dat_17$n_w)
dat_17$ton_neg_ts <- ts(dat_17$ton_neg)

#smooth with monthly moving average (4 is rather arbitrary, but automated
# detection yields 59 which clearly is nonsense!) to see trends better
require(smooth)
dat_17$n_ts_sm <- sma(dat_17$n_ts, order = 4)$fitted
dat_17$n_w_ts_sm <- sma(dat_17$n_w_ts, order = 4)$fitted
dat_17$ton_neg_ts_sm <- sma(dat_17$ton_neg_ts, order = 4)$fitted

# create starting date of every week
dat_17$week <- as.Date(paste(dat_17$years, dat_17$weeks, 1, sep="-"), "%Y-%U-%u")

# illustrate peaks and slumps
#Salience
png(filename=paste("./Prototype_UK/Results/Graphs/timeline_17.png", sep=""), width=9, height=6, units="in", res=600)
plot(dat_17$week, dat_17$n_ts_sm, type = "l",xlab="Weeks",ylab="Number of Articles",
     main="european parliament")
abline(h = mean(dat_17$n_ts_sm))
abline(h = mean(dat_17$n_ts_sm)+sd(dat_17$n_ts_sm), lty = "dashed") #Standard Deviation lines
abline(h = mean(dat_17$n_ts_sm)-sd(dat_17$n_ts_sm), lty = "dashed")
dev.off()

#Tonality
png(filename=paste("./Prototype_UK/Results/Graphs/timeline_ton_17.png", sep=""), width=9, height=6, units="in", res=600)
plot(dat_17$week, dat_17$ton_neg_ts_sm, type = "l",xlab="Weeks",ylab="Number of Negative Articles",
     main="european parliament")
abline(h = mean(dat_17$ton_neg_ts_sm))
abline(h = mean(dat_17$ton_neg_ts_sm)+sd(dat_17$ton_neg_ts_sm), lty = "dashed") #Standard Deviation lines
abline(h = mean(dat_17$ton_neg_ts_sm)-sd(dat_17$ton_neg_ts_sm), lty = "dashed")
dev.off()

# The two lines together (no secondary axis yet)
plot(dat_17$week, dat_17$n_ts_sm[], type = "l",xlab="Weeks",ylab="Number of Articles",
  main="european parliament")
lines(dat_17$week, dat_17$ton_neg_ts_sm, type = "l",xlab="Weeks",ylab="Number of Negative Articles",
     main="european parliament")

lines(x,y2,col="green")

#Variable for peak and low times
#Salience
dat_17$peak <- 0
dat_17$peak[dat_17$n_ts_sm>mean(dat_17$n_ts_sm)+sd(dat_17$n_ts_sm)] <- 1
dat_17$peak[dat_17$n_ts_sm<mean(dat_17$n_ts_sm)-sd(dat_17$n_ts_sm)] <- -1
#Tonality
dat_17$peak_neg <- 0
dat_17$peak_neg[dat_17$ton_neg_ts_sm>mean(dat_17$ton_neg_ts_sm)+sd(dat_17$ton_neg_ts_sm)] <- 1
dat_17$peak_neg[dat_17$ton_neg_ts_sm<mean(dat_17$ton_neg_ts_sm)-sd(dat_17$ton_neg_ts_sm)] <- -1


#Entity-Identifier for merging
dat_17$entity_id <- 17

#Remove these variables: same names in dat_base (initial corpus); later we will merge them
dat_17$n <- NULL
dat_17$n_w <- NULL   


#francophone parliamentary assembly
#----------
dat_26 <- dat_base[dat_base$entity_id==26,]
require(plyr)
dat_26 <- ddply(dat_26, .(weeks, years), function (x) {
  data.frame(n = sum(x$n), n_w = sum(x$n_w), ton_neg=sum(x$tonality_verbalized_negative))})
dat_26 <- dat_26[order(dat_26$year, dat_26$weeks),]

# week 53 is odd as well, so lets get rid of it as well
dat_26 <- dat_26[dat_26$week != 53,]
dat_26 <- dat_26[!is.na(dat_26$week),]


#do we have censored data?
hist(dat_26$n, breaks = 100)
hist(dat_26$n_w, breaks = 100)
hist(dat_26$ton_neg, breaks=100)

# QUESTION: How does that check for censored data?

# check for unit roots (stationarity) with Augmented Dickey-Fowler test
require(tseries)
adf.test(dat_26$n)
adf.test(dat_26$n_w)
adf.test(dat_26$ton_neg)
# p-value is smaller than 0.01 => stationary time series

# check whether and if yes, which seasonality dominates the data
require(forecast)
findfrequency(dat_26$n) # monthly seasonality (seas = 1; weekly); 
findfrequency(dat_26$n_w) # monthly seasonality (seas = 1; weekly); 
findfrequency(dat_26$ton_neg) # monthly seasonality (seas = 1; weekly); 

#Build a time series
dat_26$n_ts <- ts(dat_26$n)
dat_26$n_w_ts <- ts(dat_26$n_w)
dat_26$ton_neg_ts <- ts(dat_26$ton_neg)

#smooth with monthly moving average (4 is rather arbitrary, but automated
# detection yields 59 which clearly is nonsense!) to see trends better
require(smooth)
dat_26$n_ts_sm <- sma(dat_26$n_ts, order = 4)$fitted
dat_26$n_w_ts_sm <- sma(dat_26$n_w_ts, order = 4)$fitted
dat_26$ton_neg_ts_sm <- sma(dat_26$ton_neg_ts, order = 4)$fitted

# create starting date of every week
dat_26$week <- as.Date(paste(dat_26$years, dat_26$weeks, 1, sep="-"), "%Y-%U-%u")

# illustrate peaks and slumps
#Salience
png(filename=paste("./Prototype_UK/Results/Graphs/timeline_26.png", sep=""), width=9, height=6, units="in", res=600)
plot(dat_26$week, dat_26$n_ts_sm, type = "l",xlab="Weeks",ylab="Number of Articles",
     main="francophone parliamentary assembly")
abline(h = mean(dat_26$n_ts_sm))
abline(h = mean(dat_26$n_ts_sm)+sd(dat_26$n_ts_sm), lty = "dashed") #Standard Deviation lines
abline(h = mean(dat_26$n_ts_sm)-sd(dat_26$n_ts_sm), lty = "dashed")
dev.off()

#Tonality
png(filename=paste("./Prototype_UK/Results/Graphs/timeline_ton_26.png", sep=""), width=9, height=6, units="in", res=600)
plot(dat_26$week, dat_26$ton_neg_ts_sm, type = "l",xlab="Weeks",ylab="Number of Negative Articles",
     main="francophone parliamentary assembly")
abline(h = mean(dat_26$ton_neg_ts_sm))
abline(h = mean(dat_26$ton_neg_ts_sm)+sd(dat_26$ton_neg_ts_sm), lty = "dashed") #Standard Deviation lines
abline(h = mean(dat_26$ton_neg_ts_sm)-sd(dat_26$ton_neg_ts_sm), lty = "dashed")
dev.off()

plot(dat_26$week, dat_26$n_ts_sm, type = "l",xlab="Weeks",ylab="Number of Articles",
     main="francophone parliamentary assembly")
lines(dat_26$week, dat_26$ton_neg_ts_sm, type = "l",xlab="Weeks",ylab="Number of Negative Articles",
      main="francophone parliamentary assembly")

#Variable for peak and low times
#Salience
dat_26$peak <- 0
dat_26$peak[dat_26$n_ts_sm>mean(dat_26$n_ts_sm)+sd(dat_26$n_ts_sm)] <- 1
dat_26$peak[dat_26$n_ts_sm<mean(dat_26$n_ts_sm)-sd(dat_26$n_ts_sm)] <- -1
#Tonality
dat_26$peak_neg <- 0
dat_26$peak_neg[dat_26$ton_neg_ts_sm>mean(dat_26$ton_neg_ts_sm)+sd(dat_26$ton_neg_ts_sm)] <- 1
dat_26$peak_neg[dat_26$ton_neg_ts_sm<mean(dat_26$ton_neg_ts_sm)-sd(dat_26$ton_neg_ts_sm)] <- -1


#Entity-Identifier for merging
dat_26$entity_id <- 26

#Remove these variables: same names in dat_base (initial corpus); later we will merge them
dat_26$n <- NULL
dat_26$n_w <- NULL

#inter-parliamentary union
#----------
dat_36 <- dat_base[dat_base$entity_id==36,]
require(plyr)
dat_36 <- ddply(dat_36, .(weeks, years), function (x) {
  data.frame(n = sum(x$n), n_w = sum(x$n_w), ton_neg=sum(x$tonality_verbalized_negative))})
dat_36 <- dat_36[order(dat_36$year, dat_36$weeks),]

# week 53 is odd as well, so lets get rid of it as well
dat_36 <- dat_36[dat_36$week != 53,]
dat_36 <- dat_36[!is.na(dat_36$week),]

#do we have censored data?
hist(dat_36$n, breaks = 100)
hist(dat_36$n_w, breaks = 100)
hist(dat_36$ton_neg, breaks=100)

# QUESTION: How does that check for censored data?

# check for unit roots (stationarity) with Augmented Dickey-Fowler test
require(tseries)
adf.test(dat_36$n)
adf.test(dat_36$n_w)
adf.test(dat_36$ton_neg)
# p-value is smaller than 0.01 => stationary time series

# check whether and if yes, which seasonality dominates the data
require(forecast)
findfrequency(dat_36$n) # monthly seasonality (seas = 6; 1.5 monthly); 
findfrequency(dat_36$n_w) # monthly seasonality (seas = 6; 1.5 monthly); 
findfrequency(dat_36$ton_neg) # monthly seasonality (seas = 1; weekly); 

#Build a time series
dat_36$n_ts <- ts(dat_36$n)
dat_36$n_w_ts <- ts(dat_36$n_w)
dat_36$ton_neg_ts <- ts(dat_36$ton_neg)

#smooth with monthly moving average (4 is rather arbitrary, but automated
# detection yields 59 which clearly is nonsense!) to see trends better
require(smooth)
dat_36$n_ts_sm <- sma(dat_36$n_ts, order = 4)$fitted
dat_36$n_w_ts_sm <- sma(dat_36$n_w_ts, order = 4)$fitted
dat_36$ton_neg_ts_sm <- sma(dat_36$ton_neg_ts, order = 4)$fitted

# create starting date of every week
dat_36$week <- as.Date(paste(dat_36$years, dat_36$weeks, 1, sep="-"), "%Y-%U-%u")

# illustrate peaks and slumps
#Salience
png(filename=paste("./Prototype_UK/Results/Graphs/timeline_36.png", sep=""), width=9, height=6, units="in", res=600)
plot(dat_36$week, dat_36$n_ts_sm, type = "l",xlab="Weeks",ylab="Number of Articles",
     main="inter-parliamentary union")
abline(h = mean(dat_36$n_ts_sm))
abline(h = mean(dat_36$n_ts_sm)+sd(dat_36$n_ts_sm), lty = "dashed") #Standard Deviation lines
abline(h = mean(dat_36$n_ts_sm)-sd(dat_36$n_ts_sm), lty = "dashed")
dev.off()

#Tonality
png(filename=paste("./Prototype_UK/Results/Graphs/timeline_ton_36.png", sep=""), width=9, height=6, units="in", res=600)
plot(dat_36$week, dat_36$ton_neg_ts_sm, type = "l",xlab="Weeks",ylab="Number of Negative Articles",
     main="inter-parliamentary union")
abline(h = mean(dat_36$ton_neg_ts_sm))
abline(h = mean(dat_36$ton_neg_ts_sm)+sd(dat_36$ton_neg_ts_sm), lty = "dashed") #Standard Deviation lines
abline(h = mean(dat_36$ton_neg_ts_sm)-sd(dat_36$ton_neg_ts_sm), lty = "dashed")
dev.off()

plot(dat_36$week, dat_36$n_ts_sm, type = "l",xlab="Weeks",ylab="Number of Articles",
     main="inter-parliamentary union")
lines(dat_36$week, dat_36$ton_neg_ts_sm, type = "l",xlab="Weeks",ylab="Number of Negative Articles",
      main="inter-parliamentary union")


#Variable for peak and low times
#Salience
dat_36$peak <- 0
dat_36$peak[dat_36$n_ts_sm>mean(dat_36$n_ts_sm)+sd(dat_36$n_ts_sm)] <- 1
dat_36$peak[dat_36$n_ts_sm<mean(dat_36$n_ts_sm)-sd(dat_36$n_ts_sm)] <- -1
#Tonality
dat_36$peak_neg <- 0
dat_36$peak_neg[dat_36$ton_neg_ts_sm>mean(dat_36$ton_neg_ts_sm)+sd(dat_36$ton_neg_ts_sm)] <- 1
dat_36$peak_neg[dat_36$ton_neg_ts_sm<mean(dat_36$ton_neg_ts_sm)-sd(dat_36$ton_neg_ts_sm)] <- -1


#Entity-Identifier for merging
dat_36$entity_id <- 36

#Remove these variables: same names in dat_base (initial corpus); later we will merge them
dat_36$n <- NULL
dat_36$n_w <- NULL

#international criminal court
#----------
dat_41 <- dat_base[dat_base$entity_id==41,]
require(plyr)
dat_41 <- ddply(dat_41, .(weeks, years), function (x) {
  data.frame(n = sum(x$n), n_w = sum(x$n_w), ton_neg=sum(x$tonality_verbalized_negative))})
dat_41 <- dat_41[order(dat_41$year, dat_41$weeks),]

# week 53 is odd as well, so lets get rid of it as well
dat_41 <- dat_41[dat_41$week != 53,]
dat_41 <- dat_41[!is.na(dat_41$week),]

#do we have censored data?
hist(dat_41$n, breaks = 100)
hist(dat_41$n_w, breaks = 100)
hist(dat_41$ton_neg, breaks=100)

# QUESTION: How does that check for censored data?

# check for unit roots (stationarity) with Augmented Dickey-Fowler test
require(tseries)
adf.test(dat_41$n)
adf.test(dat_41$n_w)
adf.test(dat_41$ton_neg)
# p-value is smaller than 0.01 => stationary time series

# check whether and if yes, which seasonality dominates the data
require(forecast)
findfrequency(dat_41$n) # monthly seasonality (seas = 1; weekly); 
findfrequency(dat_41$n_w) # monthly seasonality (seas = 1; weekly); 
findfrequency(dat_41$ton_neg) # monthly seasonality (seas = 7; 1.5 monthly); 

#Build a time series
dat_41$n_ts <- ts(dat_41$n)
dat_41$n_w_ts <- ts(dat_41$n_w)
dat_41$ton_neg_ts <- ts(dat_41$ton_neg)

#smooth with monthly moving average (4 is rather arbitrary, but automated
# detection yields 59 which clearly is nonsense!) to see trends better
require(smooth)
dat_41$n_ts_sm <- sma(dat_41$n_ts, order = 4)$fitted
dat_41$n_w_ts_sm <- sma(dat_41$n_w_ts, order = 4)$fitted
dat_41$ton_neg_ts_sm <- sma(dat_41$ton_neg_ts, order = 4)$fitted

# create starting date of every week
dat_41$week <- as.Date(paste(dat_41$years, dat_41$weeks, 1, sep="-"), "%Y-%U-%u")

# illustrate peaks and slumps
#Salience
png(filename=paste("./Prototype_UK/Results/Graphs/timeline_41.png", sep=""), width=9, height=6, units="in", res=600)
plot(dat_41$week, dat_41$n_ts_sm, type = "l",xlab="Weeks",ylab="Number of Articles",
     main="international criminal court")
abline(h = mean(dat_41$n_ts_sm))
abline(h = mean(dat_41$n_ts_sm)+sd(dat_41$n_ts_sm), lty = "dashed") #Standard Deviation lines
abline(h = mean(dat_41$n_ts_sm)-sd(dat_41$n_ts_sm), lty = "dashed")
dev.off()

#Tonality
png(filename=paste("./Prototype_UK/Results/Graphs/timeline_ton_41.png", sep=""), width=9, height=6, units="in", res=600)
plot(dat_41$week, dat_41$ton_neg_ts_sm, type = "l",xlab="Weeks",ylab="Number of Negative Articles",
     main="international criminal court")
abline(h = mean(dat_41$ton_neg_ts_sm))
abline(h = mean(dat_41$ton_neg_ts_sm)+sd(dat_41$ton_neg_ts_sm), lty = "dashed") #Standard Deviation lines
abline(h = mean(dat_41$ton_neg_ts_sm)-sd(dat_41$ton_neg_ts_sm), lty = "dashed")
dev.off()

plot(dat_41$week, dat_41$n_ts_sm, type = "l",xlab="Weeks",ylab="Number of Articles",
     main="international criminal court")
lines(dat_41$week, dat_41$ton_neg_ts_sm, type = "l",xlab="Weeks",ylab="Number of Negative Articles",
      main="international criminal court")

#Variable for peak and low times
#Salience
dat_41$peak <- 0
dat_41$peak[dat_41$n_ts_sm>mean(dat_41$n_ts_sm)+sd(dat_41$n_ts_sm)] <- 1
dat_41$peak[dat_41$n_ts_sm<mean(dat_41$n_ts_sm)-sd(dat_41$n_ts_sm)] <- -1
#Tonality
dat_41$peak_neg <- 0
dat_41$peak_neg[dat_41$ton_neg_ts_sm>mean(dat_41$ton_neg_ts_sm)+sd(dat_41$ton_neg_ts_sm)] <- 1
dat_41$peak_neg[dat_41$ton_neg_ts_sm<mean(dat_41$ton_neg_ts_sm)-sd(dat_41$ton_neg_ts_sm)] <- -1


#Entity-Identifier for merging
dat_41$entity_id <- 41

#Remove these variables: same names in dat_base (initial corpus); later we will merge them
dat_41$n <- NULL
dat_41$n_w <- NULL

#international labor organization
#----------
dat_45 <- dat_base[dat_base$entity_id==45,]
require(plyr)
dat_45 <- ddply(dat_45, .(weeks, years), function (x) {
  data.frame(n = sum(x$n), n_w = sum(x$n_w), ton_neg=sum(x$tonality_verbalized_negative))})
dat_45 <- dat_45[order(dat_45$year, dat_45$weeks),]

# week 53 is odd as well, so lets get rid of it as well
dat_45 <- dat_45[dat_45$week != 53,]
dat_45 <- dat_45[!is.na(dat_45$week),]

#do we have censored data?
hist(dat_45$n, breaks = 100)
hist(dat_45$n_w, breaks = 100)
hist(dat_45$ton_neg, breaks=100)

# QUESTION: How does that check for censored data?

# check for unit roots (stationarity) with Augmented Dickey-Fowler test
require(tseries)
adf.test(dat_45$n)
adf.test(dat_45$n_w)
adf.test(dat_45$ton_neg)
# p-value is smaller than 0.01 => stationary time series

# check whether and if yes, which seasonality dominates the data
require(forecast)
findfrequency(dat_45$n) # monthly seasonality (seas = 1; weekly); 
findfrequency(dat_45$n_w) # monthly seasonality (seas = 1; weekly); 
findfrequency(dat_45$ton_neg) # monthly seasonality (seas = 4; monthly); 

#Build a time series
dat_45$n_ts <- ts(dat_45$n)
dat_45$n_w_ts <- ts(dat_45$n_w)
dat_45$ton_neg_ts <- ts(dat_45$ton_neg)

#smooth with monthly moving average (4 is rather arbitrary, but automated
# detection yields 59 which clearly is nonsense!) to see trends better
require(smooth)
dat_45$n_ts_sm <- sma(dat_45$n_ts, order = 4)$fitted
dat_45$n_w_ts_sm <- sma(dat_45$n_w_ts, order = 4)$fitted
dat_45$ton_neg_ts_sm <- sma(dat_45$ton_neg_ts, order = 4)$fitted

# create starting date of every week
dat_45$week <- as.Date(paste(dat_45$years, dat_45$weeks, 1, sep="-"), "%Y-%U-%u")

# illustrate peaks and slumps
#Salience
png(filename=paste("./Prototype_UK/Results/Graphs/timeline_45.png", sep=""), width=9, height=6, units="in", res=600)
plot(dat_45$week, dat_45$n_ts_sm, type = "l",xlab="Weeks",ylab="Number of Articles",
     main="international labor organization")
abline(h = mean(dat_45$n_ts_sm))
abline(h = mean(dat_45$n_ts_sm)+sd(dat_45$n_ts_sm), lty = "dashed") #Standard Deviation lines
abline(h = mean(dat_45$n_ts_sm)-sd(dat_45$n_ts_sm), lty = "dashed")
dev.off()

#Tonality
png(filename=paste("./Prototype_UK/Results/Graphs/timeline_ton_45.png", sep=""), width=9, height=6, units="in", res=600)
plot(dat_45$week, dat_45$ton_neg_ts_sm, type = "l",xlab="Weeks",ylab="Number of Negative Articles",
     main="international labor organization")
abline(h = mean(dat_45$ton_neg_ts_sm))
abline(h = mean(dat_45$ton_neg_ts_sm)+sd(dat_45$ton_neg_ts_sm), lty = "dashed") #Standard Deviation lines
abline(h = mean(dat_45$ton_neg_ts_sm)-sd(dat_45$ton_neg_ts_sm), lty = "dashed")
dev.off()

plot(dat_45$week, dat_45$n_ts_sm, type = "l",xlab="Weeks",ylab="Number of Articles",
     main="international labor organization")
lines(dat_45$week, dat_45$ton_neg_ts_sm, type = "l",xlab="Weeks",ylab="Number of Negative Articles",
      main="international labor organization")

#Variable for peak and low times
#Salience
dat_45$peak <- 0
dat_45$peak[dat_45$n_ts_sm>mean(dat_45$n_ts_sm)+sd(dat_45$n_ts_sm)] <- 1
dat_45$peak[dat_45$n_ts_sm<mean(dat_45$n_ts_sm)-sd(dat_45$n_ts_sm)] <- -1
#Tonality
dat_45$peak_neg <- 0
dat_45$peak_neg[dat_45$ton_neg_ts_sm>mean(dat_45$ton_neg_ts_sm)+sd(dat_45$ton_neg_ts_sm)] <- 1
dat_45$peak_neg[dat_45$ton_neg_ts_sm<mean(dat_45$ton_neg_ts_sm)-sd(dat_45$ton_neg_ts_sm)] <- -1


#Entity-Identifier for merging
dat_45$entity_id <- 45

#Remove these variables: same names in dat_base (initial corpus); later we will merge them
dat_45$n <- NULL
dat_45$n_w <- NULL

#international whaling commission
#----------
dat_49 <- dat_base[dat_base$entity_id==49,]
require(plyr)
dat_49 <- ddply(dat_49, .(weeks, years), function (x) {
  data.frame(n = sum(x$n), n_w = sum(x$n_w), ton_neg=sum(x$tonality_verbalized_negative))})
dat_49 <- dat_49[order(dat_49$year, dat_49$weeks),]

# week 53 is odd as well, so lets get rid of it as well
dat_49 <- dat_49[dat_49$week != 53,]
dat_49 <- dat_49[!is.na(dat_49$week),]


#do we have censored data?
hist(dat_49$n, breaks = 100)
hist(dat_49$n_w, breaks = 100)
hist(dat_49$ton_neg, breaks=100)

# QUESTION: How does that check for censored data?

# check for unit roots (stationarity) with Augmented Dickey-Fowler test
require(tseries)
adf.test(dat_49$n)
adf.test(dat_49$n_w)
adf.test(dat_49$ton_neg)
# p-value is smaller than 0.01 => stationary time series

# check whether and if yes, which seasonality dominates the data
require(forecast)
findfrequency(dat_49$n) # monthly seasonality (seas = 1; weekly); 
findfrequency(dat_49$n_w) # monthly seasonality (seas = 1; weekly); 
findfrequency(dat_49$ton_neg) # monthly seasonality (seas = 1; weekly); 

#Build a time series
dat_49$n_ts <- ts(dat_49$n)
dat_49$n_w_ts <- ts(dat_49$n_w)
dat_49$ton_neg_ts <- ts(dat_49$ton_neg)

#smooth with monthly moving average (4 is rather arbitrary, but automated
# detection yields 59 which clearly is nonsense!) to see trends better
require(smooth)
dat_49$n_ts_sm <- sma(dat_49$n_ts, order = 4)$fitted
dat_49$n_w_ts_sm <- sma(dat_49$n_w_ts, order = 4)$fitted
dat_49$ton_neg_ts_sm <- sma(dat_49$ton_neg_ts, order = 4)$fitted

# create starting date of every week
dat_49$week <- as.Date(paste(dat_49$years, dat_49$weeks, 1, sep="-"), "%Y-%U-%u")

# illustrate peaks and slumps
#Salience
png(filename=paste("./Prototype_UK/Results/Graphs/timeline_49.png", sep=""), width=9, height=6, units="in", res=600)
plot(dat_49$week, dat_49$n_ts_sm, type = "l",xlab="Weeks",ylab="Number of Articles",
     main="international whaling commission")
abline(h = mean(dat_49$n_ts_sm))
abline(h = mean(dat_49$n_ts_sm)+sd(dat_49$n_ts_sm), lty = "dashed") #Standard Deviation lines
abline(h = mean(dat_49$n_ts_sm)-sd(dat_49$n_ts_sm), lty = "dashed")
dev.off()

#Tonality
png(filename=paste("./Prototype_UK/Results/Graphs/timeline_ton_49.png", sep=""), width=9, height=6, units="in", res=600)
plot(dat_49$week, dat_49$ton_neg_ts_sm, type = "l",xlab="Weeks",ylab="Number of Negative Articles",
     main="international whaling commission")
abline(h = mean(dat_49$ton_neg_ts_sm))
abline(h = mean(dat_49$ton_neg_ts_sm)+sd(dat_49$ton_neg_ts_sm), lty = "dashed") #Standard Deviation lines
abline(h = mean(dat_49$ton_neg_ts_sm)-sd(dat_49$ton_neg_ts_sm), lty = "dashed")
dev.off()


plot(dat_49$week, dat_49$n_ts_sm, type = "l",xlab="Weeks",ylab="Number of Articles",
     main="international whaling commission")
lines(dat_49$week, dat_49$ton_neg_ts_sm, type = "l",ylab="Number of Negative Articles")


#Variable for peak and low times
#Salience
dat_49$peak <- 0
dat_49$peak[dat_49$n_ts_sm>mean(dat_49$n_ts_sm)+sd(dat_49$n_ts_sm)] <- 1
dat_49$peak[dat_49$n_ts_sm<mean(dat_49$n_ts_sm)-sd(dat_49$n_ts_sm)] <- -1
#Tonality
dat_49$peak_neg <- 0
dat_49$peak_neg[dat_49$ton_neg_ts_sm>mean(dat_49$ton_neg_ts_sm)+sd(dat_49$ton_neg_ts_sm)] <- 1
dat_49$peak_neg[dat_49$ton_neg_ts_sm<mean(dat_49$ton_neg_ts_sm)-sd(dat_49$ton_neg_ts_sm)] <- -1


#Entity-Identifier for merging
dat_49$entity_id <- 49

#Remove these variables: same names in dat_base (initial corpus); later we will merge them
dat_49$n <- NULL
dat_49$n_w <- NULL

#joint parliamentary assembly africa - caribbean - pacific - european union
#----------
dat_57 <- dat_base[dat_base$entity_id==57,]
require(plyr)
dat_57 <- ddply(dat_57, .(weeks, years), function (x) {
  data.frame(n = sum(x$n), n_w = sum(x$n_w), ton_neg=sum(x$tonality_verbalized_negative))})
dat_57 <- dat_57[order(dat_57$year, dat_57$weeks),]

# week 53 is odd as well, so lets get rid of it as well
dat_57 <- dat_57[dat_57$week != 53,]
dat_57 <- dat_57[!is.na(dat_57$week),]


#do we have censored data?
hist(dat_57$n, breaks = 100)
hist(dat_57$n_w, breaks = 100)
hist(dat_57$ton_neg, breaks=100)

# QUESTION: How does that check for censored data?

# check for unit roots (stationarity) with Augmented Dickey-Fowler test
require(tseries)
adf.test(dat_57$n)
adf.test(dat_57$n_w)
adf.test(dat_57$ton_neg) #non-stationary
# p-value is smaller than 0.01 => stationary time series

# check whether and if yes, which seasonality dominates the data
require(forecast)
findfrequency(dat_57$n) # monthly seasonality (seas = 1; weekly); 
findfrequency(dat_57$n_w) # monthly seasonality (seas = 7; 1.5 monthly); 
findfrequency(dat_57$ton_neg) # monthly seasonality (seas = 1; weekly); 

#Build a time series
dat_57$n_ts <- ts(dat_57$n)
dat_57$n_w_ts <- ts(dat_57$n_w)
dat_57$ton_neg_ts <- ts(dat_57$ton_neg)

#smooth with monthly moving average (4 is rather arbitrary, but automated
# detection yields 59 which clearly is nonsense!) to see trends better
require(smooth)
dat_57$n_ts_sm <- sma(dat_57$n_ts, order = 4)$fitted
dat_57$n_w_ts_sm <- sma(dat_57$n_w_ts, order = 4)$fitted
dat_57$ton_neg_ts_sm <- sma(dat_57$ton_neg_ts, order = 4)$fitted

# create starting date of every week
dat_57$week <- as.Date(paste(dat_57$years, dat_57$weeks, 1, sep="-"), "%Y-%U-%u")

# illustrate peaks and slumps
#Salience
png(filename=paste("./Prototype_UK/Results/Graphs/timeline_57.png", sep=""), width=9, height=6, units="in", res=600)
plot(dat_57$week, dat_57$n_ts_sm, type = "l",xlab="Weeks",ylab="Number of Articles",
     main="joint parliamentary assembly africa - caribbean - pacific - european union")
abline(h = mean(dat_57$n_ts_sm))
abline(h = mean(dat_57$n_ts_sm)+sd(dat_57$n_ts_sm), lty = "dashed") #Standard Deviation lines
abline(h = mean(dat_57$n_ts_sm)-sd(dat_57$n_ts_sm), lty = "dashed")
dev.off()

#Tonality
png(filename=paste("./Prototype_UK/Results/Graphs/timeline_ton_57.png", sep=""), width=9, height=6, units="in", res=600)
plot(dat_57$week, dat_57$ton_neg_ts_sm, type = "l",xlab="Weeks",ylab="Number of Negative Articles",
     main="joint parliamentary assembly africa - caribbean - pacific - european union")
abline(h = mean(dat_57$ton_neg_ts_sm))
abline(h = mean(dat_57$ton_neg_ts_sm)+sd(dat_57$ton_neg_ts_sm), lty = "dashed") #Standard Deviation lines
abline(h = mean(dat_57$ton_neg_ts_sm)-sd(dat_57$ton_neg_ts_sm), lty = "dashed")
dev.off()

#Variable for peak and low times
#Salience
dat_57$peak <- 0
dat_57$peak[dat_57$n_ts_sm>mean(dat_57$n_ts_sm)+sd(dat_57$n_ts_sm)] <- 1
dat_57$peak[dat_57$n_ts_sm<mean(dat_57$n_ts_sm)-sd(dat_57$n_ts_sm)] <- -1
#Tonality
dat_57$peak_neg <- 0
dat_57$peak_neg[dat_57$ton_neg_ts_sm>mean(dat_57$ton_neg_ts_sm)+sd(dat_57$ton_neg_ts_sm)] <- 1
dat_57$peak_neg[dat_57$ton_neg_ts_sm<mean(dat_57$ton_neg_ts_sm)-sd(dat_57$ton_neg_ts_sm)] <- -1


#Entity-Identifier for merging
dat_57$entity_id <- 57

#Remove these variables: same names in dat_base (initial corpus); later we will merge them
dat_57$n <- NULL
dat_57$n_w <- NULL

#organization for economic cooperation & development
#----------
dat_62 <- dat_base[dat_base$entity_id==62,]
require(plyr)
dat_62 <- ddply(dat_62, .(weeks, years), function (x) {
  data.frame(n = sum(x$n), n_w = sum(x$n_w), ton_neg=sum(x$tonality_verbalized_negative))})
dat_62 <- dat_62[order(dat_62$year, dat_62$weeks),]

# week 53 is odd as well, so lets get rid of it as well
dat_62 <- dat_62[dat_62$week != 53,]
dat_62 <- dat_62[!is.na(dat_62$week),]

#do we have censored data?
hist(dat_62$n, breaks = 100)
hist(dat_62$n_w, breaks = 100)
hist(dat_62$ton_neg, breaks=100)

# QUESTION: How does that check for censored data?

# check for unit roots (stationarity) with Augmented Dickey-Fowler test
require(tseries)
adf.test(dat_62$n)
adf.test(dat_62$n_w)
adf.test(dat_62$ton_neg)
# p-value is smaller than 0.01 => stationary time series

# check whether and if yes, which seasonality dominates the data
require(forecast)
findfrequency(dat_62$n) # monthly seasonality (seas = 13; 3-monthly); 
findfrequency(dat_62$n_w) # monthly seasonality (seas = 13; 3-monthly); 
findfrequency(dat_62$ton_neg) # monthly seasonality (seas = 13; 3-monthly); 

#Build a time series
dat_62$n_ts <- ts(dat_62$n)
dat_62$n_w_ts <- ts(dat_62$n_w)
dat_62$ton_neg_ts <- ts(dat_62$ton_neg)

#smooth with monthly moving average (4 is rather arbitrary, but automated
# detection yields 59 which clearly is nonsense!) to see trends better
require(smooth)
dat_62$n_ts_sm <- sma(dat_62$n_ts, order = 4)$fitted
dat_62$n_w_ts_sm <- sma(dat_62$n_w_ts, order = 4)$fitted
dat_62$ton_neg_ts_sm <- sma(dat_62$ton_neg_ts, order = 4)$fitted

# create starting date of every week
dat_62$week <- as.Date(paste(dat_62$years, dat_62$weeks, 1, sep="-"), "%Y-%U-%u")

# illustrate peaks and slumps
#Salience
png(filename=paste("./Prototype_UK/Results/Graphs/timeline_62.png", sep=""), width=9, height=6, units="in", res=600)
plot(dat_62$week, dat_62$n_ts_sm, type = "l",xlab="Weeks",ylab="Number of Articles",
     main="organization for economic cooperation & development")
abline(h = mean(dat_62$n_ts_sm))
abline(h = mean(dat_62$n_ts_sm)+sd(dat_62$n_ts_sm), lty = "dashed") #Standard Deviation lines
abline(h = mean(dat_62$n_ts_sm)-sd(dat_62$n_ts_sm), lty = "dashed")
dev.off()

#Tonality
png(filename=paste("./Prototype_UK/Results/Graphs/timeline_ton_62.png", sep=""), width=9, height=6, units="in", res=600)
plot(dat_62$week, dat_62$ton_neg_ts_sm, type = "l",xlab="Weeks",ylab="Number of Negative Articles",
     main="organization for economic cooperation & development")
abline(h = mean(dat_62$ton_neg_ts_sm))
abline(h = mean(dat_62$ton_neg_ts_sm)+sd(dat_62$ton_neg_ts_sm), lty = "dashed") #Standard Deviation lines
abline(h = mean(dat_62$ton_neg_ts_sm)-sd(dat_62$ton_neg_ts_sm), lty = "dashed")
dev.off()

plot(dat_62$week, dat_62$n_ts_sm, type = "l",xlab="Weeks",ylab="Number of Articles",
     main="organization for economic cooperation & development")
lines(dat_62$week, dat_62$ton_neg_ts_sm, type = "l",xlab="Weeks",ylab="Number of Negative Articles",
      main="organization for economic cooperation & development")

#Variable for peak and low times
#Salience
dat_62$peak <- 0
dat_62$peak[dat_62$n_ts_sm>mean(dat_62$n_ts_sm)+sd(dat_62$n_ts_sm)] <- 1
dat_62$peak[dat_62$n_ts_sm<mean(dat_62$n_ts_sm)-sd(dat_62$n_ts_sm)] <- -1
#Tonality
dat_62$peak_neg <- 0
dat_62$peak_neg[dat_62$ton_neg_ts_sm>mean(dat_62$ton_neg_ts_sm)+sd(dat_62$ton_neg_ts_sm)] <- 1
dat_62$peak_neg[dat_62$ton_neg_ts_sm<mean(dat_62$ton_neg_ts_sm)-sd(dat_62$ton_neg_ts_sm)] <- -1


#Entity-Identifier for merging
dat_62$entity_id <- 62

#Remove these variables: same names in dat_base (initial corpus); later we will merge them
dat_62$n <- NULL
dat_62$n_w <- NULL


#organization for security and cooperation in europe
#----------
dat_63 <- dat_base[dat_base$entity_id==63,]
require(plyr)
dat_63 <- ddply(dat_63, .(weeks, years), function (x) {
  data.frame(n = sum(x$n), n_w = sum(x$n_w), ton_neg=sum(x$tonality_verbalized_negative))})
dat_63 <- dat_63[order(dat_63$year, dat_63$weeks),]

# week 53 is odd as well, so lets get rid of it as well
dat_63 <- dat_63[dat_63$week != 53,]
dat_63 <- dat_63[!is.na(dat_63$week),]

#do we have censored data?
hist(dat_63$n, breaks = 100)
hist(dat_63$n_w, breaks = 100)
hist(dat_63$ton_neg, breaks=100)

# QUESTION: How does that check for censored data?

# check for unit roots (stationarity) with Augmented Dickey-Fowler test
require(tseries)
adf.test(dat_63$n)
adf.test(dat_63$n_w)
adf.test(dat_63$ton_neg)
# p-value is smaller than 0.01 => stationary time series

# check whether and if yes, which seasonality dominates the data
require(forecast)
findfrequency(dat_63$n) # monthly seasonality (seas = 9; 2-monthly); 
findfrequency(dat_63$n_w) # monthly seasonality (seas = 9; 2-monthly); 
findfrequency(dat_63$ton_neg) # monthly seasonality (seas = 13; 3-monthly); 

#Build a time series
dat_63$n_ts <- ts(dat_63$n)
dat_63$n_w_ts <- ts(dat_63$n_w)
dat_63$ton_neg_ts <- ts(dat_63$ton_neg)

#smooth with monthly moving average (4 is rather arbitrary, but automated
# detection yields 59 which clearly is nonsense!) to see trends better
require(smooth)
dat_63$n_ts_sm <- sma(dat_63$n_ts, order = 4)$fitted
dat_63$n_w_ts_sm <- sma(dat_63$n_w_ts, order = 4)$fitted
dat_63$ton_neg_ts_sm <- sma(dat_63$ton_neg_ts, order = 4)$fitted

# create starting date of every week
dat_63$week <- as.Date(paste(dat_63$years, dat_63$weeks, 1, sep="-"), "%Y-%U-%u")

# illustrate peaks and slumps
#Salience
png(filename=paste("./Prototype_UK/Results/Graphs/timeline_63.png", sep=""), width=9, height=6, units="in", res=600)
plot(dat_63$week, dat_63$n_ts_sm, type = "l",xlab="Weeks",ylab="Number of Articles",
     main="organization for security and cooperation in europe")
abline(h = mean(dat_63$n_ts_sm))
abline(h = mean(dat_63$n_ts_sm)+sd(dat_63$n_ts_sm), lty = "dashed") #Standard Deviation lines
abline(h = mean(dat_63$n_ts_sm)-sd(dat_63$n_ts_sm), lty = "dashed")
dev.off()

#Tonality
png(filename=paste("./Prototype_UK/Results/Graphs/timeline_ton_63.png", sep=""), width=9, height=6, units="in", res=600)
plot(dat_63$week, dat_63$ton_neg_ts_sm, type = "l",xlab="Weeks",ylab="Number of Negative Articles",
     main="organization for security and cooperation in europe")
abline(h = mean(dat_63$ton_neg_ts_sm))
abline(h = mean(dat_63$ton_neg_ts_sm)+sd(dat_63$ton_neg_ts_sm), lty = "dashed") #Standard Deviation lines
abline(h = mean(dat_63$ton_neg_ts_sm)-sd(dat_63$ton_neg_ts_sm), lty = "dashed")
dev.off()


plot(dat_63$week, dat_63$n_ts_sm, type = "l",xlab="Weeks",ylab="Number of Articles",
     main="organization for security and cooperation in europe")
lines(dat_63$week, dat_63$ton_neg_ts_sm, type = "l",xlab="Weeks",ylab="Number of Negative Articles",
  main="organization for security and cooperation in europe")

#Variable for peak and low times
#Salience
dat_63$peak <- 0
dat_63$peak[dat_63$n_ts_sm>mean(dat_63$n_ts_sm)+sd(dat_63$n_ts_sm)] <- 1
dat_63$peak[dat_63$n_ts_sm<mean(dat_63$n_ts_sm)-sd(dat_63$n_ts_sm)] <- -1
#Tonality
dat_63$peak_neg <- 0
dat_63$peak_neg[dat_63$ton_neg_ts_sm>mean(dat_63$ton_neg_ts_sm)+sd(dat_63$ton_neg_ts_sm)] <- 1
dat_63$peak_neg[dat_63$ton_neg_ts_sm<mean(dat_63$ton_neg_ts_sm)-sd(dat_63$ton_neg_ts_sm)] <- -1


#Entity-Identifier for merging
dat_63$entity_id <- 63

#Remove these variables: same names in dat_base (initial corpus); later we will merge them
dat_63$n <- NULL
dat_63$n_w <- NULL


#parliamentary assembly of the council of europe
#----------
dat_64 <- dat_base[dat_base$entity_id==64,]
require(plyr)
dat_64 <- ddply(dat_64, .(weeks, years), function (x) {
  data.frame(n = sum(x$n), n_w = sum(x$n_w), ton_neg=sum(x$tonality_verbalized_negative))})
dat_64 <- dat_64[order(dat_64$year, dat_64$weeks),]

# week 53 is odd as well, so lets get rid of it as well
dat_64 <- dat_64[dat_64$week != 53,]
dat_64 <- dat_64[!is.na(dat_64$week),]

#do we have censored data?
hist(dat_64$n, breaks = 100)
hist(dat_64$n_w, breaks = 100)
hist(dat_64$ton_neg, breaks=100)

# QUESTION: How does that check for censored data?

# check for unit roots (stationarity) with Augmented Dickey-Fowler test
require(tseries)
adf.test(dat_64$n)
adf.test(dat_64$n_w)
adf.test(dat_64$ton_neg)
# p-value is smaller than 0.01 => stationary time series

# check whether and if yes, which seasonality dominates the data
require(forecast)
findfrequency(dat_64$n) # monthly seasonality (seas = 1; weekly); 
findfrequency(dat_64$n_w) # monthly seasonality (seas = 1; weekly); 
findfrequency(dat_64$ton_neg) # monthly seasonality (seas = 1; weekly); 

#Build a time series
dat_64$n_ts <- ts(dat_64$n)
dat_64$n_w_ts <- ts(dat_64$n_w)
dat_64$ton_neg_ts <- ts(dat_64$ton_neg)

#smooth with monthly moving average (4 is rather arbitrary, but automated
# detection yields 59 which clearly is nonsense!) to see trends better
require(smooth)
dat_64$n_ts_sm <- sma(dat_64$n_ts, order = 4)$fitted
dat_64$n_w_ts_sm <- sma(dat_64$n_w_ts, order = 4)$fitted
dat_64$ton_neg_ts_sm <- sma(dat_64$ton_neg_ts, order = 4)$fitted

# create starting date of every week
dat_64$week <- as.Date(paste(dat_64$years, dat_64$weeks, 1, sep="-"), "%Y-%U-%u")

# illustrate peaks and slumps
#Salience
png(filename=paste("./Prototype_UK/Results/Graphs/timeline_64.png", sep=""), width=9, height=6, units="in", res=600)
plot(dat_64$week, dat_64$n_ts_sm, type = "l",xlab="Weeks",ylab="Number of Articles",
     main="parliamentary assembly of the council of europe")
abline(h = mean(dat_64$n_ts_sm))
abline(h = mean(dat_64$n_ts_sm)+sd(dat_64$n_ts_sm), lty = "dashed") #Standard Deviation lines
abline(h = mean(dat_64$n_ts_sm)-sd(dat_64$n_ts_sm), lty = "dashed")
dev.off()

#Tonality
png(filename=paste("./Prototype_UK/Results/Graphs/timeline_ton_64.png", sep=""), width=9, height=6, units="in", res=600)
plot(dat_64$week, dat_64$ton_neg_ts_sm, type = "l",xlab="Weeks",ylab="Number of Negative Articles",
     main="parliamentary assembly of the council of europe")
abline(h = mean(dat_64$ton_neg_ts_sm))
abline(h = mean(dat_64$ton_neg_ts_sm)+sd(dat_64$ton_neg_ts_sm), lty = "dashed") #Standard Deviation lines
abline(h = mean(dat_64$ton_neg_ts_sm)-sd(dat_64$ton_neg_ts_sm), lty = "dashed")
dev.off()


plot(dat_64$week, dat_64$n_ts_sm, type = "l",xlab="Weeks",ylab="Number of Articles",
     main="parliamentary assembly of the council of europe")
lines(dat_64$week, dat_64$ton_neg_ts_sm, type = "l",xlab="Weeks",ylab="Number of Negative Articles")

#Variable for peak and low times
#Salience
dat_64$peak <- 0
dat_64$peak[dat_64$n_ts_sm>mean(dat_64$n_ts_sm)+sd(dat_64$n_ts_sm)] <- 1
dat_64$peak[dat_64$n_ts_sm<mean(dat_64$n_ts_sm)-sd(dat_64$n_ts_sm)] <- -1
#Tonality
dat_64$peak_neg <- 0
dat_64$peak_neg[dat_64$ton_neg_ts_sm>mean(dat_64$ton_neg_ts_sm)+sd(dat_64$ton_neg_ts_sm)] <- 1
dat_64$peak_neg[dat_64$ton_neg_ts_sm<mean(dat_64$ton_neg_ts_sm)-sd(dat_64$ton_neg_ts_sm)] <- -1


#Entity-Identifier for merging
dat_64$entity_id <- 64

#Remove these variables: same names in dat_base (initial corpus); later we will merge them
dat_64$n <- NULL
dat_64$n_w <- NULL

# BIVARIATE ANALYSIS #
#---------------------

#Are certain governor characteristics/media types clearly under-/overrepresented in peak/non-peak times (salience & tonality)?

# TOPIC MODELS #
#---------------------

#load libraries
library(tm)
library(stm)
library(lubridate)

corpus <- corpus[order(corpus$article_date, decreasing = T),]
corpus$weeks <- week(corpus$article_date)
corpus <- corpus[corpus$weeks != 53,]
corpus$years <- year(corpus$article_date)
corpus$week <- as.numeric(as.factor(as.Date(paste(corpus$years,
                                                  corpus$weeks, 1, sep="-"), "%Y-%U-%u")))

# preprocess texts (rather rough but quite standard). Denny and Spirling
# (https://www.nyu.edu/projects/spirling/documents/preprocessing.pdf) argue that we should evaluate this, too (?).
texts <- Corpus(VectorSource(corpus$article_text))
texts <- tm_map(texts, tolower)
texts <- tm_map(texts, removePunctuation)
texts <- tm_map(texts, removeNumbers)
texts <- tm_map(texts, stripWhitespace)
for (i in 1:length(corpus$article_text)) {
  corpus$text_preprocessed[i] <- gsub("\\s", " ", texts[[i]])
}
corpus$text_preprocessed <- gsub("\\s+", " ", corpus$text_preprocessed)
corpus$text_preprocessed <- gsub("^\\s+|\\s+$", "", corpus$text_preprocessed)

# recode some vars. The stm likes factors - m.n. in the postestimation -, so we encode our indicators accordingly
corpus$actor_type[corpus$actor_type %in% c("hybrid", "private")] <- "hybrid_private"
corpus$actor_type <- as.factor(corpus$actor_type)
corpus$tonality_verbalized <- as.factor(corpus$tonality_verbalized)
corpus$policy_scope <- as.factor(corpus$policy_scope)
corpus$territorial_scope[corpus$territorial_scope %in% c("subnational", "regional")] <- "regional_national"
corpus$territorial_scope <- as.factor(corpus$territorial_scope)
corpus$media_source <- as.factor(corpus$media_source)
corpus$entity_name <- as.factor(corpus$entity_name)
corpus$media_type[corpus$media_type %in% c("regional", "tabloid_or_free")] <- "regional_tabloid_free"
corpus$media_type[corpus$media_type %in% c("magazines", "quality")] <- "quality_magazines"
corpus$media_type <- as.factor(corpus$media_type)
corpus$peak <- as.factor(corpus$peak)
corpus$policy_output[corpus$policy_output %in% c("hard", "hard / soft")] <- "hard_soft"
corpus$policy_output <- as.factor(corpus$policy_output)
corpus$policy_field_1 <- tolower(corpus$policy_field_1)
corpus$policy_field_1 <- ifelse(corpus$policy_field_1 %in% c("multiple", "not definable", "", "."), "multiple", "specific")
corpus$policy_field_1[is.na(corpus$policy_field_1)] <- "multiple"
corpus$policy_field_1 <- as.factor(corpus$policy_field_1)
corpus <- corpus[!is.na(corpus$policy_output),]










