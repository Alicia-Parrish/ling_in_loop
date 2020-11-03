library(tidyverse)
library(rjson)
library(jsonlite)

setwd("C:/Users/NYUCM Loaner Access/Documents/GitHub/ling_in_loop/scripts")

set.seed(42)

# function for reading in .jsonl files
read_json_lines <- function(file){
  con <- file(file, open = "r")
  on.exit(close(con))
  jsonlite::stream_in(con, verbose = FALSE)
}

dat<-read_json_lines("files/matched_slate.jsonl")

dat_test<-filter(dat,splits=="test")
dat_dev<-filter(dat,splits=="dev")
dat_train<-filter(dat,splits=="train")

# get already posted ones
posted = list.files("files/WRITING_csv_for_mturk_upload", pattern = "xPOSTEDx.*.csv", full.names = T)
posted_hits = NULL
for(i in 1:length(posted)){
  temp = read.csv(posted[i])
  posted_hits = rbind(posted_hits,temp)
}
posted_ids<-unique(posted_hits$promptID)

# remove ids that have already been posted
dat_dev2 <- dat_dev %>% filter(!promptID %in% posted_ids)
dat_train2 <- dat_train %>% filter(!promptID %in% posted_ids)

# remove ones where the hypothesis is too short
dat_dev3<-dat_dev2 %>% 
  mutate(lens = sapply(strsplit(premise, " "), length))%>%
  filter(!lens<6)%>%
  select(-lens)
  
dat_train3<-dat_train2%>%
  mutate(lens = sapply(strsplit(premise, " "), length))%>%
  filter(!lens<6)%>%
  select(-lens)


n_per_round = ceiling(3500/3)
n_dev = floor(nrow(dat_dev3)/4) # four rounds left
n_train = n_per_round-n_dev
add_dev = ceiling(500/3)-n_dev

# randomize order of rows
dat_dev_reorder <- dat_dev3[sample(1:nrow(dat_dev3)), ]
dat_train_reorder <- dat_train3[sample(1:nrow(dat_train3)), ]

#round1<-rbind(dat_train_reorder[1:n_train,],dat_dev_reorder[1:n_dev,])
#round1$splits[1:add_dev]<-"dev" # need to add 20 rows of dev because want 15%
round2<-rbind(dat_train_reorder[1:n_train,],dat_dev_reorder[1:n_dev,])
round2$splits[1:add_dev]<-"dev" # need to add more rows for 500 dev examples per round
round3<-rbind(dat_train_reorder[(n_train+1):(n_train*2),],dat_dev_reorder[(n_dev+1):(n_dev*2),])
round3$splits[1:add_dev]<-"dev"
round4<-rbind(dat_train_reorder[((n_train*2)+1):(n_train*3),],dat_dev_reorder[((n_dev*2)+1):(n_dev*3),])
round4$splits[1:add_dev]<-"dev"
round5<-rbind(dat_train_reorder[((n_train*3)+1):(n_train*4),],dat_dev_reorder[((n_dev*3)+1):(n_dev*4),])
round5$splits[1:add_dev]<-"dev"
# round5<-rbind(dat_train_reorder[((n_train*4)+1):(n_train*5),],dat_dev_reorder[((n_dev*4)+1):(n_dev*5),])
# round5$splits[1:add_dev]<-"dev"

#round1_reorder<-round1[sample(1:nrow(round1)), ]
round2_reorder<-round2[sample(1:nrow(round2)), ]
round3_reorder<-round3[sample(1:nrow(round3)), ]
round4_reorder<-round4[sample(1:nrow(round4)), ]
round5_reorder<-round5[sample(1:nrow(round5)), ]

#check that I didn't duplicate anything accidentally
Reduce(intersect, list(round2_reorder$promptID,round3_reorder$promptID,round4_reorder$promptID,round5_reorder$promptID)) #round1_reorder$promptID,

#check that I got the right number of dev items
#nrow(filter(round1_reorder,splits=="dev"))==167
nrow(filter(round2_reorder,splits=="dev"))==167
nrow(filter(round3_reorder,splits=="dev"))==167
nrow(filter(round4_reorder,splits=="dev"))==167
nrow(filter(round5_reorder,splits=="dev"))==167

#round1_reorder <- apply(round1_reorder,2,as.character)
round2_reorder <- apply(round2_reorder,2,as.character)
round3_reorder <- apply(round3_reorder,2,as.character)
round4_reorder <- apply(round4_reorder,2,as.character)
round5_reorder <- apply(round5_reorder,2,as.character)

write.csv(file="files/WRITING_csv_for_mturk_upload/round2_batch1.csv",round2_reorder[1:170,],row.names=FALSE)
write.csv(file="files/WRITING_csv_for_mturk_upload/round2_batch2.csv",round2_reorder[171:340,],row.names=FALSE)
write.csv(file="files/WRITING_csv_for_mturk_upload/round2_batch3.csv",round2_reorder[341:510,],row.names=FALSE)
write.csv(file="files/WRITING_csv_for_mturk_upload/round2_batch4.csv",round2_reorder[511:680,],row.names=FALSE)
write.csv(file="files/WRITING_csv_for_mturk_upload/round2_batch5.csv",round2_reorder[681:850,],row.names=FALSE)
write.csv(file="files/WRITING_csv_for_mturk_upload/round2_batch6.csv",round2_reorder[851:1020,],row.names=FALSE)
write.csv(file="files/WRITING_csv_for_mturk_upload/round2_batch7.csv",round2_reorder[1021:nrow(round2_reorder),],row.names=FALSE)
