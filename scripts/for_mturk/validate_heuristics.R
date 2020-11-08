library(tidyverse)
library(rjson)
library(jsonlite)

setwd("C:/Users/NYUCM Loaner Access/Documents/GitHub/ling_in_loop/scripts")

set.seed(42)
round = "round2"

# banned words
words_e <- c("some", "there", "something", "people")
words_n <- c("many", "most", "may ", "might")
words_c <- c("not","n't","never","none","no")

#################### FUNCTIONS ####################
# function for reading in .jsonl files
read_json_lines <- function(file){
  con <- file(file, open = "r")
  on.exit(close(con))
  jsonlite::stream_in(con, verbose = FALSE)
}

# check for banned word
identify_banned_words<-function(dat){
  dat$present = NA
  for(i in 1:nrow(dat)){
    words = unlist(strsplit(dat$hypothesis[i]," "))
    for(j in 1:length(words)){
      if(dat$label[i]=="entailment" & words[j] %in% words_e){dat$present[i]<-as.character(words[j])}
      if(dat$label[i]=="neutral" & words[j] %in% words_n){dat$present[i]<-as.character(words[j])}
      if(dat$label[i]=="contradiction" & words[j] %in% words_c){dat$present[i]<-as.character(words[j])}
    }
  }
  dat<-dat%>%
    mutate(score=ifelse(!is.na(present),1,0))
  return(dat)
}

# combine train and val for looking at restricted words
combine_dats_for_restricted_words<-function(train,val){
  val2<-val%>%
    select(annotator_ids,label,pairID,hypothesis)
  train2<-train%>%
    select(AnonId,label,pairID,hypothesis)%>%
    rename("annotator_ids"=AnonId)
  dats=rbind(val2,train2)
  return(dats)
}

# check heuristic: restricted word in another label
identify_resticted_word_diff_label<-function(dat){
  dat$present = NA
  for(i in 1:nrow(dat)){
    words = unlist(strsplit(dat$hypothesis[i]," "))
    for(j in 1:length(words)){
      if(dat$label[i]=="entailment" & words[j] %in% words_c){dat$present[i]<-as.character(words[j])}
      if(dat$label[i]=="neutral" & words[j] %in% words_c){dat$present[i]<-as.character(words[j])}
      if(dat$label[i]=="contradiction" & words[j] %in% words_n){dat$present[i]<-as.character(words[j])}
      if(dat$label[i]=="entailment" & words[j] %in% words_n){dat$present[i]<-as.character(words[j])}
      if(dat$label[i]=="neutral" & words[j] %in% words_e){dat$present[i]<-as.character(words[j])}
      if(dat$label[i]=="contradiction" & words[j] %in% words_e){dat$present[i]<-as.character(words[j])}
    }
  }
  dat<-dat%>%
    mutate(score=ifelse(!is.na(present),1,0))
  return(dat)
}

# check heuristic: relative clause
identify_likely_rel_c<-function(dat){
  c_embed_verbs<-c("think","thinks","thought",
                   "know","knows","knew",
                   "believe","believes","believed",
                   "claim","claims","claimed")
  dat$present = NA
  for(i in 1:nrow(dat)){
    words = unlist(strsplit(dat$hypothesis[i]," "))
    for(j in 1:length(words)){
      if(words[j] %in% c("that","who","which")){dat$present[i]<-as.character(words[j])}
    }
    if(tail(words,1)=="that"){dat$present[i]=NA} # don't mark if 'that' is the last word
    idx<-match(c("that"),words)
    if(words[idx-1] %in% c_embed_verbs){dat$present[i]=NA} # don't mark if 'it's'that' is likely embedding a clause
  }
  dat<-dat%>%
    mutate(score=ifelse(!is.na(present),1,0))
  return(dat)
}

#################### READ IN ####################
anon_codes = read.csv("../../SECRET/ling_in_loop_SECRET/anonymized_id_links.csv")
base_val<-read_json_lines(paste0("../NLI_data/1_Baseline_protocol/val_",round,"_base.jsonl"))
LotS_val<-read_json_lines(paste0("../NLI_data/2_Ling_on_side_protocol/val_",round,"_LotS.jsonl"))
LitL_val<-read_json_lines(paste0("../NLI_data/3_Ling_in_loop_protocol/val_",round,"_LitL.jsonl"))
base_train<-read_json_lines(paste0("../NLI_data/1_Baseline_protocol/train_",round,"_baseline.jsonl"))
LotS_train<-read_json_lines(paste0("../NLI_data/2_Ling_on_side_protocol/train_",round,"_LotS.jsonl"))
LitL_train<-read_json_lines(paste0("../NLI_data/3_Ling_in_loop_protocol/train_",round,"_LitL.jsonl"))

#################### BANNED WORDS IN TRAIN & VAL DATA ####################
bases = combine_dats_for_restricted_words(train=base_train,val=base_val)
bases_banned_words = identify_banned_words(bases)
bases_banned_words_summary = bases_banned_words %>%
  group_by(label)%>%
  summarise(total=mean(score),count=n())

LotSs = combine_dats_for_restricted_words(train=LotS_train,val=LotS_val)
LotS_banned_words = identify_banned_words(LotSs)
LotS_banned_words_summary = LotS_banned_words %>%
  group_by(label)%>%
  summarise(total=mean(score),count=n())

LitLs = combine_dats_for_restricted_words(train=LitL_train,val=LitL_val)
LitL_banned_words = identify_banned_words(LitLs)
LitL_banned_words_summary = LitL_banned_words %>%
  group_by(label)%>%
  summarise(total=mean(score),count=n())

#################### HEURISTIC: RESTRICTED WORD IN DIFF LABEL (JUST VAL) ####################
# LotS
LotS_just_restricted_word<-LotS_val%>%
  filter(heuristic=="restricted_word_in_diff_label")
LotS_restricted_heuristic<-identify_resticted_word_diff_label(LotS_just_restricted_word)

LotS_restricted_heuristic$heuristic_labels<-lapply(LotS_restricted_heuristic$heuristic_labels, setdiff, '{}')

LotS_restricted_heuristic2<-LotS_restricted_heuristic%>%
  mutate(heuristic_gold_label = case_when(score==0 ~ "No",
                                          score==1 ~ "Yes"))%>%
  select(-present,-score)

# LitL
LitL_just_restricted_word<-LitL_val%>%
  filter(heuristic=="restricted_word_in_diff_label")
LitL_restricted_heuristic<-identify_resticted_word_diff_label(LitL_just_restricted_word)

LitL_restricted_heuristic$heuristic_labels<-lapply(LitL_restricted_heuristic$heuristic_labels, setdiff, '{}')

LitL_restricted_heuristic2<-LitL_restricted_heuristic%>%
  mutate(heuristic_gold_label = case_when(score==0 ~ "No",
                                          score==1 ~ "Yes"))%>%
  select(-present,-score)

#################### HEURISTIC: RELATIVE CLAUSE (JUST VAL) ####################
# LotS
LotS_just_rel_c<-LotS_val%>%
  filter(heuristic=="relative_clause")
LotS_rel_c<-identify_likely_rel_c(LotS_just_rel_c)

LotS_rel_c$heuristic_labels<-lapply(LotS_rel_c$heuristic_labels, setdiff, '{}')

LotS_rel_c2<-LotS_rel_c%>%
  mutate(heuristic_gold_label = case_when(score==0 ~ "No",
                                          score==1 ~ "Yes"))%>%
  select(-present,-score)

# LitL
LitL_just_rel_c<-LitL_val%>%
  filter(heuristic=="relative_clause")
LitL_rel_c<-identify_likely_rel_c(LitL_just_rel_c)

LitL_rel_c$heuristic_labels<-lapply(LitL_rel_c$heuristic_labels, setdiff, '{}')

LitL_rel_c2<-LitL_rel_c%>%
  mutate(heuristic_gold_label = case_when(score==0 ~ "No",
                                          score==1 ~ "Yes"))%>%
  select(-present,-score)

#################### PUT VALIDATION BACK TOGETHER ####################
# LotS
LotS_others<-LotS_val%>%
  filter(heuristic!="relative_clause", heuristic!="restricted_word_in_diff_label")
Lots_val_all<-rbind(LotS_others,LotS_restricted_heuristic2,LotS_rel_c2)

# LitL
LitL_others<-LitL_val%>%
  filter(heuristic!="relative_clause", heuristic!="restricted_word_in_diff_label")
LitL_val_all<-rbind(LitL_others,LitL_restricted_heuristic2,LitL_rel_c2)

#################### ADD RELELVANT GLUE LABELS ####################
glue_labels = data.frame(matrix(ncol = 2, nrow = 7))
colnames(glue_labels)<-c("heuristic","glue_labels")

glue_labels$heuristic = unique(LitL_val_all$heuristic)

# need to do each of these individually each time
glue_labels$glue_labels[glue_labels$heuristic=="synonym_antonym"] = list(c("Lexical entailment"))
glue_labels$glue_labels[glue_labels$heuristic=="temporal_reasoning"] = list(c("Temporal", "Temporal;Intervals/Numbers"))
glue_labels$glue_labels[glue_labels$heuristic=="restricted_word_in_diff_label"] = list(c(""))
glue_labels$glue_labels[glue_labels$heuristic=="relative_clause"] = list(c("Relative clauses;Restrictivity", "Relative clauses"))
glue_labels$glue_labels[glue_labels$heuristic=="background_knowledge"] = list(c("World knowledge"))
glue_labels$glue_labels[glue_labels$heuristic=="hypernym_hyponym"] = list(c("Lexical entailment"))
glue_labels$glue_labels[glue_labels$heuristic=="reverse_argument_order"] = list(c("Active/Passive"))

# add to LotS
Lots_val_all_glue = merge(Lots_val_all, glue_labels, by="heuristic")
Lots_val_all_glue<-Lots_val_all_glue%>%
  select(annotator_ids,annotator_labels,label,pairID,promptID,premise,hypothesis,heuristic,heuristic_labels,heuristic_gold_label,glue_labels,round,group)

# add to LitL
LitL_val_all_glue = merge(LitL_val_all, glue_labels, by="heuristic")
LitL_val_all_glue<-LitL_val_all_glue%>%
  select(annotator_ids,annotator_labels,label,pairID,promptID,premise,hypothesis,heuristic,heuristic_labels,heuristic_gold_label,glue_labels,round,group)



#################### SAVE ####################
# ---------- LING-ON-SIDE PROTOCOL
jsonlite::stream_out(Lots_val_all_glue, file(paste0('../NLI_data/2_Ling_on_side_protocol/val_',round,'_LotS.jsonl')))

# ---------- LING-IN-LOOP PROTOCOL
jsonlite::stream_out(LitL_val_all_glue, file(paste0('../NLI_data/3_Ling_in_loop_protocol/val_',round,'_LitL.jsonl')))
