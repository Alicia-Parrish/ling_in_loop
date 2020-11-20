library(tidyverse)
library(rjson)
library(jsonlite)

setwd("C:/Users/NYUCM Loaner Access/Documents/GitHub/ling_in_loop/scripts")

set.seed(42)

anon_codes = read.csv("../../SECRET/ling_in_loop_SECRET/anonymized_id_links.csv")

round = "round4" # change this value each round

LitL<-NULL
LitL_files = list.files(paste0("../../SECRET/ling_in_loop_SECRET/raw_mturk_files/Group3_ling_in_loop/",round,"_writing"),full.names=T, pattern = "*.csv")
for(i in 1:length(LitL_files)){
  temp = read.csv(LitL_files[i])
  LitL = rbind(LitL,temp)
}

LitL_anon<-merge(LitL,anon_codes,by="WorkerId")
LitL_anon_transformed <- LitL_anon %>%
  group_by(AnonId, WorkerId)%>%
  summarise(count=n())

