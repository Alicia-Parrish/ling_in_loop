library(tidyverse)
library(rjson)
library(jsonlite)

setwd("C:/Users/NYUCM Loaner Access/Documents/GitHub/ling_in_loop/scripts")

set.seed(42)

anon_codes = read.csv("../../SECRET/ling_in_loop_SECRET/anonymized_id_links.csv")

round = "round2" # change this value each round

#################### FUNCTIONS ####################
transform_data = function(dat){
  dat2<-dat%>%
    filter(Input.splits=="train")%>%
    select(AnonId,group,round,Input.promptID,Input.premise,Answer.entailment,Answer.neutral,Answer.contradiction,heuristic,heuristic_checked)%>%
    rename("promptID" = Input.promptID,
           "premise" = Input.premise,
           "entailment" = Answer.entailment,
           "neutral" = Answer.neutral,
           "contradiction" = Answer.contradiction)%>%
    gather("label","hypothesis",-promptID,-premise,-AnonId,-group,-round,-heuristic,-heuristic_checked)%>%
    mutate("pairID"=ifelse(label=="entailment",paste0(promptID,"e"),
                           ifelse(label=="neutral",paste0(promptID,"n"),
                                  ifelse(label=="contradiction",paste0(promptID,"c"),"problem"))))
  return(dat2)
}

#################### READ IN ####################

base<-NULL
LotS<-NULL
LitL<-NULL

base_files = list.files(paste0("../../SECRET/ling_in_loop_SECRET/raw_mturk_files/Group1_baseline/",round,"_writing"),full.names=T, pattern = "*.csv")
LotS_files = list.files(paste0("../../SECRET/ling_in_loop_SECRET/raw_mturk_files/Group2_ling_on_side/",round,"_writing"),full.names=T, pattern = "*.csv")
LitL_files = list.files(paste0("../../SECRET/ling_in_loop_SECRET/raw_mturk_files/Group3_ling_in_loop/",round,"_writing"),full.names=T, pattern = "*.csv")

#################### AGGREGATE ####################

for(i in 1:length(base_files)){
  temp = read.csv(base_files[i])
  temp$heuristic = NA
  temp$heuristic_checked = NA
  base = rbind(base,temp)
}
for(i in 1:length(LotS_files)){
  temp = read.csv(LotS_files[i])
  heuristic_used = as.character(unique(temp$Answer.constraint_1))
  heuristic_used = heuristic_used[heuristic_used != ""]
  temp$heuristic = heuristic_used
  temp2 = temp %>% mutate(heuristic_checked = case_when(Answer.constraint_1 != heuristic ~ "No",
                                                        Answer.constraint_1 == heuristic ~ "Yes"))
  LotS = rbind(LotS,temp2)
}
for(i in 1:length(LitL_files)){
  temp = read.csv(LitL_files[i])
  heuristic_used = as.character(unique(temp$Answer.constraint_1))
  heuristic_used = heuristic_used[heuristic_used != ""]
  temp$heuristic = heuristic_used
  temp2 = temp %>% mutate(heuristic_checked = case_when(Answer.constraint_1 != heuristic ~ "No",
                                                        Answer.constraint_1 == heuristic ~ "Yes"))
  LitL = rbind(LitL,temp2)
}

#################### TRANSFORM ####################

# ---------- BASELINE PROTOCOL
base_anon<-merge(base,anon_codes,by="WorkerId")
base_anon$round<-round

base_anon_transformed = transform_data(base_anon)

for(i in 1:length(base_anon_transformed)){
  base_anon_transformed$annotator_labels[i] = list(base_anon_transformed$label[i])
}


# ---------- LotS PROTOCOL
LotS_anon<-merge(LotS,anon_codes,by="WorkerId")
LotS_anon$round<-round
LotS_anon_transformed <- transform_data(LotS_anon)

for(i in 1:length(LotS_anon_transformed)){
  LotS_anon_transformed$annotator_labels[i] = list(LotS_anon_transformed$label[i])
}


# ---------- LitL PROTOCOL
LitL_anon<-merge(LitL,anon_codes,by="WorkerId")
LitL_anon$round<-"round1"
LitL_anon_transformed <- transform_data(LitL_anon)

for(i in 1:length(LitL_anon_transformed)){
  LitL_anon_transformed$annotator_labels[i] = list(LitL_anon_transformed$label[i])
}


#################### ADD RELELVANT GLUE LABELS ####################
glue_labels = data.frame(matrix(ncol = 2, nrow = 7))
colnames(glue_labels)<-c("heuristic","glue_labels")

glue_labels$heuristic = unique(LotS_anon_transformed$heuristic)

# need to do each of these individually each time
glue_labels$glue_labels[glue_labels$heuristic=="synonym_antonym"] = list(c("Lexical entailment"))
glue_labels$glue_labels[glue_labels$heuristic=="temporal_reasoning"] = list(c("Temporal", "Temporal;Intervals/Numbers"))
glue_labels$glue_labels[glue_labels$heuristic=="restricted_word_in_diff_label"] = list(c(""))
glue_labels$glue_labels[glue_labels$heuristic=="relative_clause"] = list(c("Relative clauses;Restrictivity", "Relative clauses"))
glue_labels$glue_labels[glue_labels$heuristic=="background_knowledge"] = list(c("World knowledge"))
glue_labels$glue_labels[glue_labels$heuristic=="hypernym_hyponym"] = list(c("Lexical entailment"))
glue_labels$glue_labels[glue_labels$heuristic=="reverse_argument_order"] = list(c("Active/Passive"))

# add to LotS
LotS_glue = merge(LotS_anon_transformed, glue_labels)

# add to LitL
LitL_glue = merge(LitL_anon_transformed, glue_labels)

#################### FINAL REORDERING AND DROPPING ####################

# baseline
base_anon_transformed2<-base_anon_transformed%>%
  select(AnonId,group,round,annotator_labels,label,pairID,promptID,premise,hypothesis,heuristic,heuristic_checked)%>%
  select(-heuristic,-heuristic_checked)%>%
  filter(!is.na(hypothesis), hypothesis!="")

# Ling on the side
LotS_anon_transformed2<-LotS_glue%>%
  select(AnonId,group,round,annotator_labels,label,pairID,promptID,premise,hypothesis,heuristic,heuristic_checked,glue_labels)%>%
  filter(!is.na(hypothesis), hypothesis!="")

# Ling in the loop
LitL_anon_transformed2<-LitL_glue%>%
  select(AnonId,group,round,annotator_labels,label,pairID,promptID,premise,hypothesis,heuristic,heuristic_checked,glue_labels)%>%
  filter(!is.na(hypothesis), hypothesis!="")

#################### SAVE ####################

jsonlite::stream_out(base_anon_transformed, file(paste0('../NLI_data/1_Baseline_protocol/train_',round,'_baseline.jsonl')))
jsonlite::stream_out(LotS_anon_transformed_glue, file(paste0('../NLI_data/2_Ling_on_side_protocol/train_',round,'_LotS.jsonl')))
jsonlite::stream_out(LitL_anon_transformed_glue, file(paste0('../NLI_data/3_Ling_in_loop_protocol/train_',round,'_LitL.jsonl')))

