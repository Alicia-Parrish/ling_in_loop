library(tidyverse)
library(ggplot2)

setwd("C:/Users/NYUCM Loaner Access/Documents/GitHub/ling_in_loop/scripts")

set.seed(42)

cols<-brewer.pal(9, "Set1")

################## BY ROUND ###################

rounds <- c("r1","r2","r3","r4","r5")
labels <- c("entailment","neutral","contradiction")
groups <- c("Baseline", "Ling_on_side", "Ling_in_loop")
group_nums <- c("1","2","3")

all_data<-NULL

for(g in 1:length(groups)){
  for(i in 1:length(rounds)){
    for(j in 1:length(labels)){
      dat<-read.csv(paste0("../corpus_stats/",rounds[i],"/",group_nums[g],"_",groups[g],"_protocol/separate/overlap_",labels[j],".csv"))
      dat$label <- labels[j]
      dat$round <- rounds[i]
      dat$group <- groups[g]
      all_data = rbind(all_data,dat)
    }
  }
}

# all_data_binned = all_data %>%
#   mutate(x_bins = cut(X0, breaks = seq(0,1,0.05)))

all_data$label = factor(all_data$label, levels = c("entailment","contradiction","neutral"))
all_data$group = factor(all_data$group, levels = c("Baseline","Ling_on_side","Ling_in_loop"))


(plt = ggplot(all_data,aes(x=X0,fill=label))+
    geom_bar(position=position_dodge2(preserve = "single"),width=0.75)+
    scale_x_binned(breaks = seq(0,1,0.1))+
    #scale_y_continuous(trans = 'log10')+
    #facet_grid(round~group)
    facet_grid(~group)+
    xlab("overlap rate")+
    #ylab("log10 count")+
    ggtitle("Overlap rates in each protocol - all rounds combined")+
    theme(plot.title = element_text(hjust = 0.5))+
    scale_fill_manual(values=c(cols[2],cols[5],cols[3]))
    )

(plt2 = ggplot(all_data,aes(x=X0,col=label))+
    geom_freqpoly(binwidth = 0.04)+
    scale_y_continuous(trans = 'log10')+
    facet_grid(round~group)
    #facet_grid(~group)
    )
