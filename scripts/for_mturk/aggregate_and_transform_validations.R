library(tidyverse)
library(rjson)
library(jsonlite)
library(data.table)

setwd("C:/Users/NYUCM Loaner Access/Documents/GitHub/ling_in_loop/scripts")

set.seed(42)

anon_codes = read.csv("../../SECRET/ling_in_loop_SECRET/anonymized_id_links.csv")
round = "round2" # change this value each round

#################### FUNCTIONS ####################
smaller_data <- function(dat){
  colnames(dat) <- sub("AnonId","Annotator1_ID", colnames(dat))
  dat_anon<-merge(dat,anon_codes,by="WorkerId") # anonymize
  dat_smaller = select(dat_anon, matches("Answer|Input|AnonId")) # get only relevant columns
  colnames(dat_smaller) <-  sub("Answer.", "", colnames(dat_smaller)) # rename to get rid of mturk's automatically added notation
  colnames(dat_smaller) <-  sub("Input.", "", colnames(dat_smaller))
  #this_group = unique(dat_smaller$group) # save these values
  #this_round = unique(dat_smaller$round)
  dat_smaller2<-dat_smaller%>% # get rid of other unneeded columns
    select(-useragent,-response_ex,-numanswered,-comments,-group,-round)
  return(dat_smaller2)
}

long_data <- function(dat,heur){
  # separate into different dfs and adjust column names so they're the same
  dat_part1<-select(dat,matches("_1|anonId"))
  colnames(dat_part1) <- sub("_1","", colnames(dat_part1))
  dat_part2<-select(dat,matches("_2|anonId"))
  colnames(dat_part2) <- sub("_2","", colnames(dat_part2))
  dat_part3<-select(dat,matches("_3|anonId"))
  colnames(dat_part3) <- sub("_3","", colnames(dat_part3))
  dat_part4<-select(dat,matches("_4|anonId"))
  colnames(dat_part4) <- sub("_4","", colnames(dat_part4))
  dat_part5<-select(dat,matches("_5|anonId"))
  colnames(dat_part5) <- sub("_5","", colnames(dat_part5))
  dat_part6<-select(dat,matches("_6|anonId"))
  colnames(dat_part6) <- sub("_6","", colnames(dat_part6))
  # put them back together now that they all have the same name
  all_dat<-rbind(dat_part1,dat_part2,dat_part3,dat_part4,dat_part5,dat_part6)
  if(heur){
    all_dat<-all_dat%>%
      replace_na(list(heuristic_val="{}"))%>%
      filter(!heuristic_val=='')
  }
  all_dat2<-all_dat%>%
    filter(response!="")%>% # get rid of ones where the worker didn't answer
    filter(hypothesis!="{}")%>% # get rid of ones that were missing the hypothesis
    filter(pairID!=0) # get rid of ones I intentionally left blank
  return(all_dat2)
}

transform_data <- function(dat,heur){
  if(heur){ #this shouldn't be necessary, but I messed up the coding
    dat<-dat%>%
      mutate(response = case_when(response=="N" ~ "neutral",
                                  response=="E" ~ "entailment",
                                  response=="C" ~ "contradiction"))
    dat$response=as.factor(dat$response)
  }
  all_pairIds = unique(dat$pairID)
  # create df to fill in with values
  if(heur){
    dat_transformed=data.frame(matrix(ncol = 10, nrow = length(all_pairIds)))
    colnames(dat_transformed)<-c("annotator_ids","annotator_labels","label","pairID","promptID","premise","hypothesis","heuristic","heuristic_labels","heuristic_gold_label")
  }
  if(!heur){
    dat_transformed=data.frame(matrix(ncol = 7, nrow = length(all_pairIds)))
    colnames(dat_transformed)<-c("annotator_ids","annotator_labels","label","pairID","promptID","premise","hypothesis")
  }
  
  # does formatting needed for jiant
  for(i in 1:length(all_pairIds)){
    temp = filter(dat,pairID==all_pairIds[i]) # create df of just one pairId
    all_ids = list(as.character(temp$AnonId)) # keep track of annotator ids
    all_ids= list(unlist(append(as.character(temp$Annotator1_ID[1]),all_ids)))
    dat_transformed$annotator_ids[i] = all_ids
    all_labels = list(as.character(temp$response)) # keep track of labels
    all_labels= list(unlist(append(as.character(temp$label[1]),all_labels)))
    dat_transformed$annotator_labels[i] = all_labels
    num_e = sum(str_count(unlist(all_labels),"entailment")) # get number of each kind of label
    num_n = sum(str_count(unlist(all_labels),"neutral"))
    num_c = sum(str_count(unlist(all_labels),"contradiction"))
    gold_label = ifelse(num_e>=3,"entailment", # calculate gold label
                        ifelse(num_n>=3,"neutral",
                               ifelse(num_c>=3,"contradiction","no_winner")))
    dat_transformed$label[i] = as.character(gold_label)
    new_pairId = ifelse(gold_label=="entailment", paste0(temp$promptID[1],"e"), # use gold label to get new pairId
                        ifelse(gold_label=="neutral", paste0(temp$promptID[1],"n"),
                               ifelse(gold_label=="contradiction", paste0(temp$promptID[1],"c"),"no_winner")))
    dat_transformed$pairID[i] = as.character(new_pairId)
    dat_transformed$promptID[i] = as.character(temp$promptID[1])
    dat_transformed$premise[i] = as.character(temp$premise[1])
    dat_transformed$hypothesis[i] = as.character(temp$hypothesis[1])
    if(heur){
      dat_transformed$heuristic[i] = as.character(temp$heuristic[1])
      all_h_labels = list(as.character(temp$heuristic_val))
      all_h_labels= list(unlist(append(as.character(temp$heuristic_checked[1]),all_h_labels)))
      dat_transformed$heuristic_labels[i] = all_h_labels
      num_yes = sum(str_count(unlist(all_h_labels),"Yes")) # get number of each kind of label
      num_no = sum(str_count(unlist(all_h_labels),"No"))
      gold_h_label = ifelse(num_yes>=3,"Yes", # calculate gold label
                          ifelse(num_no>=3,"No","no_winner"))
      dat_transformed$heuristic_gold_label[i] = as.character(gold_h_label)
    }
  }
  return(dat_transformed)
}

add_missing_columns<-function(dat){
  dat$Answer.heuristic_val_1 = NA
  dat$Answer.heuristic_val_2 = NA
  dat$Answer.heuristic_val_3 = NA
  dat$Answer.heuristic_val_4 = NA
  dat$Answer.heuristic_val_5 = NA
  dat$Answer.heuristic_val_6 = NA
  return(dat)
}

#################### READ IN AND AGGREGATE ####################

base<-NULL
LotS<-NULL
LitL<-NULL

base_files = list.files(paste0("../../SECRET/ling_in_loop_SECRET/raw_mturk_files/Group1_baseline/",round,"_validation"),full.names=T,pattern="*.csv")
LotS_files = list.files(paste0("../../SECRET/ling_in_loop_SECRET/raw_mturk_files/Group2_ling_on_side/",round,"_validation"),full.names=T,pattern="*.csv")
LitL_files = list.files(paste0("../../SECRET/ling_in_loop_SECRET/raw_mturk_files/Group3_ling_in_loop/",round,"_validation"),full.names=T,pattern="*.csv")

for(i in 1:length(base_files)){
  temp = read.csv(base_files[i],stringsAsFactors=FALSE)
  base = rbind(base,temp)
}
for(i in 1:length(LotS_files)){
  temp = read.csv(LotS_files[i],stringsAsFactors=FALSE)
  temp2 = select(temp, -matches("heuristic_description|heuristic_example")) # get only relevant columns
  if(!"Answer.heuristic_val_1" %in% names(temp2)){temp2=add_missing_columns(temp2)}
  LotS = rbind(LotS,temp2)
}
for(i in 1:length(LitL_files)){
  temp = read.csv(LitL_files[i],stringsAsFactors=FALSE)
  temp2 = select(temp, -matches("heuristic_description|heuristic_example")) # get only relevant columns
  if(!"Answer.heuristic_val_1" %in% names(temp2)){temp2=add_missing_columns(temp2)}
  LitL = rbind(LitL,temp2)
}

#################### TRANSFORM DATA ####################

# ---------- BASELINE PROTOCOL
base_smaller<-smaller_data(base)
base_long <- long_data(base_smaller,heur=F)

base_transformed <- transform_data(dat=base_long, heur=F)

# add values back in
base_transformed$round = round
base_transformed$group = "group1"

base_transformed<-filter(base_transformed,!is.na(promptID))

# validation failures
base_fails<-filter(base_transformed,label=="no_winner")
# validation passes
base_pass<-filter(base_transformed,label!="no_winner")


# ---------- LING-ON-SIDE PROTOCOL
LotS_smaller <- smaller_data(LotS)
LotS_long <- long_data(LotS_smaller,heur=T)

LotS_transformed<-transform_data(LotS_long, heur=T)

# add values back in
LotS_transformed$round = round
LotS_transformed$group = "group2"

LotS_transformed<-filter(LotS_transformed,!is.na(promptID))

# validation failures
LotS_fails<-filter(LotS_transformed,label=="no_winner")
# validation passes
LotS_pass<-filter(LotS_transformed,label!="no_winner")



# ---------- LING-IN-LOOP PROTOCOL
LitL_smaller <- smaller_data(LitL)
LitL_long <- long_data(LitL_smaller,heur=T)

LitL_transformed<-transform_data(LitL_long, heur=T)

# add values back in
LitL_transformed$round = round
LitL_transformed$group = "group3"

LitL_transformed<-filter(LitL_transformed,!is.na(promptID))
LitL_transformed<-filter(LitL_transformed,promptID!='49943') # problem just during round 2

# validation failures
LitL_fails<-filter(LitL_transformed,label=="no_winner")
# validation passes
LitL_pass<-filter(LitL_transformed,label!="no_winner")


#################### SAVE DATA ####################

# ---------- BASELINE PROTOCOL
jsonlite::stream_out(base_pass, file(paste0('../NLI_data/1_Baseline_protocol/val_',round,'_base.jsonl')))
jsonlite::stream_out(base_transformed, file(paste0('../../SECRET/ling_in_loop_SECRET/full_validation_files/val_',round,'_base_alldata.jsonl')))

# ---------- LING-ON-SIDE PROTOCOL
jsonlite::stream_out(LotS_pass, file(paste0('../NLI_data/2_Ling_on_side_protocol/val_',round,'_LotS.jsonl')))
jsonlite::stream_out(LotS_transformed, file(paste0('../../SECRET/ling_in_loop_SECRET/full_validation_files/val_',round,'_LotS_alldata.jsonl')))

# ---------- LING-IN-LOOP PROTOCOL
jsonlite::stream_out(LitL_pass, file(paste0('../NLI_data/3_Ling_in_loop_protocol/val_',round,'_LitL.jsonl')))
jsonlite::stream_out(LitL_transformed, file(paste0('../../SECRET/ling_in_loop_SECRET/full_validation_files/val_',round,'_LitL_alldata.jsonl')))

