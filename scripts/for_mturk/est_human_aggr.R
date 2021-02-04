library(tidyverse)
library(ggplot2)

setwd("C:/Users/NYUCM Loaner Access/Documents/GitHub/ling_in_loop/scripts")

set.seed(42)

########################## READ IN DATA ############################

round = "round5"

# function for reading in .jsonl files
read_json_lines <- function(file){
  con <- file(file, open = "r")
  on.exit(close(con))
  jsonlite::stream_in(con, verbose = FALSE)
}

groups <- c("Baseline", "Ling_on_side", "Ling_in_loop")
group_nums <- c("1","2","3")
g_label = c("base","LotS","LitL")

val_accuracies = NULL
for(g in 1:length(groups)){
  dat<-read.csv(paste0("../predictions/roberta-large/",group_nums[g],"_",groups[g],"_protocol/r5/combined/full/val_round5_",g_label[g],"_combined_preds.csv"))
  dat$group <- groups[g]
  if(g>1){dat<-dat%>%select(-heuristic_labels,-glue_labels,-heuristic,-heuristic_gold_label)}
  val_accuracies = rbind(val_accuracies,dat)
}

val_files = list.files("../../SECRET/ling_in_loop_SECRET/full_validation_files",full.names=T)

all_vals = NULL
for(i in 1:length(val_files)){
  dat = read_json_lines(val_files[i])
  dat2 <- dat %>%
    select(annotator_ids,annotator_labels,label,pairID,promptID,group,round)
  all_vals = rbind(all_vals,dat2)
}

########################## DETERMINE AGREEMENT ############################

checks_full = NULL
for(j in c(1:5)){
  checks_temp = data.frame(matrix(ncol = 6, nrow = nrow(all_vals)))
  colnames(checks_temp)<-c("AnonId","original_label","validated_label","pairID","group","round")
  for(i in 1:nrow(all_vals)){
    checks_temp$AnonId[i] = unlist(all_vals$annotator_ids[i])[j]
    checks_temp$original_label[i] = unlist(all_vals$annotator_labels[i])[j]
    checks_temp$validated_label[i] = all_vals$label[i]
    checks_temp$pairID[i] = all_vals$pairID[i]
    checks_temp$group[i] = all_vals$group[i]
    checks_temp$round[i] = all_vals$round[i]
  }
  checks_full = rbind(checks_full,checks_temp)
}

checks_full2<-checks_full%>%
  mutate(same=case_when(original_label==validated_label ~ 1,
                        original_label!=validated_label ~0))%>%
  filter(!is.na(original_label))%>%
  filter(validated_label!="no_winner")

mean(checks_full2$same[checks_full2$group=="group1"],na.rm=T)
mean(checks_full2$same[checks_full2$group=="group2"],na.rm=T)
mean(checks_full2$same[checks_full2$group=="group3"],na.rm=T)

val_checks <- checks_full2 %>%
  mutate(group = case_when(group=="group1" ~ "Baseline",
                           group=="group2" ~ "Ling_on_side",
                           group=="group3" ~ "Ling_in_loop"))%>%
  rename("label" = validated_label)%>%
  group_by(round,group,label)%>%
  summarise(human_aggr = mean(same), count.human=n())

#################### COMBINE WITH ACCURACY ######################

val_accuracies2 <- val_accuracies %>%
  group_by(round,group,label)%>%
  mutate(corr = case_when(correct=="True" ~ 1,
                          correct=="False" ~ 0))%>%
  summarise(model_acc = mean(corr),count.model=n())

model_human_vals = merge(val_checks,val_accuracies2)

model_human_diff <- model_human_vals %>%
  mutate(diff = model_acc - human_aggr)

################### PLOT ###########################

model_human_diff$label = factor(model_human_diff$label, levels = c("entailment","contradiction","neutral"))
model_human_diff$group = factor(model_human_diff$group, levels = c("Baseline","Ling_on_side","Ling_in_loop"))

(plt <- ggplot(model_human_diff, aes(x=round,y=diff,fill=group))+
    geom_bar(stat='identity',position=position_dodge())+
    #scale_fill_manual(values=c(cols[3],cols[4],cols[9]))+
    theme(axis.text.x = element_text(angle = 90, vjust = 1, hjust=1))+
    facet_wrap(~label)+
    ylab("Model - human gap")
)

model_human_diff2 <- model_human_vals %>%
  group_by(round,group)%>%
  summarise(model_acc2 = weighted.mean(model_acc,count.model),
            human_aggr2 = weighted.mean(human_aggr,count.human))%>%
  mutate(diff = model_acc2 - human_aggr2)

(plt2 <- ggplot(model_human_diff2, aes(x=round,y=diff,fill=group))+
    geom_bar(stat='identity',position=position_dodge())+
    #scale_fill_manual(values=c(cols[3],cols[4],cols[9]))+
    theme(axis.text.x = element_text(angle = 90, vjust = 1, hjust=1))+
    ylab("Model - human gap")
)

model_human_diff3 <- model_human_vals %>%
  group_by(group)%>%
  summarise(model_acc2 = weighted.mean(model_acc,count.model),
            human_aggr2 = weighted.mean(human_aggr,count.human))%>%
  mutate(diff = model_acc2 - human_aggr2)

(plt3 <- ggplot(model_human_diff3, aes(x=group,y=diff,fill=group))+
    geom_bar(stat='identity',position=position_dodge())+
    scale_fill_manual(values=c(cols[3],cols[4],cols[9]))+
    theme(axis.text.x = element_text(angle = 90, vjust = 1, hjust=1))+
    ylab("Model - human gap")
)
