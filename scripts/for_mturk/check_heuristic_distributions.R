library(tidyverse)
library(ggplot2)

setwd("C:/Users/NYUCM Loaner Access/Documents/GitHub/ling_in_loop/scripts")

set.seed(42)

anon_codes = read.csv("../../SECRET/ling_in_loop_SECRET/anonymized_id_links.csv")

round = "round5" # change this value each round

LotS<-NULL
LitL<-NULL

LotS_files = list.files(paste0("../../SECRET/ling_in_loop_SECRET/raw_mturk_files/Group2_ling_on_side/",round,"_writing"),full.names=T, pattern = "*.csv")
LitL_files = list.files(paste0("../../SECRET/ling_in_loop_SECRET/raw_mturk_files/Group3_ling_in_loop/",round,"_writing"),full.names=T, pattern = "*.csv")

for(i in 1:length(LotS_files)){
  temp = read.csv(LotS_files[i])
  this_heur = as.character(unique(temp$Input.heuristic_value))
  if(this_heur=="hyponym"){temp$Input.heuristic_value="hypernym"} # I flipped these in round 3, whoops
  if(this_heur=="hypernym"){temp$Input.heuristic_value="hyponym"}
  LotS = rbind(LotS,temp)
}
for(i in 1:length(LitL_files)){
  temp = read.csv(LitL_files[i])
  this_heur = as.character(unique(temp$Input.heuristic_value))
  if(this_heur=="hyponym"){temp$Input.heuristic_value="hypernym"} # I flipped these in round 3, whoops
  if(this_heur=="hypernym"){temp$Input.heuristic_value="hyponym"}
  LitL = rbind(LitL,temp)
}

################ TRANSFORM ##################

# Ling on side
LotSanon<-merge(LotS,anon_codes,by="WorkerId")

LotSanon2<-LotSanon%>%
  select(AnonId,Answer.constraint_contradiciton,Answer.constraint_entailment,Answer.constraint_neutral,Input.heuristic_value)%>%
  rename("contradiction" = Answer.constraint_contradiciton,
         "entailment" = Answer.constraint_entailment,
         "neutral" = Answer.constraint_neutral,
         "heuristic" = Input.heuristic_value)%>%
  gather("label","Value",-AnonId,-heuristic)%>%
  mutate(Value = case_when(Value == "" ~ "No",
                           Value != "" ~ "Yes"))%>%
  #group_by(AnonId,Label,Value)%>%
  group_by(label,Value,heuristic)%>%
  summarise(count=n())

# Ling in loop
LitLanon<-merge(LitL,anon_codes,by="WorkerId")

LitLanon2<-LitLanon%>%
  select(AnonId,Answer.constraint_contradiciton,Answer.constraint_entailment,Answer.constraint_neutral,Input.heuristic_value)%>%
  rename("contradiction" = Answer.constraint_contradiciton,
         "entailment" = Answer.constraint_entailment,
         "neutral" = Answer.constraint_neutral,
         "heuristic" = Input.heuristic_value)%>%
  gather("label","Value",-AnonId,-heuristic)%>%
  mutate(Value = case_when(Value == "" ~ "No",
                           Value != "" ~ "Yes"))%>%
  #group_by(AnonId,Label,Value)%>%
  group_by(label,Value,heuristic)%>%
  summarise(count=n())

############# PLOT DISTRIBUTION ###############
LotSanon2$group="LotS"
LitLanon2$group="LitL"

for_plt <-  rbind(LotSanon2,LitLanon2)

heur_paymnt <- read.csv(paste0("for_mturk/heuristic_payment_",round,".csv"))

for_plt2<-merge(for_plt,heur_paymnt)

(plt<-ggplot(for_plt2,aes(fill=Value, y=count, x=label)) + 
    geom_bar(position="fill", stat="identity")+
    geom_text(aes(x=label, y=0.8, label=paste0("$",bonus)))+
    labs(title = "How often workers checked the box on a heuristic")+
    ylab("percent")+
    ggtitle("Heuristics attempted round 5")+
    theme(plot.title = element_text(hjust = 0.5))+
    facet_wrap(~ heuristic + group, ncol = 2))

ggsave(plot=plt, 
       filename="figures/heuristic_distributions_round5.png",
       width = 6, height = 7)

############# FINAL HEURISTIC DISTRIBUTIONS ################

# function for reading in .jsonl files
read_json_lines <- function(file){
  con <- file(file, open = "r")
  on.exit(close(con))
  jsonlite::stream_in(con, verbose = FALSE)
}

LotS_val = read_json_lines("C:/Users/NYUCM Loaner Access/Documents/GitHub/ling_in_loop/NLI_data/2_Ling_on_side_protocol/val_round5_LotS_combined.jsonl")
LotS_train = read_json_lines("C:/Users/NYUCM Loaner Access/Documents/GitHub/ling_in_loop/NLI_data/2_Ling_on_side_protocol/train_round5_LotS_combined.jsonl")

LotS_val_2 = data.frame(matrix(ncol = 4, nrow = nrow(LotS_val)))
colnames(LotS_val_2)<-c("pairID","heuristic_labels","round","group")
for(i in 1:nrow(LotS_val)){
  LotS_val_2$pairID[i] = LotS_val$pairID[i]
  LotS_val_2$round[i] = LotS_val$round[i]
  LotS_val_2$group[i] = LotS_val$group[i]
  if(length(LotS_val$heuristic_labels[i]) > 0){
    LotS_val_2$heuristic_labels[i] = unlist(LotS_val$heuristic_labels[i])[1]
  }
  else{
    LotS_val_2$heuristic_labels[i] = NA
  }
}

LotS_train_2 = data.frame(matrix(ncol = 4, nrow = nrow(LotS_train)))
colnames(LotS_train_2)<-c("pairID","heuristic_labels","round","group")
for(i in 1:nrow(LotS_train)){
  LotS_train_2$pairID[i] = LotS_train$pairID[i]
  LotS_train_2$round[i] = LotS_train$round[i]
  LotS_train_2$group[i] = LotS_train$group[i]
  LotS_train_2$heuristic_labels[i] = LotS_train$heuristic_checked[i]
}

LotS = rbind(LotS_train_2,LotS_val_2)

LitL_val = read_json_lines("C:/Users/NYUCM Loaner Access/Documents/GitHub/ling_in_loop/NLI_data/3_Ling_in_loop_protocol/val_round5_LitL_combined.jsonl")
LitL_train = read_json_lines("C:/Users/NYUCM Loaner Access/Documents/GitHub/ling_in_loop/NLI_data/3_Ling_in_loop_protocol/train_round5_LitL_combined.jsonl")

LitL_val_2 = data.frame(matrix(ncol = 4, nrow = nrow(LitL_val)))
colnames(LitL_val_2)<-c("pairID","heuristic_labels","round","group")
for(i in 1:nrow(LitL_val)){
  LitL_val_2$pairID[i] = LitL_val$pairID[i]
  LitL_val_2$round[i] = LitL_val$round[i]
  LitL_val_2$group[i] = LitL_val$group[i]
  if(length(LitL_val$heuristic_labels[i]) > 0){
    LitL_val_2$heuristic_labels[i] = unlist(LitL_val$heuristic_labels[i])[1]
  }
  else{
    LitL_val_2$heuristic_labels[i] = NA
  }
}

LitL_train_2 = data.frame(matrix(ncol = 4, nrow = nrow(LitL_train)))
colnames(LitL_train_2)<-c("pairID","heuristic_labels","round","group")
for(i in 1:nrow(LitL_train)){
  LitL_train_2$pairID[i] = LitL_train$pairID[i]
  LitL_train_2$round[i] = LitL_train$round[i]
  LitL_train_2$group[i] = LitL_train$group[i]
  LitL_train_2$heuristic_labels[i] = LitL_train$heuristic_checked[i]
}

LitL = rbind(LitL_train_2,LitL_val_2)

all_dat = rbind(LotS,LitL)

all_dat2 <- all_dat %>%
  group_by(round,group,heuristic_labels)%>%
  #group_by(group,heuristic_labels)%>%
  summarise(count=n())%>%
  spread(heuristic_labels,count)%>%
  mutate(mean_yes = Yes / (No + Yes))
