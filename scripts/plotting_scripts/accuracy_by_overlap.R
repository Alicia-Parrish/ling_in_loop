library(tidyverse)
library(ggplot2)
library(Hmisc)

setwd("C:/Users/NYUCM Loaner Access/Documents/GitHub/ling_in_loop/scripts")

set.seed(42)

cols<-brewer.pal(9, "Set1")

################## READ IN ALL DATA ###################

rounds <- c("r1","r2","r3","r4","r5")
labels <- c("entailment","neutral","contradiction")
groups <- c("Baseline", "Ling_on_side", "Ling_in_loop")
group_nums <- c("1","2","3")
g_label = c("base","LotS","LitL")
round = "round5"

overlap_data_train<-NULL
for(g in 1:length(groups)){
  for(i in 1:length(rounds)){
    for(j in 1:length(labels)){
      dat<-read.csv(paste0("../corpus_stats/",rounds[i],"/",group_nums[g],"_",groups[g],"_protocol/separate/overlap_",labels[j],".csv"))
      dat$label <- labels[j]
      dat$round <- rounds[i]
      dat$group <- groups[g]
      overlap_data_train = rbind(overlap_data_train,dat)
    }
  }
}

overlap_data_val = NULL
for(g in 1:length(groups)){
  for(j in 1:length(labels)){
    dat<-read.csv(paste0("../corpus_stats/r5/",group_nums[g],"_",groups[g],"_protocol/val/combined/overlap_",labels[j],".csv"))
    dat$label <- labels[j]
    dat$group <- groups[g]
    overlap_data_val = rbind(overlap_data_val,dat)
  }
}

val_accuracies = NULL
for(g in 1:length(groups)){
  dat<-read.csv(paste0("../predictions/roberta-large/",group_nums[g],"_",groups[g],"_protocol/r5/combined/full/val_round5_",g_label[g],"_combined_preds.csv"))
  dat$group <- groups[g]
  if(g>1){dat<-dat%>%select(-heuristic_labels,-glue_labels,-heuristic,-heuristic_gold_label)}
  val_accuracies = rbind(val_accuracies,dat)
}

################ COMBINE OVERLAP AND PREDICTIONS #################

#fix issue with pairId in entailment
overlap_data_val2 <- overlap_data_val %>%
  mutate(pairID = case_when(label=='entailment' ~ paste0(pairID,"e"),
                            label!='entailment' ~ pairID))%>%
  select(-X)

val_accuracies2<-val_accuracies %>% select(-X)

overlap_preds = merge(overlap_data_val2,val_accuracies2,all=T)

################ CALCULATE BIAS SCORE IN EACH BIN #################

all_data_bias <- overlap_data_train %>%
  rename("overlap" = X0)%>%
  mutate(x_bins = cut(overlap, breaks = seq(0,1,0.1), include.lowest = T))%>%
  group_by(x_bins,group,label)%>%
  summarise(count=n())%>%
  ungroup()%>%
  spread(label,count)%>%
  mutate("E_bias" = entailment / (entailment+neutral+contradiction))%>%
  mutate("N_bias" = neutral / (entailment+neutral+contradiction))%>%
  mutate("C_bias" = contradiction / (entailment+neutral+contradiction))%>%
  select(-entailment,-contradiction,-neutral)%>%
  gather("label","bias_score",-x_bins,-group)%>%
  mutate(label=case_when(label=="E_bias" ~ "entailment",
                         label=="N_bias" ~ "neutral",
                         label=="C_bias" ~ "contradiction"))

################ BIN PRED DATA #################

overlap_pred_binned <- overlap_preds %>%
  mutate(x_bins = cut(overlap, breaks = seq(0,1,0.1), include.lowest = T))%>%
  mutate(score = case_when(correct=="True" ~ 1,
                           correct=="False" ~ 0))%>%
  group_by(x_bins,group,label)%>%
  summarise(accuracy=mean(score))%>%
  ungroup()

############### COMBINE DATA ##################

all_data <- merge(overlap_pred_binned,all_data_bias)

############### PLOT ##################

# accuracy within each bin
(plt_acc<-ggplot(data=all_data,aes(x=x_bins,y=accuracy,fill=group))+
   geom_bar(stat='identity',position=position_dodge2(preserve = "single"),width=0.75)+
   scale_fill_manual(values=c(cols[3],cols[4],cols[9]))+
   theme(axis.text.x = element_text(angle = 90, vjust = 1, hjust=1))+
   facet_wrap(~label)+
   ggtitle("Accuracy by overlap bin")+
   theme(plot.title = element_text(hjust = 0.5))
 )
ggsave(paste0("figures/CorpusStats/Accuracy_in_overlapRateBins_barplot.png"), plot=plt_acc, width = 10, height = 4)

(plt_acc2<-ggplot(data=all_data,aes(x=factor(x_bins),y=accuracy,col=group,group=group))+
    geom_line(size=1.2)+
    scale_color_manual(values=c(cols[3],cols[4],cols[9]))+
    theme(axis.text.x = element_text(angle = 90, vjust = 1, hjust=1))+
    facet_wrap(~label)+
    xlab("x_bins")+
    ggtitle("Accuracy by overlap bin")+
    theme(plot.title = element_text(hjust = 0.5))
)
ggsave(paste0("figures/CorpusStats/Accuracy_in_overlapRateBins_linePlot.png"), plot=plt_acc2, width = 10, height = 4)

# correlation of accuracy and bias
(plt_corr<-ggplot(data=all_data,aes(x=bias_score,y=accuracy))+
   geom_point(aes(col=label))+
   geom_smooth(method = lm, se = FALSE, colour="gray", alpha = 0.2)+
   geom_smooth(aes(col=label),method = lm, se = FALSE)+
   scale_color_manual(values=c(cols[2],cols[5],cols[3]))+
   facet_wrap(~group)+
   ggtitle("Accuracy - bias score correlation")+
   theme(plot.title = element_text(hjust = 0.5))
  )
ggsave(paste0("figures/CorpusStats/Accuracy_by_overlapBiasScore.png"), plot=plt_corr, width = 8, height = 4)


############## COMPARE CORRELATION VALUES ###################

cor.test(all_data$accuracy[all_data$group=="Baseline"], all_data$bias_score[all_data$group=="Baseline"])
cor.test(all_data$accuracy[all_data$group=="Ling_in_loop"], all_data$bias_score[all_data$group=="Ling_in_loop"])
cor.test(all_data$accuracy[all_data$group=="Ling_on_side"], all_data$bias_score[all_data$group=="Ling_on_side"])
