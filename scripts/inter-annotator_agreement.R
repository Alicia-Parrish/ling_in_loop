library(tidyverse)
library(rjson)
library(jsonlite)
library(irr)
library(boot)
library(RColorBrewer)
library(gridExtra)
library(grid)

setwd("C:/Users/NYUCM Loaner Access/Documents/GitHub/ling_in_loop/scripts")

set.seed(42)

# function for reading in .jsonl files
read_json_lines <- function(file){
  con <- file(file, open = "r")
  on.exit(close(con))
  jsonlite::stream_in(con, verbose = FALSE)
}

######### get all the data 
base_val<-read_json_lines("../../SECRET/ling_in_loop_SECRET/full_validation_files/val_round1_base_alldata.jsonl")
LotS_val<-read_json_lines("../../SECRET/ling_in_loop_SECRET/full_validation_files/val_round1_LotS_alldata.jsonl")
LitL_val<-read_json_lines("../../SECRET/ling_in_loop_SECRET/full_validation_files/val_round1_LitL_alldata.jsonl")

## BASELINE
base_val<-filter(base_val,label!="no_winner")
dat1 <- do.call(rbind, base_val$annotator_labels) # transform data
kappam.fleiss(dat1,detail = TRUE) # calculate fleiss's kappa

## LING ON SIDE
LotS_val<-filter(LotS_val,label!="no_winner")
dat2 <- do.call(rbind, LotS_val$annotator_labels) # transform data
kappam.fleiss(dat2,detail = TRUE) # calculate fleiss's kappa

## LING IN LOOP
LitL_val<-filter(LitL_val,label!="no_winner")
dat3 <- do.call(rbind, LitL_val$annotator_labels) # transform data
kappam.fleiss(dat3,detail = TRUE) # calculate fleiss's kappa


# compare differences in distribution using bootstrapping
bt1 <- boot(dat1, function(x, idx) {kappam.fleiss(x[idx,])$value}, R=1000)
ci1<-boot.ci(bt1)
ci1_hi<-as.list(strsplit(as.character(unlist(ci1[4])), '\\s+')[[2]])
ci1_lo<-as.list(strsplit(as.character(unlist(ci1[4])), '\\s+')[[3]])
p1<-hist(bt1$t, freq = FALSE, breaks = 50)

bt2 <- boot(dat2, function(x, idx) {kappam.fleiss(x[idx,])$value}, R=1000)
ci2<-boot.ci(bt2)
ci2_hi<-as.list(strsplit(as.character(unlist(ci2[4])), '\\s+')[[2]])
ci2_lo<-as.list(strsplit(as.character(unlist(ci2[4])), '\\s+')[[3]])
p2<-hist(bt2$t, freq = FALSE, breaks = 50)

bt3 <- boot(dat3, function(x, idx) {kappam.fleiss(x[idx,])$value}, R=1000)
ci3<-boot.ci(bt3)
ci3_hi<-as.list(strsplit(as.character(unlist(ci3[4])), '\\s+')[[2]])
ci3_lo<-as.list(strsplit(as.character(unlist(ci3[4])), '\\s+')[[3]])
p3<-hist(bt3$t, freq = FALSE, breaks = 50)

par(mfrow = c(3, 1))
cols<-brewer.pal(12, "Set3")

plt1<-plot(p1, col = cols[1], xlim = c(0.55, .7), ylim = c(0,60),main="Baseline", xlab="kappa", ylab="count")
abline(v = c(ci1_lo,ci1_hi,as.character(bt1[1])), col=c("red","red","blue"), lwd=c(3,3,5), lty=c(2,2,1))
plt2<-plot(p2, col = cols[4], xlim = c(0.55, .7), ylim = c(0,60),main="Linguist on the side", xlab="kappa", ylab="count")
abline(v = c(ci2_lo,ci2_hi,as.character(bt2[1])), col=c("red","red","blue"), lwd=c(3,3,5), lty=c(2,2,1))
plt3<-plot(p3, col = cols[8], xlim = c(0.55, .7), ylim = c(0,60),main="Linguist in the loop", xlab="kappa", ylab="count")
abline(v = c(ci3_lo,ci3_hi,as.character(bt3[1])), col=c("red","red","blue"), lwd=c(3,3,5), lty=c(2,2,1))

par(mfrow = c(1, 1))
