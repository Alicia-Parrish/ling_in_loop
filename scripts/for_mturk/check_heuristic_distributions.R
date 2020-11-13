library(tidyverse)
library(ggplot2)

setwd("C:/Users/NYUCM Loaner Access/Documents/GitHub/ling_in_loop/scripts")

set.seed(42)

anon_codes = read.csv("../../SECRET/ling_in_loop_SECRET/anonymized_id_links.csv")

round = "round3" # change this value each round

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
  rename("Contradiction" = Answer.constraint_contradiciton,
         "Entailment" = Answer.constraint_entailment,
         "Neutral" = Answer.constraint_neutral,
         "Heuristic" = Input.heuristic_value)%>%
  gather("Label","Value",-AnonId,-Heuristic)%>%
  mutate(Value = case_when(Value == "" ~ "No",
                           Value != "" ~ "Yes"))%>%
  #group_by(AnonId,Label,Value)%>%
  group_by(Label,Value,Heuristic)%>%
  summarise(count=n())

# Ling in loop
LitLanon<-merge(LitL,anon_codes,by="WorkerId")

LitLanon2<-LitLanon%>%
  select(AnonId,Answer.constraint_contradiciton,Answer.constraint_entailment,Answer.constraint_neutral,Input.heuristic_value)%>%
  rename("Contradiction" = Answer.constraint_contradiciton,
         "Entailment" = Answer.constraint_entailment,
         "Neutral" = Answer.constraint_neutral,
         "Heuristic" = Input.heuristic_value)%>%
  gather("Label","Value",-AnonId,-Heuristic)%>%
  mutate(Value = case_when(Value == "" ~ "No",
                           Value != "" ~ "Yes"))%>%
  #group_by(AnonId,Label,Value)%>%
  group_by(Label,Value,Heuristic)%>%
  summarise(count=n())

############# PLOT DISTRIBUTION ###############
LotSanon2$group="LotS"
LitLanon2$group="LitL"

for_plt <-  rbind(LotSanon2,LitLanon2)

heur_paymnt <- read.csv("for_mturk/heuristic_payment.csv")

for_plt2<-merge(for_plt,heur_paymnt)

(plt<-ggplot(for_plt2,aes(fill=Value, y=count, x=Label)) + 
    geom_bar(position="fill", stat="identity")+
    geom_text(aes(x=Label, y=0.8, label=paste0("$",Bonus)))+
    labs(title = "How often workers checked the box on a heuristic")+
    ylab("percent")+
    theme(plot.title = element_text(hjust = 0.5))+
    facet_wrap(~ Heuristic + group, ncol = 2))
