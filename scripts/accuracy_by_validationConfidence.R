library(tidyverse)
library(ggplot2)

setwd("C:/Users/NYUCM Loaner Access/Documents/GitHub/ling_in_loop/scripts")

set.seed(42)
round = "round2"

base_pred<-read.csv("../predictions/1_Baseline_protocol/r2/combined/full/val_round2_base_combined_preds.csv")
LotS_pred<-read.csv("../predictions/2_Ling_on_side_protocol/r2/combined/full/val_round2_LotS_combined_preds.csv")
LitL_pred<-read.csv("../predictions/3_Ling_in_loop_protocol/r2/combined/full/val_round2_LitL_combined_preds.csv")

accuracy_by_validationConfidence<-function(dat){
  dat$num_label<-NA
  for(i in 1:nrow(dat)){
    this_num_label = str_count(dat$annotator_labels[i],as.character(dat$label[i]))
    dat$num_label[i] = this_num_label
  }
  dat2<-dat%>%
    mutate(score = case_when(correct=="True" ~ 1,
                             correct=="False" ~ 0))%>%
    group_by(num_label,label,group)%>%
    summarise(accuracy=mean(score),count=n())
}

base_pred2<-accuracy_by_validationConfidence(base_pred)
LotS_pred2<-accuracy_by_validationConfidence(LotS_pred)
LitL_pred2<-accuracy_by_validationConfidence(LitL_pred)

all_preds<-rbind(base_pred2,LotS_pred2,LitL_pred2)

(plt<-ggplot(data=all_preds,aes(x=num_label,y=accuracy,col=label))+
  geom_line(size=1.2)+
  geom_point(aes(size=count),alpha=0.5)+
  ylab('Accuracy')+
  xlab('Number of annotators agreeing on gold label')+
  ggtitle('Accuracy by annotator confidence')+
  theme(plot.title = element_text(hjust = 0.5))+
  scale_x_continuous(breaks=c(3,4,5))+
  facet_wrap(~group))

ggsave("figures/acc_by_confidence_round2_combined.png", plot=plt, width = 7, height = 5)
