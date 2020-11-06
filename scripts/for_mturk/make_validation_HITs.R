library(tidyverse)
library(rjson)
library(jsonlite)
library(data.table)

setwd("C:/Users/NYUCM Loaner Access/Documents/GitHub/ling_in_loop/scripts")

set.seed(42)

round = "round2" # change this value each round

base<-NULL
LotS<-NULL
LitL<-NULL

anon_codes = read.csv("../../SECRET/ling_in_loop_SECRET/anonymized_id_links.csv")
heur_mapping<-read.csv("for_mturk/heuristic_definitions_round2.csv")

#################### FUNCTIONS ####################
transform_data = function(dat){
  dat2<-dat%>%
    filter(Input.splits=="dev")%>%
    select(AnonId,group,Input.promptID,Input.premise,Answer.entailment,Answer.neutral,Answer.contradiction,heuristic,heuristic_checked)%>%
    rename("promptID" = Input.promptID,
           "premise" = Input.premise,
           "entailment" = Answer.entailment,
           "neutral" = Answer.neutral,
           "contradiction" = Answer.contradiction)%>%
    gather("label","hypothesis",-promptID,-premise,-AnonId,-group,-heuristic,-heuristic_checked)%>%
    mutate("pairID"=ifelse(label=="entailment",paste0(promptID,"e"),
                           ifelse(label=="neutral",paste0(promptID,"n"),
                                  ifelse(label=="contradiction",paste0(promptID,"c"),"problem"))))
  return(dat2)
}

restructure_for_validation_HITs <- function(dat){
  # randomize order
  dat_reorder <- dat[sample(1:nrow(dat)), ]
  
  # get structure needed for validation HIT
  num=floor(nrow(dat_reorder)/6) # will have some leftover
  dat_1 = dat_reorder[1:num,]
  dat_2 = dat_reorder[(num+1):(num*2),]
  dat_3 = dat_reorder[((num*2)+1):(num*3),]
  dat_4 = dat_reorder[((num*3)+1):(num*4),]
  dat_5 = dat_reorder[((num*4)+1):(num*5),]
  dat_6 = dat_reorder[((num*5)+1):(num*6),]
  dat_leftover = dat_reorder[((num*6)+1):nrow(dat_reorder),]
  
  colnames(dat_1)<-unlist(lapply(names(dat_1), function(x) paste0(x,"_1")))
  colnames(dat_2)<-unlist(lapply(names(dat_2), function(x) paste0(x,"_2")))
  colnames(dat_3)<-unlist(lapply(names(dat_3), function(x) paste0(x,"_3")))
  colnames(dat_4)<-unlist(lapply(names(dat_4), function(x) paste0(x,"_4")))
  colnames(dat_5)<-unlist(lapply(names(dat_5), function(x) paste0(x,"_5")))
  colnames(dat_6)<-unlist(lapply(names(dat_6), function(x) paste0(x,"_6")))
  
  full_dat_val = cbind(dat_1,dat_2,dat_3,dat_4,dat_5,dat_6)
  
  return(list(full_dat_val,dat_leftover))
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

base_transformed<-transform_data(base_anon)

# remove heuristic column, not relevant for this protocol
base_transformed2 <- base_transformed %>%
  select(-heuristic_checked, -heuristic)
  
base_vals = restructure_for_validation_HITs(base_transformed2)
full_base_val <- base_vals[[1]]
base_leftover <- base_vals[[2]]

full_base_val$group = "group1"
full_base_val$round = round

write.csv(file=paste0("files/VALIDATION_csv_for_mturk_upload/",round,"_group1_base_batch1.csv"),full_base_val[1:20,],row.names = F)
write.csv(file=paste0("files/VALIDATION_csv_for_mturk_upload/",round,"_group1_base_batch2.csv"),full_base_val[21:50,],row.names = F)
write.csv(file=paste0("files/VALIDATION_csv_for_mturk_upload/",round,"_group1_base_batch3.csv"),full_base_val[51:nrow(full_base_val),],row.names = F)

write.csv(file=paste0("files/VALIDATION_csv_for_mturk_upload/",round,"_group1_base_leftover.csv"),base_leftover,row.names = F)

# ---------- LotS PROTOCOL
LotS_anon<-merge(LotS,anon_codes,by="WorkerId")
LotS_transformed<-transform_data(LotS_anon)

all_heuristics<-unique(LotS_transformed$heuristic)

full_LotS_val = NULL
LotS_leftovers <- list()

for(i in 1:length(all_heuristics)){
  this_dat <- LotS_transformed %>% filter(heuristic==all_heuristics[i])
  restructured_dats <- restructure_for_validation_HITs(this_dat)
  val_dat = restructured_dats[[1]]
  leftover_dat = restructured_dats[[2]]
  val_dat$group = "group2"
  val_dat$round = round
  full_LotS_val = rbind(full_LotS_val,val_dat)
  #assign(paste("LotS_leftover", i, sep = "_") , leftover_dat)
  LotS_leftovers[[i]] <- leftover_dat
}

# add in mapping to ${heuristic_description} and ${heuristic_example}
full_LotS_val_heur<-merge(full_LotS_val,heur_mapping,by="heuristic_1")


# Set up the rel.clause and restricted word ones to run first, since those heuristics don't get validated by mturkers
full_LotS_val_1 <- full_LotS_val_heur %>% filter(heuristic_1 == "restricted_word_in_diff_label" |
                                              heuristic_1 == "relative_clause")
  
write.csv(file=paste0("files/VALIDATION_csv_for_mturk_upload/",round,"_group2_LotS_batch1.csv"),full_LotS_val_heur[1:20,],row.names = F)
write.csv(file=paste0("files/VALIDATION_csv_for_mturk_upload/",round,"_group2_LotS_batch2.csv"),full_LotS_val_heur[21:50,],row.names = F)
write.csv(file=paste0("files/VALIDATION_csv_for_mturk_upload/",round,"_group2_LotS_batch3.csv"),full_LotS_val_heur[51:nrow(full_LotS_val_heur),],row.names = F)

for(i in 1:length(all_heuristics)){
  write.csv(file=paste0("files/VALIDATION_csv_for_mturk_upload/",round,"_group2_LotS_leftover_",all_heuristics[i],".csv"),LotS_leftovers[[i]],row.names = F)
}

# ---------- LitL PROTOCOL
LitL_anon<-merge(LitL,anon_codes,by="WorkerId")
LitL_transformed<-transform_data(LitL_anon)

all_heuristics<-unique(LitL_transformed$heuristic)

full_LitL_val = NULL
LitL_leftovers = list()

for(i in 1:length(all_heuristics)){
  this_dat <- LitL_transformed %>% filter(heuristic==all_heuristics[i])
  restructured_dats <- restructure_for_validation_HITs(this_dat)
  val_dat = restructured_dats[[1]]
  leftover_dat = restructured_dats[[2]]
  val_dat$group = "group2"
  val_dat$round = round
  full_LitL_val = rbind(full_LitL_val,val_dat)
  #assign(paste("LitL_leftover", i, sep = "_") , leftover_dat)
  LitL_leftovers[[i]] <- leftover_dat
}

full_LitL_val$group = "group3"
full_LitL_val$round = round

# add in mapping to ${heuristic_description} and ${heuristic_example}
full_LitL_val_heur<-merge(full_LitL_val,heur_mapping,by="heuristic_1")


# Set up the rel.clause and restricted word ones to run first, since those heuristics don't get validated by mturkers
full_LitL_val_1 <- full_LitL_val_heur %>% filter(heuristic_1 == "restricted_word_in_diff_label" |
                                                   heuristic_1 == "relative_clause")

write.csv(file=paste0("files/VALIDATION_csv_for_mturk_upload/",round,"_group3_LitL_batch1.csv"),full_LitL_val_heur[1:20,],row.names = F)
write.csv(file=paste0("files/VALIDATION_csv_for_mturk_upload/",round,"_group3_LitL_batch2.csv"),full_LitL_val_heur[21:50,],row.names = F)
write.csv(file=paste0("files/VALIDATION_csv_for_mturk_upload/",round,"_group3_LitL_batch3.csv"),full_LitL_val_heur[51:nrow(full_LitL_val_heur),],row.names = F)

for(i in 1:length(LitL_leftovers)){
  write.csv(file=paste0("files/VALIDATION_csv_for_mturk_upload/",round,"_group3_LitL_leftover",all_heuristics[i],".csv"),LitL_leftovers[[i]],row.names = F)
}
