library(tidyverse)
library(ggplot2)

setwd("C:/Users/NYUCM Loaner Access/Documents/GitHub/ling_in_loop/scripts")

set.seed(42)
round = "round2"
r = "r2"

base_pred<-read.csv(paste0("../predictions/1_Baseline_protocol/",r,"/combined/hyp/val_",round,"_base_combined_preds.csv"))
LotS_pred<-read.csv(paste0("../predictions/2_Ling_on_side_protocol/",r,"/combined/hyp/val_",round,"_LotS_combined_preds.csv"))
LitL_pred<-read.csv(paste0("../predictions/3_Ling_in_loop_protocol/",r,"/combined/hyp/val_",round,"_LitL_combined_preds.csv"))

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
  mutate(acc_diff = (accuracy - overall_acc)*100)

(plt<-ggplot(data=all_acc4,aes(x=heuristic,y=acc_diff,fill=label))+
    geom_bar(stat='identity',position=position_dodge2(preserve = "single", padding = 0))+
    geom_text(aes(label=count),position=position_dodge(width = 1),size=2,face="bold")+
    theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust=1))+
    ylab("Accuracy difference from mean")+
    ggtitle("Hypothesis only bias after Round 2")+
    facet_grid(heuristic_gold_label ~ group*round ,scales="free_x")
)
ggsave(paste0("figures/HypOnlyaccuracyHeuristic_",round,"_combined.png"), plot=plt, width = 12, height = 6)

########### DON'T SEPARATE BY INDIVIDUAL HEURISTIC ############

accuracies<-function(dat,heur){
  if(!heur){dat$heuristic_gold_label = "No"}
  dat2<-dat%>%
    mutate(score = case_when(correct=="True" ~ 1,
                             correct=="False" ~ 0))%>%
    {if(heur) select(.,-heuristic) else .}%>%
    group_by(heuristic_gold_label,label,group,round)%>%
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
  mutate(acc_diff = (accuracy - overall_acc)*100)

(plt2<-ggplot(data=all_accs4,aes(x=round,y=acc_diff,fill=label))+
    geom_bar(stat='identity',position=position_dodge2(preserve = "single", padding = 0))+
    geom_text(aes(label=count),position=position_dodge(width = 1),size=2,face="bold")+
    theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust=1))+
    ylab("Accuracy difference from mean")+
    ggtitle("Hypothesis only bias after Round 2")+
    facet_grid(heuristic_applied ~ group)
)

ggsave(paste0("figures/HypOnlyAccuracyHeuristicApplied_",round,"_combined.png"), plot=plt2, width = 8, height = 4)

########### BIAS BY LABEL ############

agg_accuracies2<-function(dat){
  dat2<-dat%>%
    mutate(score = case_when(correct=="True" ~ 1,
                             correct=="False" ~ 0))%>%
    #group_by(label,group,round)%>%
    group_by(group,round)%>%
    summarise(accuracy=mean(score),count=n())
  return(dat2)
}

agg_base<-agg_accuracies2(base_pred)
agg_LotS<-agg_accuracies2(LotS_pred)
agg_LitL<-agg_accuracies2(LitL_pred)

all_agg<-rbind(agg_base,agg_LotS,agg_LitL)

mean_accs<-all_agg%>%
  group_by(group,round)%>%
  summarise(mean_acc = weighted.mean(accuracy,count))

agg_accs3<-merge(all_agg,mean_accs)

(plt3<-ggplot(data=agg_accs3,aes(x=round,y=accuracy,col=label,group=label))+
    #geom_bar(stat='identity',position=position_dodge2(preserve = "single", padding = 0))+
    geom_line(aes(y=mean_acc),col="gray45",linetype = "solid",size=1.2)+
    geom_point(aes(y=mean_acc),col="gray45",size=2)+
    geom_line(size=1.5)+
    geom_point(size=2)+
    #geom_text(aes(label=count),position=position_dodge(width = 1),size=2)+
    #theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust=1))+
    ylab("Accuracy")+
    ggtitle("Hypothesis only bias after Round 2")+
    facet_wrap(~group)
)

ggsave(paste0("figures/HypOnly_byLabel_",round,"_combined.png"), plot=plt3, width = 5.5, height = 3)

