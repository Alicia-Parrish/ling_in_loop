library(tidyverse)
library(ggplot2)

setwd("C:/Users/NYUCM Loaner Access/Documents/GitHub/ling_in_loop/scripts")

set.seed(42)
round = "round5"
r = "r5"

base_pred<-read.csv(paste0("../predictions/roberta-large/1_Baseline_protocol/",r,"/combined/full/val_",round,"_base_combined_preds.csv"))
LotS_pred<-read.csv(paste0("../predictions/roberta-large/2_Ling_on_side_protocol/",r,"/combined/full/val_",round,"_LotS_combined_preds.csv"))
LitL_pred<-read.csv(paste0("../predictions/roberta-large/3_Ling_in_loop_protocol/",r,"/combined/full/val_",round,"_LitL_combined_preds.csv"))

h_ids = LotS_pred %>% select(heuristic,promptID)
h_ids2 = LitL_pred %>% select(heuristic,promptID)
all_h_ids <- rbind(h_ids,h_ids2)  
all_h_ids <- all_h_ids %>% distinct(heuristic,promptID, .keep_all = TRUE)

accuracy_by_heuristic<-function(dat,heur){
  dat2<-merge(dat,all_h_ids)
  dat3<-dat2%>%
    mutate(score = case_when(correct=="True" ~ 1,
                             correct=="False" ~ 0))%>%
    {if(!heur) group_by(.,heuristic,label,group,round) else .}%>%
    {if(heur) group_by(.,heuristic,label,group,round,heuristic_gold_label) else .}%>%
    summarise(accuracy=mean(score),count=n())
  if(!heur){dat3$heuristic_gold_label = "No"}
  return(dat3)
}

base_acc<-accuracy_by_heuristic(base_pred,F)
LotS_acc<-accuracy_by_heuristic(LotS_pred,T)
LitL_acc<-accuracy_by_heuristic(LitL_pred,T)

all_acc<-rbind(base_acc,LotS_acc,LitL_acc)
all_acc2<-all_acc%>%
  mutate(heuristic_gold_label=ifelse(heuristic=="","No",heuristic_gold_label))

overall_acc<-all_acc2%>%
  group_by(group,round)%>%
  summarise(overall_acc = weighted.mean(accuracy,count))

all_acc3<-merge(all_acc2,overall_acc)
all_acc4<-all_acc3 %>%
  mutate(acc_diff = (accuracy - overall_acc)*100)%>%
  filter(heuristic_gold_label!="no_winner")

(plt<-ggplot(data=all_acc4,aes(x=heuristic,y=acc_diff,fill=label))+
    geom_bar(stat='identity',position=position_dodge2(preserve = "single", padding = 0))+
    geom_text(aes(label=count),position=position_dodge(width = 1),size=2,face="bold")+
    theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust=1))+
    ylab("Accuracy difference from mean")+
    facet_grid(heuristic_gold_label ~ group*round ,scales="free_x")
  )

ggsave(paste0("figures/accuracyHeuristic_",round,"_combined.png"), plot=plt, width = 12, height = 6)



########### DON'T SEPARATE BY INDIVIDUAL HEURISTIC ############

accuracies<-function(dat,heur,byRound=T){
  if(!heur){dat$heuristic_gold_label = "No"}
  dat2<-dat%>%
    mutate(score = case_when(correct=="True" ~ 1,
                             correct=="False" ~ 0))%>%
    {if(heur) select(.,-heuristic) else .}%>%
    {if(byRound) group_by(.,heuristic_gold_label,label,group,round) else .}%>%
    {if(!byRound) group_by(.,heuristic_gold_label,label,group) else .}%>%
    summarise(accuracy=mean(score),count=n())
  return(dat2)
}

base_accs<-accuracies(base_pred,F)
LotS_accs<-accuracies(LotS_pred,T)
LitL_accs<-accuracies(LitL_pred,T)

all_accs<-rbind(base_accs,LotS_accs,LitL_accs)
all_accs2<-all_accs%>%
  mutate(heuristic_applied=ifelse(heuristic_gold_label=="","No",heuristic_gold_label))%>%
  select(-heuristic_gold_label)

overall_accs<-all_accs2%>%
  group_by(group,round)%>%
  summarise(overall_acc = weighted.mean(accuracy,count))

all_accs3<-merge(all_accs2,overall_accs)
all_accs4<-all_accs3 %>%
  mutate(acc_diff = (accuracy - overall_acc)*100)%>%
  filter(heuristic_gold_label!="no_winner")

(plt2<-ggplot(data=all_accs4,aes(x=round,y=acc_diff,fill=label))+
    geom_bar(stat='identity',position=position_dodge2(preserve = "single", padding = 0))+
    geom_text(aes(label=count),position=position_dodge(width = 1),size=2,face="bold")+
    theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust=1))+
    ylab("Accuracy difference from mean")+
    facet_grid(heuristic_applied ~ group)
)

ggsave(paste0("figures/accuracyHeuristicApplied_",round,"_combined_byRound.png"), plot=plt2, width = 8, height = 4)


# ORGANIZE DIFFERENTLY...
sums<-function(dat,heur){
  if(!heur){dat$heuristic_gold_label = "No"}
  dat2<-dat%>%
    {if(heur) select(.,-heuristic) else .}%>%
    filter(heuristic_gold_label!="no_winner")%>%
    mutate(heuristic_applied=ifelse(heuristic_gold_label=="","No",
                                    ifelse(heuristic_gold_label=="No","No",
                                           ifelse(heuristic_gold_label=="Yes","Yes","problem"))))%>%
    group_by(heuristic_applied,label,group,correct)%>%
    summarise(count=n())
  return(dat2)
}
base_accs<-sums(base_pred,F)
LotS_accs<-sums(LotS_pred,T)
LitL_accs<-sums(LitL_pred,T)

all_accs<-rbind(base_accs,LotS_accs,LitL_accs)

(plt3<-ggplot(data=all_accs,aes(x=heuristic_applied,y=count,fill=correct))+
    geom_bar(stat='identity',position='fill')+
    #geom_text(aes(label=count),size=2)+
    #theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust=1))+
    ylab("Proportion correct")+
    ggtitle("Effect of applying a heuristic on accuracy")+
    theme(plot.title = element_text(hjust = 0.5))+
    facet_grid(label ~ group)
)

ggsave(paste0("figures/accuracyHeuristicApplied_",round,"_combined_collapseRounds.png"), plot=plt3, width = 6, height = 4)

