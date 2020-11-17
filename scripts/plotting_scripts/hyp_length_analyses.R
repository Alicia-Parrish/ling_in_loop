library(tidyverse)
library(ggplot2)

setwd("C:/Users/NYUCM Loaner Access/Documents/GitHub/ling_in_loop/scripts")

set.seed(42)

################## BY ROUND ###################

rounds <- c("r1","r2","r3")
groups <- c("Baseline", "Ling_on_side", "Ling_in_loop")
labels <- c("entailment","neutral","contradiction")
group_nums <- c("1","2","3")

# hyp_lengths<-NULL
# for(g in 1:length(groups)){
#   for(i in 1:length(rounds)){
#     dat<-read.csv(paste0("../corpus_stats/",rounds[i],"/",group_nums[g],"_",groups[g],"_protocol/separate/hyp_length_stats.csv"))
#     dat$round <- rounds[i]
#     dat$group <- groups[g]
#     hyp_lengths = rbind(hyp_lengths,dat)
#   }
# }
# 
# hyp_lengths2<-hyp_lengths%>%
#   gather("label","value",-X,-round,-group)%>%
#   spread(X,value)
# 
# (plt<-ggplot(data=hyp_lengths2,aes(x=round,y=mean,col=label))+
#   geom_point(size=2)+
#   geom_point(aes(y=`25ptile`),alpha=0.3)+
#   geom_point(aes(y=`75ptile`),alpha=0.3)+
#   facet_wrap(~group))


hyp_lengths<-NULL
for(g in 1:length(groups)){
  for(j in 1:length(labels)){
    for(i in 1:length(rounds)){
      dat<-read.csv(paste0("../corpus_stats/",rounds[i],"/",group_nums[g],"_",groups[g],"_protocol/separate/hyp_lengths_",labels[j],".csv"))
      dat$round <- rounds[i]
      dat$label <- labels[j]
      dat$group <- groups[g]
      hyp_lengths = rbind(hyp_lengths,dat)
    }
  }
}

hyp_lengths<-filter(hyp_lengths,X0<40)

(plt2<-ggplot(data=hyp_lengths,aes(x=round,y=X0,col=label))+
    geom_point(position = position_jitterdodge(
      jitter.width = NULL,
      jitter.height = 0.45,
      dodge.width = 1,
    ),alpha=.05)+
    geom_violin(fill="transparent",draw_quantiles = c(0.25, 0.5, 0.75),position=position_dodge(width=1),size=1.5)+
    xlab('Round')+
    ylab('Hypothesis length')+
    ggtitle('Hyp length by group & label over time')+
    theme(plot.title = element_text(hjust = 0.5))+
    facet_wrap(~group))

ggsave("figures/hyp_length_over_time_round3.png", plot=plt2, width = 12, height = 9)

