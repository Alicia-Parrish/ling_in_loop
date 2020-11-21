library(tidyverse)
library(rjson)
library(jsonlite)

setwd("C:/Users/NYUCM Loaner Access/Documents/GitHub/ling_in_loop/scripts")

set.seed(42)

anon_codes = read.csv("../../SECRET/ling_in_loop_SECRET/anonymized_id_links.csv")

round = "round4" # change this value each round
groups = c("Group1_baseline","Group2_ling_on_side","Group3_ling_in_loop")
group = groups[1]
split = "validation" # "writing" # 

dat<-NULL
dat_files = list.files(paste0("../../SECRET/ling_in_loop_SECRET/raw_mturk_files/",group,"/",round,"_",split),full.names=T, pattern = "*.csv")
for(i in 1:length(dat_files)){
  temp = read.csv(dat_files[i])
  dat = rbind(dat,temp)
}

dat_anon<-merge(dat,anon_codes,by="WorkerId")
dat_anon_transformed <- dat_anon %>%
  group_by(AnonId, WorkerId)%>%
  summarise(count=n())

View(dat_anon_transformed)
