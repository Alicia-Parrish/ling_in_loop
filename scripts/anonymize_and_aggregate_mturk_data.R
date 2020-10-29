library(tidyverse)
library(rjson)
library(jsonlite)

setwd("C:/Users/NYUCM Loaner Access/Documents/GitHub/ling_in_loop/scripts")

set.seed(42)

anon_codes = read.csv("../../SECRET/ling_in_loop_SECRET/anonymized_id_links.csv")

base<-NULL
LotS<-NULL
LitL<-NULL

base_files = list.files("../../SECRET/ling_in_loop_SECRET/raw_mturk_files/Group1_baseline/Round1_writing",full.names=T)
LotS_files = list.files("../../SECRET/ling_in_loop_SECRET/raw_mturk_files/Group2_ling_on_side/Round1_writing",full.names=T)
LitL_files = list.files("../../SECRET/ling_in_loop_SECRET/raw_mturk_files/Group3_ling_in_loop/Round1_writing",full.names=T)

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
base_anon<-merge(base,anon_codes,by="WorkerId")
base_anon$round<-"round1"
base_anon_transformed<-base_anon%>%
  filter(Input.splits=="train")%>%
  select(AnonId,group,round,Input.promptID,Input.premise,Answer.entailment,Answer.neutral,Answer.contradiction)%>%
  rename("promptID"=Input.promptID,
         "premise"=Input.premise,
         "entailment"=Answer.entailment,
         "neutral"=Answer.neutral,
         "contradiction"=Answer.contradiction)%>%
  gather("gold_label","hypothesis",-promptID,-premise,-AnonId,-group,-round)%>%
  mutate("pairID"=ifelse(gold_label=="entailment",paste0(promptID,"e"),
                         ifelse(gold_label=="neutral",paste0(promptID,"n"),
                                ifelse(gold_label=="contradiction",paste0(promptID,"c"),"problem"))))

for(i in 1:length(base_anon_transformed)){
  base_anon_transformed$annotator_labels[i] = list(base_anon_transformed$gold_label[i])
}

base_anon_transformed<-base_anon_transformed%>%
  select(AnonId,group,round,annotator_labels,gold_label,pairID,promptID,premise,hypothesis)

jsonlite::stream_out(base_anon_transformed, file('../NLI_data/1_Baseline_protocol/round1_baseline.jsonl'))


# ---------- LotS PROTOCOL
LotS_anon<-merge(LotS,anon_codes,by="WorkerId")
LotS_anon$round<-"round1"
LotS_anon_transformed<-LotS_anon%>%
  filter(Input.splits=="train")%>%
  select(AnonId,group,round,Input.promptID,Input.premise,Answer.entailment,Answer.neutral,Answer.contradiction)%>%
  rename("promptID"=Input.promptID,
         "premise"=Input.premise,
         "entailment"=Answer.entailment,
         "neutral"=Answer.neutral,
         "contradiction"=Answer.contradiction)%>%
  gather("gold_label","hypothesis",-promptID,-premise,-AnonId,-group,-round)%>%
  mutate("pairID"=ifelse(gold_label=="entailment",paste0(promptID,"e"),
                         ifelse(gold_label=="neutral",paste0(promptID,"n"),
                                ifelse(gold_label=="contradiction",paste0(promptID,"c"),"problem"))))

for(i in 1:length(LotS_anon_transformed)){
  LotS_anon_transformed$annotator_labels[i] = list(LotS_anon_transformed$gold_label[i])
}

LotS_anon_transformed<-LotS_anon_transformed%>%
  select(AnonId,group,round,annotator_labels,gold_label,pairID,promptID,premise,hypothesis)

jsonlite::stream_out(LotS_anon_transformed, file('../NLI_data/2_Ling_on_side_protocol/round1_LotS.jsonl'))


# ---------- LitL PROTOCOL
LitL_anon<-merge(LitL,anon_codes,by="WorkerId")
LitL_anon$round<-"round1"
LitL_anon_transformed<-LitL_anon%>%
  filter(Input.splits=="train")%>%
  select(AnonId,group,round,Input.promptID,Input.premise,Answer.entailment,Answer.neutral,Answer.contradiction)%>%
  rename("promptID"=Input.promptID,
         "premise"=Input.premise,
         "entailment"=Answer.entailment,
         "neutral"=Answer.neutral,
         "contradiction"=Answer.contradiction)%>%
  gather("gold_label","hypothesis",-promptID,-premise,-AnonId,-group,-round)%>%
  mutate("pairID"=ifelse(gold_label=="entailment",paste0(promptID,"e"),
                         ifelse(gold_label=="neutral",paste0(promptID,"n"),
                                ifelse(gold_label=="contradiction",paste0(promptID,"c"),"problem"))))

for(i in 1:length(LitL_anon_transformed)){
  LitL_anon_transformed$annotator_labels[i] = list(LitL_anon_transformed$gold_label[i])
}

LitL_anon_transformed<-LitL_anon_transformed%>%
  select(AnonId,group,round,annotator_labels,gold_label,pairID,promptID,premise,hypothesis)

jsonlite::stream_out(LitL_anon_transformed, file('../NLI_data/3_Ling_in_loop_protocol/round1_LitL.jsonl'))

