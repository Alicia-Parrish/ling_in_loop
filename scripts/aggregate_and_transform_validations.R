library(tidyverse)
library(rjson)
library(jsonlite)
library(data.table)

setwd("C:/Users/NYUCM Loaner Access/Documents/GitHub/ling_in_loop/scripts")

set.seed(42)

base<-NULL
LotS<-NULL
LitL<-NULL

anon_codes = read.csv("../../SECRET/ling_in_loop_SECRET/anonymized_id_links.csv")

base_files = list.files("../../SECRET/ling_in_loop_SECRET/raw_mturk_files/Group1_baseline/Round1_validation",full.names=T,pattern="*.csv")
LotS_files = list.files("../../SECRET/ling_in_loop_SECRET/raw_mturk_files/Group2_ling_on_side/Round1_validation",full.names=T,pattern="*.csv")
LitL_files = list.files("../../SECRET/ling_in_loop_SECRET/raw_mturk_files/Group3_ling_in_loop/Round1_validation",full.names=T,pattern="*.csv")

for(i in 1:length(base_files)){
  temp = read.csv(base_files[i])
  base = rbind(base,temp)
}
for(i in 1:length(LotS_files)){
  temp = read.csv(LotS_files[i])
  LotS = rbind(LotS,temp)
}
for(i in 1:length(LitL_files)){
  temp = read.csv(LitL_files[i])
  LitL = rbind(LitL,temp)
}

# ---------- BASELINE PROTOCOL
base_anon<-merge(base,anon_codes,by="WorkerId") # anonymize
base_smaller = select(base_anon, matches("Answer|Input|AnonId")) # get only relevant columns
colnames(base_smaller) <-  sub("Answer.", "", colnames(base_smaller)) # rename to get rid of mturk's automatically added notation
colnames(base_smaller) <-  sub("Input.", "", colnames(base_smaller))
this_group = unique(base_smaller$group) # save these values
this_round = unique(base_smaller$round)
base_smaller2<-base_smaller%>% # get rid of other unneeded columns
  select(-useragent,-response_ex,-numanswered,-comments,-group,-round)

# separate into different dfs and adjust column names so they're the same
base_part1<-select(base_smaller2,matches("_1|anonId"))
colnames(base_part1) <- sub("_1","", colnames(base_part1))
base_part2<-select(base_smaller2,matches("_2|anonId"))
colnames(base_part2) <- sub("_2","", colnames(base_part2))
base_part3<-select(base_smaller2,matches("_3|anonId"))
colnames(base_part3) <- sub("_3","", colnames(base_part3))
base_part4<-select(base_smaller2,matches("_4|anonId"))
colnames(base_part4) <- sub("_4","", colnames(base_part4))
base_part5<-select(base_smaller2,matches("_5|anonId"))
colnames(base_part5) <- sub("_5","", colnames(base_part5))
base_part6<-select(base_smaller2,matches("_6|anonId"))
colnames(base_part6) <- sub("_6","", colnames(base_part6))
# put them back together now that they all have the same name
all_base<-rbind(base_part1,base_part2,base_part3,base_part4,base_part5,base_part6)
all_base2<-all_base%>%
  filter(response!="")%>% # get rid of ones where the worker didn't answer
  filter(hypothesis!="{}")%>% # get rid of ones that were missing the hypothesis
  filter(pairID!=0) # get rid of ones I intentionally left blank

all_pairIds = levels(all_base2$pairID)
# create df to fill in with values
base_transformed=data.frame(matrix(ncol = 7, nrow = length(all_pairIds)))
colnames(base_transformed)<-c("annotator_ids","annotator_labels","label","pairID","promptID","premise","hypothesis")

# does formatting needed for jiant
for(i in 1:length(all_pairIds)){
  temp = filter(all_base2,pairID==all_pairIds[i]) # create df of just one pairId
  all_ids = list(as.character(temp$AnonId)) # keep track of annotator ids
  all_ids= list(unlist(append(as.character(temp$annotator1_ID[1]),all_ids)))
  base_transformed$annotator_ids[i] = all_ids
  all_labels = list(as.character(temp$response)) # keep track of labels
  all_labels= list(unlist(append(as.character(temp$annotator1_label[1]),all_labels)))
  base_transformed$annotator_labels[i] = all_labels
  num_e = sum(str_count(unlist(all_labels),"entailment")) # get number of each kind of label
  num_n = sum(str_count(unlist(all_labels),"neutral"))
  num_c = sum(str_count(unlist(all_labels),"contradiction"))
  gold_label = ifelse(num_e>=3,"entailment", # calculate gold label
                      ifelse(num_n>=3,"neutral",
                             ifelse(num_c>=3,"contradiction","no_winner")))
  base_transformed$label[i] = as.character(gold_label)
  new_pairId = ifelse(gold_label=="entailment", paste0(temp$promptID[1],"e"), # use gold label to get new pairId
                      ifelse(gold_label=="neutral", paste0(temp$promptID[1],"n"),
                             ifelse(gold_label=="contradiction", paste0(temp$promptID[1],"c"),"no_winner")))
  base_transformed$pairID[i] = as.character(new_pairId)
  base_transformed$promptID[i] = as.character(temp$promptID[1])
  base_transformed$premise[i] = as.character(temp$premise[1])
  base_transformed$hypothesis[i] = as.character(temp$hypothesis[1])
}

# add values back in
base_transformed$round = this_round
base_transformed$group = this_group

base_transformed<-filter(base_transformed,!is.na(promptID))

# validation failures
base_fails<-filter(base_transformed,label=="no_winner")
# validation passes
base_pass<-filter(base_transformed,label!="no_winner")

# save file
jsonlite::stream_out(base_pass, file('../NLI_data/1_Baseline_protocol/val_round1_base.jsonl'))
jsonlite::stream_out(base_transformed, file('../../SECRET/ling_in_loop_SECRET/full_validation_files/val_round1_base_alldata.jsonl'))

# ---------- LING-ON-SIDE PROTOCOL
LotS_anon<-merge(LotS,anon_codes,by="WorkerId") # anonymize
LotS_smaller = select(LotS_anon, matches("Answer|Input|AnonId")) # get only relevant columns
colnames(LotS_smaller) <-  sub("Answer.", "", colnames(LotS_smaller)) # rename to get rid of mturk's automatically added notation
colnames(LotS_smaller) <-  sub("Input.", "", colnames(LotS_smaller))
this_group = unique(LotS_smaller$group) # save these values
this_round = unique(LotS_smaller$round)
LotS_smaller2<-LotS_smaller%>% # get rid of other unneeded columns
  select(-useragent,-response_ex,-numanswered,-comments,-group,-round)

# separate into different dfs and adjust column names so they're the same
LotS_part1<-select(LotS_smaller2,matches("_1|anonId"))
colnames(LotS_part1) <- sub("_1","", colnames(LotS_part1))
LotS_part2<-select(LotS_smaller2,matches("_2|anonId"))
colnames(LotS_part2) <- sub("_2","", colnames(LotS_part2))
LotS_part3<-select(LotS_smaller2,matches("_3|anonId"))
colnames(LotS_part3) <- sub("_3","", colnames(LotS_part3))
LotS_part4<-select(LotS_smaller2,matches("_4|anonId"))
colnames(LotS_part4) <- sub("_4","", colnames(LotS_part4))
LotS_part5<-select(LotS_smaller2,matches("_5|anonId"))
colnames(LotS_part5) <- sub("_5","", colnames(LotS_part5))
LotS_part6<-select(LotS_smaller2,matches("_6|anonId"))
colnames(LotS_part6) <- sub("_6","", colnames(LotS_part6))
# put them back together now that they all have the same name
all_LotS<-rbind(LotS_part1,LotS_part2,LotS_part3,LotS_part4,LotS_part5,LotS_part6)
all_LotS2<-all_LotS%>%
  filter(response!="")%>% # get rid of ones where the worker didn't answer
  filter(hypothesis!="{}")%>% # get rid of ones that were missing the hypothesis
  filter(pairID!=0) # get rid of ones I intentionally left blank

all_pairIds = levels(all_LotS2$pairID)
# create df to fill in with values
LotS_transformed=data.frame(matrix(ncol = 7, nrow = length(all_pairIds)))
colnames(LotS_transformed)<-c("annotator_ids","annotator_labels","label","pairID","promptID","premise","hypothesis")

# does formatting needed for jiant
for(i in 1:length(all_pairIds)){
  temp = filter(all_LotS2,pairID==all_pairIds[i]) # create df of just one pairId
  all_ids = list(as.character(temp$AnonId)) # keep track of annotator ids
  all_ids= list(unlist(append(as.character(temp$annotator1_ID[1]),all_ids)))
  LotS_transformed$annotator_ids[i] = all_ids
  all_labels = list(as.character(temp$response)) # keep track of labels
  all_labels= list(unlist(append(as.character(temp$annotator1_label[1]),all_labels)))
  LotS_transformed$annotator_labels[i] = all_labels
  num_e = sum(str_count(unlist(all_labels),"entailment")) # get number of each kind of label
  num_n = sum(str_count(unlist(all_labels),"neutral"))
  num_c = sum(str_count(unlist(all_labels),"contradiction"))
  gold_label = ifelse(num_e>=3,"entailment", # calculate gold label
                      ifelse(num_n>=3,"neutral",
                             ifelse(num_c>=3,"contradiction","no_winner")))
  LotS_transformed$label[i] = as.character(gold_label)
  new_pairId = ifelse(gold_label=="entailment", paste0(temp$promptID[1],"e"), # use gold label to get new pairId
                      ifelse(gold_label=="neutral", paste0(temp$promptID[1],"n"),
                             ifelse(gold_label=="contradiction", paste0(temp$promptID[1],"c"),"no_winner")))
  LotS_transformed$pairID[i] = as.character(new_pairId)
  LotS_transformed$promptID[i] = as.character(temp$promptID[1])
  LotS_transformed$premise[i] = as.character(temp$premise[1])
  LotS_transformed$hypothesis[i] = as.character(temp$hypothesis[1])
}

# add values back in
LotS_transformed$round = this_round
LotS_transformed$group = this_group

LotS_transformed<-filter(LotS_transformed,!is.na(promptID))

# validation failures
LotS_fails<-filter(LotS_transformed,label=="no_winner")
# validation passes
LotS_pass<-filter(LotS_transformed,label!="no_winner")

# save file
jsonlite::stream_out(LotS_pass, file('../NLI_data/2_Ling_on_side_protocol/val_round1_LotS.jsonl'))
jsonlite::stream_out(LotS_transformed, file('../../SECRET/ling_in_loop_SECRET/full_validation_files/val_round1_LotS_alldata.jsonl'))


# ---------- LING-IN-LOOP PROTOCOL
LitL_anon<-merge(LitL,anon_codes,by="WorkerId") # anonymize
LitL_smaller = select(LitL_anon, matches("Answer|Input|AnonId")) # get only relevant columns
colnames(LitL_smaller) <-  sub("Answer.", "", colnames(LitL_smaller)) # rename to get rid of mturk's automatically added notation
colnames(LitL_smaller) <-  sub("Input.", "", colnames(LitL_smaller))
this_group = unique(LitL_smaller$group) # save these values
this_round = unique(LitL_smaller$round)
LitL_smaller2<-LitL_smaller%>% # get rid of other unneeded columns
  select(-useragent,-response_ex,-numanswered,-comments,-group,-round)

# separate into different dfs and adjust column names so they're the same
LitL_part1<-select(LitL_smaller2,matches("_1|anonId"))
colnames(LitL_part1) <- sub("_1","", colnames(LitL_part1))
LitL_part2<-select(LitL_smaller2,matches("_2|anonId"))
colnames(LitL_part2) <- sub("_2","", colnames(LitL_part2))
LitL_part3<-select(LitL_smaller2,matches("_3|anonId"))
colnames(LitL_part3) <- sub("_3","", colnames(LitL_part3))
LitL_part4<-select(LitL_smaller2,matches("_4|anonId"))
colnames(LitL_part4) <- sub("_4","", colnames(LitL_part4))
LitL_part5<-select(LitL_smaller2,matches("_5|anonId"))
colnames(LitL_part5) <- sub("_5","", colnames(LitL_part5))
LitL_part6<-select(LitL_smaller2,matches("_6|anonId"))
colnames(LitL_part6) <- sub("_6","", colnames(LitL_part6))
# put them back together now that they all have the same name
all_LitL<-rbind(LitL_part1,LitL_part2,LitL_part3,LitL_part4,LitL_part5,LitL_part6)
all_LitL2<-all_LitL%>%
  filter(response!="")%>% # get rid of ones where the worker didn't answer
  filter(hypothesis!="{}")%>% # get rid of ones that were missing the hypothesis
  filter(pairID!=0) # get rid of ones I intentionally left blank

all_pairIds = levels(all_LitL2$pairID)
# create df to fill in with values
LitL_transformed=data.frame(matrix(ncol = 7, nrow = length(all_pairIds)))
colnames(LitL_transformed)<-c("annotator_ids","annotator_labels","label","pairID","promptID","premise","hypothesis")

# does formatting needed for jiant
for(i in 1:length(all_pairIds)){
  temp = filter(all_LitL2,pairID==all_pairIds[i]) # create df of just one pairId
  all_ids = list(as.character(temp$AnonId)) # keep track of annotator ids
  all_ids= list(unlist(append(as.character(temp$annotator1_ID[1]),all_ids)))
  LitL_transformed$annotator_ids[i] = all_ids
  all_labels = list(as.character(temp$response)) # keep track of labels
  all_labels= list(unlist(append(as.character(temp$annotator1_label[1]),all_labels)))
  LitL_transformed$annotator_labels[i] = all_labels
  num_e = sum(str_count(unlist(all_labels),"entailment")) # get number of each kind of label
  num_n = sum(str_count(unlist(all_labels),"neutral"))
  num_c = sum(str_count(unlist(all_labels),"contradiction"))
  gold_label = ifelse(num_e>=3,"entailment", # calculate gold label
                      ifelse(num_n>=3,"neutral",
                             ifelse(num_c>=3,"contradiction","no_winner")))
  LitL_transformed$label[i] = as.character(gold_label)
  new_pairId = ifelse(gold_label=="entailment", paste0(temp$promptID[1],"e"), # use gold label to get new pairId
                      ifelse(gold_label=="neutral", paste0(temp$promptID[1],"n"),
                             ifelse(gold_label=="contradiction", paste0(temp$promptID[1],"c"),"no_winner")))
  LitL_transformed$pairID[i] = as.character(new_pairId)
  LitL_transformed$promptID[i] = as.character(temp$promptID[1])
  LitL_transformed$premise[i] = as.character(temp$premise[1])
  LitL_transformed$hypothesis[i] = as.character(temp$hypothesis[1])
}

# add values back in
LitL_transformed$round = this_round
LitL_transformed$group = this_group

LitL_transformed<-filter(LitL_transformed,!is.na(promptID))

# validation failures
LitL_fails<-filter(LitL_transformed,label=="no_winner")
# validation passes
LitL_pass<-filter(LitL_transformed,label!="no_winner")

# save file
jsonlite::stream_out(LitL_pass, file('../NLI_data/3_Ling_in_loop_protocol/val_round1_LitL.jsonl'))
jsonlite::stream_out(LitL_transformed, file('../../SECRET/ling_in_loop_SECRET/full_validation_files/val_round1_LitL_alldata.jsonl'))


