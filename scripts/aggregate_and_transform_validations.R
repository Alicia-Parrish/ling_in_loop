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

base_files = list.files("../../SECRET/ling_in_loop_SECRET/raw_mturk_files/Group1_baseline/Round1_validation",full.names=T)
LotS_files = list.files("../../SECRET/ling_in_loop_SECRET/raw_mturk_files/Group2_ling_on_side/Round1_validation",full.names=T)
LitL_files = list.files("../../SECRET/ling_in_loop_SECRET/raw_mturk_files/Group3_ling_in_loop/Round1_validation",full.names=T)

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
# apply anon codes here

base_smaller = select(base, matches("Answer|Input|AnonId"))
colnames(base_smaller) <-  sub("Answer.", "", colnames(base_smaller))
colnames(base_smaller) <-  sub("Input.", "", colnames(base_smaller))
this_group = unique(base_smaller$group)
this_round = unique(base_smaller$round)
base_smaller2<-base_smaller%>%
  select(-useragent,-response_ex,-numanswered,-comments,-group,-round)
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
all_base<-rbind(base_part1,base_part2,base_part3,base_part4,base_part5,base_part6)

all_pairIds = levels(all_base$pairID)
base_transformed=data.frame(matrix(ncol = 7, nrow = length(all_pairIds)))
colnames(base_transformed)<-c("annotator_ids","annotator_labels","label","pairID","promptID","premise","hypothesis")

for(i in 1:length(all_pairIds)){
  temp = filter(all_base2,pairID==all_pairIds[i])
  all_ids = list(as.character(temp$anonId))
  all_ids= list(unlist(append(as.character(temp$annotator1_ID[1]),all_ids)))
  base_transformed$annotator_ids[i] = all_ids
  all_labels = list(as.character(temp$response))
  all_labels= list(unlist(append(as.character(temp$annotator1_label[1]),all_labels)))
  base_transformed$annotator_labels[i] = all_labels
  #calculate_gold = table(all_labels)
  num_e = sum(str_count(unlist(all_labels),"entailment"))
  num_n = sum(str_count(unlist(all_labels),"neutral"))
  num_c = sum(str_count(unlist(all_labels),"contradiction"))
  gold_label = ifelse(num_e>=3,"entailment",
                      ifelse(num_n>=3,"neutral",
                             ifelse(num_c>=3,"contradiction","no_winner")))
  base_transformed$label[i] = as.character(gold_label)
  new_pairId = ifelse(gold_label=="entailment", paste0(temp$promptID[1],"e"),
                      ifelse(gold_label=="neutral", paste0(temp$promptID[1],"n"),
                             ifelse(gold_label=="contradiction", paste0(temp$promptID[1],"c"),"no_winner")))
  base_transformed$pairID[i] = as.character(new_pairId)
  base_transformed$promptID[i] = as.character(temp$promptID[1])
  base_transformed$premise[i] = as.character(temp$premise[1])
  base_transformed$hypothesis[i] = as.character(temp$hypothesis[1])
}

base_transformed$round = this_round
base_transformed$group = this_group

jsonlite::stream_out(base_transformed, file('../NLI_data/3_Ling_in_loop_protocol/val_round1_base.jsonl'))


# ---------- LING-ON-SIDE PROTOCOL



# ---------- LING-IN-LOOP PROTOCOL


