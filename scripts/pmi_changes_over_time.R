library(tidyverse)
library(ggplot2)

setwd("C:/Users/NYUCM Loaner Access/Documents/GitHub/ling_in_loop/scripts")

set.seed(42)

################## BY ROUND ###################

rounds <- c("r1","r2")
labels <- c("entailment","neutral","contradiction")
groups <- c("Baseline", "Ling_on_side", "Ling_in_loop")
group_nums <- c("1","2","3")

all_data<-NULL

for(g in 1:length(groups)){
  for(i in 1:length(rounds)){
    for(j in 1:length(labels)){
      dat<-read.csv(paste0("../corpus_stats/",rounds[i],"/",group_nums[g],"_",groups[g],"_protocol/separate/pmi_",labels[j],".csv"))
      dat$label <- labels[j]
      dat$round <- rounds[i]
      dat$group <- groups[g]
      all_data = rbind(all_data,dat)
    }
  }
}

(plt<-ggplot(data=all_data,aes(x=round,y=pmi,col=label,label=X))+
    geom_text(position=position_jitter(width=0.39,height=0),
              check_overlap = T)+
    theme(legend.position = "none")+
    facet_wrap(~group*label))

ggsave("figures/pmis_round2_byRound.png", plot=plt, width = 18, height = 18)

################## COMBINED ###################

round <- "r2"
labels <- c("entailment","neutral","contradiction")
groups <- c("Baseline", "Ling_on_side", "Ling_in_loop")
group_nums <- c("1","2","3")

combined_data<-NULL

for(g in 1:length(groups)){
  for(j in 1:length(labels)){
    dat<-read.csv(paste0("../corpus_stats/",round,"/",group_nums[g],"_",groups[g],"_protocol/combined/pmi_",labels[j],".csv"))
    dat$label <- labels[j]
    dat$group <- groups[g]
    combined_data = rbind(combined_data,dat)
  }
}

(plt2<-ggplot(data=combined_data,aes(x=label,y=pmi,col=label,label=X))+
    geom_text(position=position_jitter(width=0.39,height=0),
              check_overlap = T)+
    theme(legend.position = "none")+
    facet_wrap(~group))

ggsave("figures/pmis_round2_combined.png", plot=plt2, width = 18, height = 18)
