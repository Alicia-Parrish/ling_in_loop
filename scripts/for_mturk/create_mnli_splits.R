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
  temp = select(temp, promptID)
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
n_dev = floor(nrow(dat_dev3)) # two rounds left
n_train = n_per_round-n_dev
add_dev = ceiling(500/3)-n_dev

# randomize order of rows
dat_dev_reorder <- dat_dev3[sample(1:nrow(dat_dev3)), ]
dat_train_reorder <- dat_train3[sample(1:nrow(dat_train3)), ]

#round1<-rbind(dat_train_reorder[1:n_train,],dat_dev_reorder[1:n_dev,])
#round1$splits[1:add_dev]<-"dev" # need to add 20 rows of dev because want 15%
#round2<-rbind(dat_train_reorder[1:n_train,],dat_dev_reorder[1:n_dev,])
#round2$splits[1:add_dev]<-"dev" # need to add more rows for 500 dev examples per round
#round3<-rbind(dat_train_reorder[1:n_train,],dat_dev_reorder[1:n_dev,])
#round3$splits[1:add_dev]<-"dev" # need to add more rows for 500 dev examples per round
#round4<-rbind(dat_train_reorder[1:n_train,],dat_dev_reorder[1:n_dev,])
#round4$splits[1:add_dev]<-"dev" # need to add more rows for 500 dev examples per round
round5<-rbind(dat_train_reorder[1:n_train,],dat_dev_reorder[1:n_dev,])
round5$splits[1:add_dev]<-"dev" # need to add more rows for 500 dev examples per round
#round5<-rbind(dat_train_reorder[(n_train+1):(n_train*2),],dat_dev_reorder[(n_dev+1):(n_dev*2),])
#round5$splits[1:add_dev]<-"dev"
#round5<-rbind(dat_train_reorder[((n_train*2)+1):(n_train*3),],dat_dev_reorder[((n_dev*2)+1):(n_dev*3),])
#round5$splits[1:add_dev]<-"dev"
# round5<-rbind(dat_train_reorder[((n_train*3)+1):(n_train*4),],dat_dev_reorder[((n_dev*3)+1):(n_dev*4),])
# round5$splits[1:add_dev]<-"dev"
# round5<-rbind(dat_train_reorder[((n_train*4)+1):(n_train*5),],dat_dev_reorder[((n_dev*4)+1):(n_dev*5),])
# round5$splits[1:add_dev]<-"dev"

#round1_reorder<-round1[sample(1:nrow(round1)), ]
#round2_reorder<-round2[sample(1:nrow(round2)), ]
#round3_reorder<-round3[sample(1:nrow(round3)), ]
#round4_reorder<-round4[sample(1:nrow(round4)), ]
round5_reorder<-round5[sample(1:nrow(round5)), ]

#check that I didn't duplicate anything accidentally
Reduce(intersect, list(round5_reorder$promptID)) #round1_reorder$promptID, round2_reorder$promptID, round4_reorder$promptID,

#check that I got the right number of dev items
#nrow(filter(round1_reorder,splits=="dev"))==167
#nrow(filter(round2_reorder,splits=="dev"))==167
#nrow(filter(round3_reorder,splits=="dev"))==167
#nrow(filter(round4_reorder,splits=="dev"))==167
nrow(filter(round5_reorder,splits=="dev"))==167

#round1_reorder <- apply(round1_reorder,2,as.character)
#round2_reorder <- apply(round2_reorder,2,as.character)
#round3_reorder <- apply(round3_reorder,2,as.character)
#round4_reorder <- apply(round4_reorder,2,as.character)
round5_reorder <- apply(round5_reorder,2,as.character)

######### CREATE FILES FOR UPLOAD ##########

round = 'round5'
batches = 4

# break into batches
r5_b1<-round5_reorder[1:290,]
r5_b2<-round5_reorder[291:580,]
r5_b3<-round5_reorder[581:870,]
r5_b4<-round5_reorder[871:nrow(round5_reorder),]
#r3_b5<-round3_reorder[933:nrow(round3_reorder),]

heurs_g2<-read.csv("files/round5_heuristics_group2.csv")
heurs_g3<-read.csv("files/round5_heuristics_group3.csv")

base_csvs<-list(r5_b1,r5_b2,r5_b3,r5_b4)
LotS_csvs<-list(
  merge(r5_b1, heurs_g2[2,]),
  merge(r5_b2, heurs_g2[1,]),
  merge(r5_b3, heurs_g2[4,]),
  merge(r5_b4, heurs_g2[3,])
)
LitL_csvs<-list(
  merge(r5_b1, heurs_g3[2,]),
  merge(r5_b2, heurs_g3[1,]),
  merge(r5_b3, heurs_g3[4,]),
  merge(r5_b4, heurs_g3[3,])
)

for(i in 1:length(base_csvs)){
  write.csv(file=paste0("files/WRITING_csv_for_mturk_upload/",round,"_group1_batch",i,".csv"),base_csvs[[i]],row.names=FALSE)
}
for(i in 1:length(LotS_csvs)){
  write.csv(file=paste0("files/WRITING_csv_for_mturk_upload/",round,"_group2_batch",i,".csv"),LotS_csvs[[i]],row.names=FALSE)
}
for(i in 1:length(LitL_csvs)){
  write.csv(file=paste0("files/WRITING_csv_for_mturk_upload/",round,"_group3_batch",i,".csv"),LitL_csvs[[i]],row.names=FALSE)
}
  
  
# write.csv(file=paste0("files/WRITING_csv_for_mturk_upload/",round,"_group1_batch2.csv"),round3_reorder[171:340,],row.names=FALSE)
# write.csv(file=paste0("files/WRITING_csv_for_mturk_upload/",round,"_group1_batch3.csv"),round3_reorder[341:510,],row.names=FALSE)
# write.csv(file=paste0("files/WRITING_csv_for_mturk_upload/",round,"_group1_batch4.csv"),round3_reorder[511:680,],row.names=FALSE)
# write.csv(file=paste0("files/WRITING_csv_for_mturk_upload/",round,"_group1_batch5.csv"),round3_reorder[681:850,],row.names=FALSE)
# write.csv(file="files/WRITING_csv_for_mturk_upload/round2_batch6.csv",round2_reorder[851:1020,],row.names=FALSE)
# write.csv(file="files/WRITING_csv_for_mturk_upload/round2_batch7.csv",round2_reorder[1021:nrow(round2_reorder),],row.names=FALSE)
