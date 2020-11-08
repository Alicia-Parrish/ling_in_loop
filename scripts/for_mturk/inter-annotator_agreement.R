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
round="round2"

# function for reading in .jsonl files
read_json_lines <- function(file){
  con <- file(file, open = "r")
  on.exit(close(con))
  jsonlite::stream_in(con, verbose = FALSE)
}

######### get all the data 
base_val<-read_json_lines(paste0("../../SECRET/ling_in_loop_SECRET/full_validation_files/val_",round,"_base_alldata.jsonl"))
LotS_val<-read_json_lines(paste0("../../SECRET/ling_in_loop_SECRET/full_validation_files/val_",round,"_LotS_alldata.jsonl"))
LitL_val<-read_json_lines(paste0("../../SECRET/ling_in_loop_SECRET/full_validation_files/val_",round,"_LitL_alldata.jsonl"))

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

plt1<-plot(p1, col = cols[1], xlim = c(0.58, .78), ylim = c(0,60),main="Baseline", xlab="kappa", ylab="count")
abline(v = c(ci1_lo,ci1_hi,as.character(bt1[1])), col=c("red","red","blue"), lwd=c(3,3,5), lty=c(2,2,1))
plt2<-plot(p2, col = cols[4], xlim = c(0.58, .78), ylim = c(0,60),main="Linguist on the side", xlab="kappa", ylab="count")
abline(v = c(ci2_lo,ci2_hi,as.character(bt2[1])), col=c("red","red","blue"), lwd=c(3,3,5), lty=c(2,2,1))
plt3<-plot(p3, col = cols[8], xlim = c(0.58, .78), ylim = c(0,60),main="Linguist in the loop", xlab="kappa", ylab="count")
abline(v = c(ci3_lo,ci3_hi,as.character(bt3[1])), col=c("red","red","blue"), lwd=c(3,3,5), lty=c(2,2,1))

par(mfrow = c(1, 1))

############### BY HEURISTIC RESULTS #################

par(mar=c(2,2,2,2))
par(mfrow = c(7, 2))
all_heuristics = unique(LotS_val$heuristic)

## LING ON SIDE
dats<-list(LotS_val,LitL_val)
names(dats) <- c("LotS", "LitL")

n <- 14 # number of plots
list_plot <- vector(mode = "list", length = n)
names(list_plot) <- paste("plot", 1:n)

boots<-vector(mode = "list", length = n)
ci_lows<-vector(mode = "list", length = n)
ci_his<-vector(mode = "list", length = n)

for(i in 1:length(all_heuristics)){
  for(j in 1:length(dats)){
    dat <- dats[[j]]
    dat2<-dat%>%
      filter(label != "no_winner",
             heuristic == all_heuristics[i])
    dat3 <- do.call(rbind, dat2$annotator_labels) # transform data
    print(all_heuristics[i])
    kappam.fleiss(dat3,detail = TRUE) # calculate fleiss's kappa
    
    bt <- boot(dat3, function(x, idx) {kappam.fleiss(x[idx,])$value}, R=1000)
    boots[[((i-1)*2)+j]] <- bt
    ci<-boot.ci(bt)
    ci_lows[[((i-1)*2)+j]]<-as.list(strsplit(as.character(unlist(ci[4])), '\\s+')[[2]])
    ci_his[[((i-1)*2)+j]]<-as.list(strsplit(as.character(unlist(ci[4])), '\\s+')[[3]])
    list_plot[[((i-1)*2)+j]] <-hist(bt$t, freq = FALSE, breaks = 50)
    names(list_plot)[((i-1)*2)+j] = paste0(names(dats)[j],": ",all_heuristics[i])
  }
}

twocols<-c(cols[8],cols[4])
for(i in 1:14){
  plt_x<-plot(list_plot[[i]], col = twocols[(i%%2)+1], xlim = c(0.4, .85), ylim = c(0,80),main=names(list_plot)[i], xlab="kappa", ylab="count")
  abline(v = c(unlist(ci_lows[[i]]),unlist(ci_his[[i]]),as.character(boots[[i]][1])), col=c("red","red","blue"), lwd=c(3,3,5), lty=c(2,2,1))
}

