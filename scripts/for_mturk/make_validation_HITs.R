library(tidyverse)
library(rjson)
library(jsonlite)
library(data.table)

setwd("C:/Users/NYUCM Loaner Access/Documents/GitHub/ling_in_loop/scripts")

set.seed(42)

round = "round3" # change this value each round

anon_codes = read.csv("../../SECRET/ling_in_loop_SECRET/anonymized_id_links.csv")
heur_mapping<-read.csv(paste0("for_mturk/heuristic_definitions_",round,".csv"))

#################### FUNCTIONS ####################
transform_data = function(dat,heur){
  dat2<-dat%>%
    filter(Input.splits=="dev")%>%
    #select(AnonId,Input.promptID,Input.premise,Answer.entailment,Answer.neutral,Answer.contradiction,heuristic,heuristic_checked)%>% # round 2
    {if(!heur) select(.,AnonId,Input.promptID,Input.premise,Answer.entailment,Answer.neutral,Answer.contradiction) else . } %>%
    {if(heur) select(.,AnonId,Input.promptID,Input.premise,Answer.entailment,Answer.neutral,Answer.contradiction,
                     Input.heuristic_value, Answer.constraint_contradiciton, Answer.constraint_entailment, Answer.constraint_neutral) else . } %>%
    rename("promptID" = Input.promptID,
           "premise" = Input.premise,
           "entailment" = Answer.entailment,
           "neutral" = Answer.neutral,
           "contradiction" = Answer.contradiction)%>%
    {if(heur) rename(.,"heuristic" = Input.heuristic_value) else . } %>%
    #gather("label","hypothesis",-promptID,-premise,-AnonId,-heuristic,-heuristic_checked)%>% # round 2
    {if(heur) gather(.,"label","hypothesis",-promptID,-premise,-AnonId,-heuristic,
                     -Answer.constraint_contradiciton, -Answer.constraint_entailment, -Answer.constraint_neutral) else .} %>%
    {if(heur) mutate(.,"heuristic_checked" = case_when(label=="contradiction" ~ Answer.constraint_contradiciton,
                                                       label=="entailment" ~ Answer.constraint_entailment,
                                                       label=="neutral" ~ Answer.constraint_neutral)) else .} %>%
    {if(heur) mutate(., "heuristic_checked" = case_when(heuristic_checked=="" ~ "No",
                                                        heuristic_checked!="" ~ "Yes")) else .}%>%
    {if(heur) select(., -Answer.constraint_contradiciton, -Answer.constraint_entailment, -Answer.constraint_neutral) else .} %>%
    {if(!heur) gather(.,"label","hypothesis",-promptID,-premise,-AnonId) else .} %>%
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

base_transformed<-transform_data(base_anon,heur=F)

# remove heuristic column, not relevant for this protocol
#base_transformed2 <- base_transformed %>% # only needed during round 2
#  select(-heuristic_checked, -heuristic)
  
base_vals = restructure_for_validation_HITs(base_transformed)
full_base_val <- base_vals[[1]]
base_leftover <- base_vals[[2]]

full_base_val$group = "group1"
full_base_val$round = round

write.csv(file=paste0("files/VALIDATION_csv_for_mturk_upload/",round,"/",round,"_group1_base_batch1.csv"),full_base_val[1:20,],row.names = F)
write.csv(file=paste0("files/VALIDATION_csv_for_mturk_upload/",round,"/",round,"_group1_base_batch2.csv"),full_base_val[21:50,],row.names = F)
write.csv(file=paste0("files/VALIDATION_csv_for_mturk_upload/",round,"/",round,"_group1_base_batch3.csv"),full_base_val[51:nrow(full_base_val),],row.names = F)

write.csv(file=paste0("files/VALIDATION_csv_for_mturk_upload/",round,"/",round,"_group1_base_leftover.csv"),base_leftover,row.names = F)

# ---------- LotS PROTOCOL
LotS_anon<-merge(LotS,anon_codes,by="WorkerId")
LotS_transformed<-transform_data(LotS_anon,heur=T)

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
# full_LotS_val_noHeur <- full_LotS_val_heur %>% 
#   filter(heuristic_1 == "restricted_word_in_diff_label" |
#          heuristic_1 == "relative_clause") 
# full_LotS_val_noHeur$heuristic_description = NA
# full_LotS_val_noHeur$heuristic_example = NA

# Set up with rest of them
full_LotS_val_withHeur1 <- full_LotS_val_heur %>% 
  filter(heuristic_1 == "hypernym" |
         heuristic_1 == "reverse_argument_order")
full_LotS_val_withHeur2 <- full_LotS_val_heur %>% 
  filter(heuristic_1 == "hyponym" |
         heuristic_1 == "antonym")
full_LotS_val_withHeur3 <- full_LotS_val_heur %>% 
  filter(heuristic_1 == "sub_part")
  
write.csv(file=paste0("files/VALIDATION_csv_for_mturk_upload/",round,"/",round,"_group2_LotS_batch1_withHeur.csv"),full_LotS_val_withHeur1,row.names = F)
write.csv(file=paste0("files/VALIDATION_csv_for_mturk_upload/",round,"/",round,"_group2_LotS_batch2_withHeur.csv"),full_LotS_val_withHeur2,row.names = F)
write.csv(file=paste0("files/VALIDATION_csv_for_mturk_upload/",round,"/",round,"_group2_LotS_batch3_withHeur.csv"),full_LotS_val_withHeur3,row.names = F)
#write.csv(file=paste0("files/VALIDATION_csv_for_mturk_upload/",round,"/",round,"_group2_LotS_batch3_noHeur.csv"),full_LotS_val_noHeur,row.names = F)

for(i in 1:length(all_heuristics)){
  write.csv(file=paste0("files/VALIDATION_csv_for_mturk_upload/",round,"/",round,"_group2_LotS_leftover_",all_heuristics[i],".csv"),LotS_leftovers[[i]],row.names = F)
}

# ---------- LitL PROTOCOL
LitL_anon<-merge(LitL,anon_codes,by="WorkerId")
LitL_transformed<-transform_data(LitL_anon,heur=T)

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
# full_LitL_val_noHeur <- full_LitL_val_heur %>% 
#   filter(heuristic_1 == "restricted_word_in_diff_label" |
#         heuristic_1 == "relative_clause")
# full_LitL_val_noHeur$heuristic_description = NA
# full_LitL_val_noHeur$heuristic_example = NA

# Set up with rest of them
full_LitL_val_withHeur1 <- full_LitL_val_heur %>% 
  filter(heuristic_1 == "hypernym" |
           heuristic_1 == "reverse_argument_order")
full_LitL_val_withHeur2 <- full_LitL_val_heur %>% 
  filter(heuristic_1 == "hyponym" |
           heuristic_1 == "antonym")
full_LitL_val_withHeur3 <- full_LitL_val_heur %>% 
  filter(heuristic_1 == "sub_part")

write.csv(file=paste0("files/VALIDATION_csv_for_mturk_upload/",round,"/",round,"_group3_LitL_batch1_withHeur.csv"),full_LitL_val_withHeur1,row.names = F)
write.csv(file=paste0("files/VALIDATION_csv_for_mturk_upload/",round,"/",round,"_group3_LitL_batch2_withHeur.csv"),full_LitL_val_withHeur2,row.names = F)
write.csv(file=paste0("files/VALIDATION_csv_for_mturk_upload/",round,"/",round,"_group3_LitL_batch3_withHeur.csv"),full_LitL_val_withHeur3,row.names = F)

for(i in 1:length(LitL_leftovers)){
  write.csv(file=paste0("files/VALIDATION_csv_for_mturk_upload/",round,"/",round,"_group3_LitL_leftover",all_heuristics[i],".csv"),LitL_leftovers[[i]],row.names = F)
}
