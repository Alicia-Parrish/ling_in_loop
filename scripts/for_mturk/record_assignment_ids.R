library(tidyverse)

setwd("C:/Users/NYUCM Loaner Access/Documents/GitHub/ling_in_loop/scripts")

anon_codes = read.csv("../../SECRET/ling_in_loop_SECRET/anonymized_id_links.csv")

############### HIT info needed to pay bonus ###############

base_files = list.files("../../SECRET/ling_in_loop_SECRET/raw_mturk_files/Group1_baseline/Intro",full.names=T)
LotS_files = list.files("../../SECRET/ling_in_loop_SECRET/raw_mturk_files/Group2_ling_on_side/Intro",full.names=T)
LitL_files = list.files("../../SECRET/ling_in_loop_SECRET/raw_mturk_files/Group3_ling_in_loop/Intro",full.names=T)

base=NULL
LotS=NULL
LitL=NULL

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

base_ass_ids<-base%>%
  select(WorkerId,AssignmentId)
lots_ass_ids<-LotS%>%
  select(WorkerId,AssignmentId)
litl_ass_ids<-LitL%>%
  select(WorkerId,AssignmentId)

all_ass_ids<-rbind(base_ass_ids,lots_ass_ids,litl_ass_ids)

all_ass_ids_with_anon<-merge(all_ass_ids,anon_codes,by="WorkerId",all=T)

write.csv(all_ass_ids_with_anon,"../../SECRET/ling_in_loop_SECRET/assignment_ids.csv")
