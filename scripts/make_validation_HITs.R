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
base$round<-"round1"
base_anon<-merge(base,anon_codes,by="WorkerId")
base_transformed<-base_anon%>%
  filter(Input.splits=="dev")%>%
  select(AnonId,Input.promptID,Input.premise,Answer.entailment,Answer.neutral,Answer.contradiction)%>%
  rename("promptID"=Input.promptID,
         "premise"=Input.premise,
         "entailment"=Answer.entailment,
         "neutral"=Answer.neutral,
         "contradiction"=Answer.contradiction,
         "annotator1_ID"=AnonId)%>%
  gather("annotator1_label","hypothesis",-promptID,-premise,-annotator1_ID)%>%
  mutate("pairID"=ifelse(annotator1_label=="entailment",paste0(promptID,"e"),
                         ifelse(annotator1_label=="neutral",paste0(promptID,"n"),
                                ifelse(annotator1_label=="contradiction",paste0(promptID,"c"),"problem"))))
  
# randomize order
base_reorder <- base_transformed[sample(1:nrow(base_transformed)), ]

# get structure needed for validation HIT
num=floor(nrow(base_reorder)/6) # will have 2 leftover
base_1 = base_reorder[1:num,]
base_2 = base_reorder[(num+1):(num*2),]
base_3 = base_reorder[((num*2)+1):(num*3),]
base_4 = base_reorder[((num*3)+1):(num*4),]
base_5 = base_reorder[((num*4)+1):(num*5),]
base_6 = base_reorder[((num*5)+1):(num*6),]

colnames(base_1)<-unlist(lapply(names(base_1), function(x) paste0(x,"_1")))
colnames(base_2)<-unlist(lapply(names(base_2), function(x) paste0(x,"_2")))
colnames(base_3)<-unlist(lapply(names(base_3), function(x) paste0(x,"_3")))
colnames(base_4)<-unlist(lapply(names(base_4), function(x) paste0(x,"_4")))
colnames(base_5)<-unlist(lapply(names(base_5), function(x) paste0(x,"_5")))
colnames(base_6)<-unlist(lapply(names(base_6), function(x) paste0(x,"_6")))

full_base_val = cbind(base_1,base_2,base_3,base_4,base_5,base_6)
full_base_val$group = "group1"
full_base_val$round = "round1"

write.csv(file="files/VALIDATION_csv_for_mturk_upload/round1_base_batch1.csv",full_base_val,row.names = F)

# ---------- LotS PROTOCOL
LotS$round<-"round1"
LotS_anon<-merge(LotS,anon_codes,by="WorkerId")
LotS_transformed<-LotS_anon%>%
  filter(Input.splits=="dev")%>%
  select(AnonId,Input.promptID,Input.premise,Answer.entailment,Answer.neutral,Answer.contradiction)%>%
  rename("promptID"=Input.promptID,
         "premise"=Input.premise,
         "entailment"=Answer.entailment,
         "neutral"=Answer.neutral,
         "contradiction"=Answer.contradiction,
         "annotator1_ID"=AnonId)%>%
  gather("annotator1_label","hypothesis",-promptID,-premise,-annotator1_ID)%>%
  mutate("pairID"=ifelse(annotator1_label=="entailment",paste0(promptID,"e"),
                         ifelse(annotator1_label=="neutral",paste0(promptID,"n"),
                                ifelse(annotator1_label=="contradiction",paste0(promptID,"c"),"problem"))))

# randomize order
LotS_reorder <- LotS_transformed[sample(1:nrow(LotS_transformed)), ]

# get structure needed for validation HIT
num=floor(nrow(LotS_reorder)/6) # will have 2 leftover
LotS_1 = LotS_reorder[1:num,]
LotS_2 = LotS_reorder[(num+1):(num*2),]
LotS_3 = LotS_reorder[((num*2)+1):(num*3),]
LotS_4 = LotS_reorder[((num*3)+1):(num*4),]
LotS_5 = LotS_reorder[((num*4)+1):(num*5),]
LotS_6 = LotS_reorder[((num*5)+1):(num*6),]

colnames(LotS_1)<-unlist(lapply(names(LotS_1), function(x) paste0(x,"_1")))
colnames(LotS_2)<-unlist(lapply(names(LotS_2), function(x) paste0(x,"_2")))
colnames(LotS_3)<-unlist(lapply(names(LotS_3), function(x) paste0(x,"_3")))
colnames(LotS_4)<-unlist(lapply(names(LotS_4), function(x) paste0(x,"_4")))
colnames(LotS_5)<-unlist(lapply(names(LotS_5), function(x) paste0(x,"_5")))
colnames(LotS_6)<-unlist(lapply(names(LotS_6), function(x) paste0(x,"_6")))

full_LotS_val = cbind(LotS_1,LotS_2,LotS_3,LotS_4,LotS_5,LotS_6)
full_LotS_val$group = "group1"
full_LotS_val$round = "round1"

write.csv(file="files/VALIDATION_csv_for_mturk_upload/round1_LotS_batch1.csv",full_LotS_val,row.names = F)


# ---------- LitL PROTOCOL
LitL$round<-"round1"
LitL_anon<-merge(LitL,anon_codes,by="WorkerId")
LitL_transformed<-LitL_anon%>%
  filter(Input.splits=="dev")%>%
  select(AnonId,Input.promptID,Input.premise,Answer.entailment,Answer.neutral,Answer.contradiction)%>%
  rename("promptID"=Input.promptID,
         "premise"=Input.premise,
         "entailment"=Answer.entailment,
         "neutral"=Answer.neutral,
         "contradiction"=Answer.contradiction,
         "annotator1_ID"=AnonId)%>%
  gather("annotator1_label","hypothesis",-promptID,-premise,-annotator1_ID)%>%
  mutate("pairID"=ifelse(annotator1_label=="entailment",paste0(promptID,"e"),
                         ifelse(annotator1_label=="neutral",paste0(promptID,"n"),
                                ifelse(annotator1_label=="contradiction",paste0(promptID,"c"),"problem"))))

# randomize order
LitL_reorder <- LitL_transformed[sample(1:nrow(LitL_transformed)), ]

# get structure needed for validation HIT
num=floor(nrow(base_reorder)/6) # will have 2 leftover
LitL_1 = LitL_reorder[1:num,]
LitL_2 = LitL_reorder[(num+1):(num*2),]
LitL_3 = LitL_reorder[((num*2)+1):(num*3),]
LitL_4 = LitL_reorder[((num*3)+1):(num*4),]
LitL_5 = LitL_reorder[((num*4)+1):(num*5),]
LitL_6 = LitL_reorder[((num*5)+1):(num*6),]

colnames(LitL_1)<-unlist(lapply(names(LitL_1), function(x) paste0(x,"_1")))
colnames(LitL_2)<-unlist(lapply(names(LitL_2), function(x) paste0(x,"_2")))
colnames(LitL_3)<-unlist(lapply(names(LitL_3), function(x) paste0(x,"_3")))
colnames(LitL_4)<-unlist(lapply(names(LitL_4), function(x) paste0(x,"_4")))
colnames(LitL_5)<-unlist(lapply(names(LitL_5), function(x) paste0(x,"_5")))
colnames(LitL_6)<-unlist(lapply(names(LitL_6), function(x) paste0(x,"_6")))

full_LitL_val = cbind(LitL_1,LitL_2,LitL_3,LitL_4,LitL_5,LitL_6)
full_LitL_val$group = "group1"
full_LitL_val$round = "round1"

write.csv(file="files/VALIDATION_csv_for_mturk_upload/round1_LitL_batch1.csv",full_LitL_val,row.names = F)

