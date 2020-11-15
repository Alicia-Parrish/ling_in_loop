library(tidyverse)
library(rjson)
library(jsonlite)

setwd("C:/Users/NYUCM Loaner Access/Documents/GitHub/ling_in_loop/scripts")

set.seed(42)

anon_codes = read.csv("../../SECRET/ling_in_loop_SECRET/anonymized_id_links.csv")

round = "round3" # change this value each round

#################### FUNCTIONS ####################
transform_data = function(dat,heur){
  dat2<-dat%>%
    filter(Input.splits=="train")%>%
    #select(AnonId,group,round,Input.promptID,Input.premise,Answer.entailment,Answer.neutral,Answer.contradiction,heuristic,heuristic_checked)%>% # round 2
    {if(!heur) select(.,AnonId,group,round,Input.promptID,Input.premise,Answer.entailment,Answer.neutral,Answer.contradiction) else . } %>%
    {if(heur) select(.,AnonId,group,round,Input.promptID,Input.premise,Answer.entailment,Answer.neutral,Answer.contradiction,
                     Input.heuristic_value, Answer.constraint_contradiciton, Answer.constraint_entailment, Answer.constraint_neutral) else . } %>%
    rename("promptID" = Input.promptID,
           "premise" = Input.premise,
           "entailment" = Answer.entailment,
           "neutral" = Answer.neutral,
           "contradiction" = Answer.contradiction)%>%
    {if(heur) rename(.,"heuristic" = Input.heuristic_value) else . } %>%
    #gather("label","hypothesis",-promptID,-premise,-AnonId,-group,-round,-heuristic,-heuristic_checked)%>% # round 2
    {if(heur) gather(.,"label","hypothesis",-promptID,-premise,-AnonId,-group,-round,-heuristic,
                      -Answer.constraint_contradiciton, -Answer.constraint_entailment, -Answer.constraint_neutral) else .} %>%
    {if(heur) mutate(.,"heuristic_checked" = case_when(label=="contradiction" ~ Answer.constraint_contradiciton,
                                                       label=="entailment" ~ Answer.constraint_entailment,
                                                       label=="neutral" ~ Answer.constraint_neutral)) else .} %>%
    {if(heur) mutate(., "heuristic_checked" = case_when(heuristic_checked=="" ~ "No",
                                                        heuristic_checked!="" ~ "Yes")) else .}%>%
    {if(heur) select(., -Answer.constraint_contradiciton, -Answer.constraint_entailment, -Answer.constraint_neutral) else .} %>%
    {if(!heur) gather(.,"label","hypothesis",-promptID,-premise,-AnonId,-group,-round) else .} %>%
    mutate("pairID"=ifelse(label=="entailment",paste0(promptID,"e"),
                           ifelse(label=="neutral",paste0(promptID,"n"),
                                  ifelse(label=="contradiction",paste0(promptID,"c"),"problem"))))
  return(dat2)
}

# function for reading in .jsonl files
read_json_lines <- function(file){
  con <- file(file, open = "r")
  on.exit(close(con))
  jsonlite::stream_in(con, verbose = FALSE)
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
  #temp$heuristic = NA # needed with round2
  #temp$heuristic_checked = NA # needed with round2
  base = rbind(base,temp)
}
for(i in 1:length(LotS_files)){
  temp = read.csv(LotS_files[i])
  #heuristic_used = as.character(unique(temp$Answer.constraint_1)) # needed with round2
  #heuristic_used = heuristic_used[heuristic_used != ""] # needed with round2
  #temp$heuristic = heuristic_used # needed with round2
  #temp2 = temp %>% mutate(heuristic_checked = case_when(Answer.constraint_1 != heuristic ~ "No", # needed with round2
  #                                                      Answer.constraint_1 == heuristic ~ "Yes"))
  this_heur = as.character(unique(temp$Input.heuristic_value))
  if(this_heur=="hyponym"){temp$Input.heuristic_value="hypernym"} # I flipped these in round 3, whoops
  if(this_heur=="hypernym"){temp$Input.heuristic_value="hyponym"}
  LotS = rbind(LotS,temp)
}
for(i in 1:length(LitL_files)){
  temp = read.csv(LitL_files[i])
  #heuristic_used = as.character(unique(temp$Answer.constraint_1)) # needed with round2
  #heuristic_used = heuristic_used[heuristic_used != ""] # needed with round2
  #temp$heuristic = heuristic_used # needed with round2
  #temp2 = temp %>% mutate(heuristic_checked = case_when(Answer.constraint_1 != heuristic ~ "No", # needed with round2
  #                                                      Answer.constraint_1 == heuristic ~ "Yes"))
  this_heur = as.character(unique(temp$Input.heuristic_value))
  if(this_heur=="hyponym"){temp$Input.heuristic_value="hypernym"} # I flipped these in round 3, whoops
  if(this_heur=="hypernym"){temp$Input.heuristic_value="hyponym"}
  LitL = rbind(LitL,temp)
}

#################### TRANSFORM ####################

# ---------- BASELINE PROTOCOL
base_anon<-merge(base,anon_codes,by="WorkerId")
base_anon$round<-round

base_anon_transformed = transform_data(base_anon,heur=F)

for(i in 1:nrow(base_anon_transformed)){
  base_anon_transformed$annotator_labels[i] = list(base_anon_transformed$label[i])
}


# ---------- LotS PROTOCOL
LotS_anon<-merge(LotS,anon_codes,by="WorkerId")
LotS_anon$round<-round
LotS_anon_transformed <- transform_data(LotS_anon,heur=T)


for(i in 1:nrow(LotS_anon_transformed)){
  LotS_anon_transformed$annotator_labels[i] = list(LotS_anon_transformed$label[i])
}


# ---------- LitL PROTOCOL
LitL_anon<-merge(LitL,anon_codes,by="WorkerId")
LitL_anon$round<-round
LitL_anon_transformed <- transform_data(LitL_anon,heur=T)

for(i in 1:nrow(LitL_anon_transformed)){
  LitL_anon_transformed$annotator_labels[i] = list(LitL_anon_transformed$label[i])
}


#################### ADD RELELVANT GLUE LABELS ####################
glue_labels = data.frame(matrix(ncol = 2, nrow = 5))
colnames(glue_labels)<-c("heuristic","glue_labels")

glue_labels$heuristic = unique(LotS_anon_transformed$heuristic)

# need to do each of these individually each time
glue_labels$glue_labels[glue_labels$heuristic=="antonym"] = list(c("Lexical entailment"))
#glue_labels$glue_labels[glue_labels$heuristic=="temporal_reasoning"] = list(c("Temporal", "Temporal;Intervals/Numbers"))
#glue_labels$glue_labels[glue_labels$heuristic=="restricted_word_in_diff_label"] = list(c(""))
#glue_labels$glue_labels[glue_labels$heuristic=="relative_clause"] = list(c("Relative clauses;Restrictivity", "Relative clauses"))
glue_labels$glue_labels[glue_labels$heuristic=="sub_part"] = list(c("World knowledge"))
glue_labels$glue_labels[glue_labels$heuristic=="hyponym"] = list(c("Lexical entailment"))
glue_labels$glue_labels[glue_labels$heuristic=="hypernym"] = list(c("Lexical entailment"))
glue_labels$glue_labels[glue_labels$heuristic=="reverse_argument_order"] = list(c("Active/Passive"))

# add to LotS
LotS_glue = merge(LotS_anon_transformed, glue_labels)

# add to LitL
LitL_glue = merge(LitL_anon_transformed, glue_labels)

#################### FINAL REORDERING AND DROPPING ####################

# baseline
base_anon_transformed2<-base_anon_transformed%>%
  select(AnonId,group,round,annotator_labels,label,pairID,promptID,premise,hypothesis)%>% # ,heuristic,heuristic_checked)%>%
  #select(-heuristic,-heuristic_checked)%>% # round 2
  filter(!is.na(hypothesis), hypothesis!="", hypothesis != "{}")

# Ling on the side
LotS_anon_transformed2<-LotS_glue%>%
  select(AnonId,group,round,annotator_labels,label,pairID,promptID,premise,hypothesis,heuristic,heuristic_checked,glue_labels)%>%
  filter(!is.na(hypothesis), hypothesis!="", hypothesis != "{}")

# Ling in the loop
LitL_anon_transformed2<-LitL_glue%>%
  select(AnonId,group,round,annotator_labels,label,pairID,promptID,premise,hypothesis,heuristic,heuristic_checked,glue_labels)%>%
  filter(!is.na(hypothesis), hypothesis!="", hypothesis != "{}")

#################### SAVE ####################

jsonlite::stream_out(base_anon_transformed2, file(paste0('../NLI_data/1_Baseline_protocol/train_',round,'_baseline.jsonl')))
jsonlite::stream_out(LotS_anon_transformed2, file(paste0('../NLI_data/2_Ling_on_side_protocol/train_',round,'_LotS.jsonl')))
jsonlite::stream_out(LitL_anon_transformed2, file(paste0('../NLI_data/3_Ling_in_loop_protocol/train_',round,'_LitL.jsonl')))

#################### MAKE COMBINED FILES #########################

base_jsonl_files<-list.files('../NLI_data/1_Baseline_protocol/',full.names=T, pattern = "train_.*_baseline.jsonl")
LotS_jsonl_files<-list.files('../NLI_data/2_Ling_on_side_protocol/',full.names=T, pattern = "train_.*_LotS.jsonl")
LitL_jsonl_files<-list.files('../NLI_data/3_Ling_in_loop_protocol/',full.names=T, pattern = "train_.*_LitL.jsonl")

all_base_jsonl = NULL
all_LotS_jsonl = NULL
all_LitL_jsonl = NULL

for(i in 1:length(base_jsonl_files)){
  temp = read_json_lines(base_jsonl_files[i])
  temp = temp %>%
    filter(!is.na(hypothesis))%>%
    filter(hypothesis!="")%>%
    filter(hypothesis!="{}")
  all_LotS_jsonl = rbind(all_LotS_jsonl,temp)
  all_base_jsonl = rbind(all_base_jsonl,temp)
}
for(i in 1:length(LotS_jsonl_files)){
  temp = read_json_lines(LotS_jsonl_files[i])
  if(!"heuristic" %in% colnames(temp)){
    temp$heuristic = NA
    temp$heuristic_checked = NA
    temp$glue_labels = NA
  }
  temp = temp %>%
    filter(!is.na(hypothesis))%>%
    filter(hypothesis!="")%>%
    filter(hypothesis!="{}")
  all_LotS_jsonl = rbind(all_LotS_jsonl,temp)
}
for(i in 1:length(LitL_jsonl_files)){
  temp = read_json_lines(LitL_jsonl_files[i])
  if(!"heuristic" %in% colnames(temp)){
    temp$heuristic = NA
    temp$heuristic_checked = NA
    temp$glue_labels = NA
  }
  temp = temp %>%
    filter(!is.na(hypothesis))%>%
    filter(hypothesis!="")%>%
    filter(hypothesis!="{}")
  all_LotS_jsonl = rbind(all_LotS_jsonl,temp)
  all_LitL_jsonl = rbind(all_LitL_jsonl,temp)
}

all_LotS_jsonl2 = all_LotS_jsonl %>%
  filter(!is.na(hypothesis))%>%
  filter(hypothesis!="")%>%
  filter(hypothesis!="{}")

jsonlite::stream_out(all_base_jsonl, file(paste0('../NLI_data/1_Baseline_protocol/train_',round,'_baseline_combined.jsonl')))
jsonlite::stream_out(all_LotS_jsonl2, file(paste0('../NLI_data/2_Ling_on_side_protocol/train_',round,'_LotS_combined.jsonl')))
jsonlite::stream_out(all_LitL_jsonl, file(paste0('../NLI_data/3_Ling_in_loop_protocol/train_',round,'_LitL_combined.jsonl')))

