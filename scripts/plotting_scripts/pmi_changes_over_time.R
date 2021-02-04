library(tidyverse)
library(ggplot2)

setwd("C:/Users/NYUCM Loaner Access/Documents/GitHub/ling_in_loop/scripts")

set.seed(42)

################## BY ROUND ###################

rounds <- c("r1","r2","r3","r4","r5")
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
    geom_text(position=position_jitter(width=0.32,height=0),
              check_overlap = T,size=2)+
    theme(legend.position = "none")+
    ggtitle("Round 5 PMI changes")+
    facet_wrap(~group*label))

ggsave("figures/pmis_round5_byRound.png", plot=plt, width = 18, height = 18)

################## COMBINED ###################

round <- "r5"
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
              check_overlap = T,size=2)+
    theme(legend.position = "none")+
    ggtitle("Round 5 combined PMI")+
    facet_wrap(~group))

ggsave("figures/pmis_round5_combined.png", plot=plt2, width = 18, height = 18)

############################################
# Without words

(plt3<-ggplot(data=all_data,aes(x=round,y=pmi,col=label))+
   geom_point(position=position_jitter(width=0.32,height=0),alpha=0.5)+
   ggtitle("Round 5 PMI changes")+
   facet_wrap(~group))

ggsave("figures/pmis_round5_byRound_noText.png", plot=plt3, width = 6, height = 5)

(plt4<-ggplot(data=combined_data,aes(x=label,y=pmi,col=label))+
    geom_point(position=position_jitter(width=0.5,height=0),alpha=0.5)+
    ggtitle("Round 5 combined PMI")+
    facet_wrap(~group))

ggsave("figures/pmis_round5_combined_noText.png", plot=plt4, width = 8.5, height = 4.5)

all_data$label = factor(all_data$label, levels = c("entailment","contradiction","neutral"))
all_data$group = factor(all_data$group, levels = c("Baseline","Ling_on_side","Ling_in_loop"))

base_col = brewer.pal(9,"Greys")[5]
LotS_col = brewer.pal(9,"Purples")[5]
LitL_col = brewer.pal(9,"Greens")[4]

(plt5<-ggplot(data=combined_data,aes(x=group,y=pmi,col=group))+
    geom_point(position=position_jitter(width=0.32,height=0),alpha=0.5)+
    geom_boxplot(alpha=0)+
    ggtitle("Final PMI changes")+
    scale_color_manual(values = c(cols[9],cols[4],cols[3]))+
    theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust=1))+
    facet_wrap(~label))

ggsave("figures/CorpusStats/pmis_round5_facetLabel.png", plot=plt5, width = 6, height = 5)

########### COMPARE NUMBERS #############

library(ez)

for(label in unique(combined_data$label)){
  print(label)
  print(mean(combined_data$pmi[combined_data$group=="Baseline" & combined_data$label==label]))
  print(mean(combined_data$pmi[combined_data$group=="Ling_on_side" & combined_data$label==label]))
  print(mean(combined_data$pmi[combined_data$group=="Ling_in_loop" & combined_data$label==label]))
  dat.aov <- aov(pmi ~ group, data = combined_data[combined_data$label==label,])
  print(summary(dat.aov))
  print("")
}

t.test(combined_data$pmi[combined_data$group=="Baseline"],
       combined_data$pmi[combined_data$group=="Ling_on_side"],
       paired=F)

t.test(combined_data$pmi[combined_data$group=="Baseline"],
       combined_data$pmi[combined_data$group=="Ling_in_loop"],
       paired=F)

rounds_1_5 <- all_data %>%
  filter(round=="r1"|round=="r5")

lots.aov = aov(pmi ~ group*round, data = rounds_1_5[rounds_1_5$group!="Ling_in_loop",])
summary(lots.aov)
mean(rounds_1_5$pmi[rounds_1_5$group=="Baseline" & rounds_1_5$round=="r1"])
mean(rounds_1_5$pmi[rounds_1_5$group=="Baseline" & rounds_1_5$round=="r5"])
mean(rounds_1_5$pmi[rounds_1_5$group=="Ling_on_side" & rounds_1_5$round=="r1"])
mean(rounds_1_5$pmi[rounds_1_5$group=="Ling_on_side" & rounds_1_5$round=="r5"])

litl.aov = aov(pmi ~ group*round, data = rounds_1_5[rounds_1_5$group!="Ling_on_side",])
summary(litl.aov)
mean(rounds_1_5$pmi[rounds_1_5$group=="Ling_in_loop" & rounds_1_5$round=="r1"])
mean(rounds_1_5$pmi[rounds_1_5$group=="Ling_in_loop" & rounds_1_5$round=="r5"])

all.aov = aov(pmi ~ group*round, data = rounds_1_5)
summary(all.aov)

(plt = ggplot(data=all_data, aes(x=round,y=pmi,col=group,group=group))+
  stat_summary(fun=mean, geom="line"))

  