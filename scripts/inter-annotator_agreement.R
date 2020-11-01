library(tidyverse)
library(rjson)
library(jsonlite)
library("irr")

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
