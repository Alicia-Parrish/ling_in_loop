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
round = "round5"

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

ggsave(paste0("figures/CorpusStats/OverlapRate",round,"_combined.png"), plot=plt, width = 10, height = 4)


(plt2 = ggplot(all_data,aes(x=X0,col=label))+
    scale_color_manual(values=c(cols[2],cols[5],cols[3]))+
    geom_freqpoly(binwidth = 0.1,size=1.2)+
    #scale_y_continuous(trans = 'log10')+
    facet_grid(round~group)+
    xlab("overlap rate")+
    ggtitle("Overlap rates in each protocol")+
    theme(plot.title = element_text(hjust = 0.5))
    )

ggsave(paste0("figures/CorpusStats/OverlapRate",round,"_byRound.png"), plot=plt2, width = 8, height = 8)


#####################################
# flip color and facet
(plt_flip = ggplot(all_data,aes(x=X0,fill=group))+
    geom_bar(position=position_dodge2(preserve = "single"),width=0.75)+
    scale_x_binned(breaks = seq(0,1,0.1))+
    #scale_y_continuous(trans = 'log10')+
    #facet_grid(round~group)
    facet_grid(~label)+
    xlab("overlap rate")+
    #ylab("log10 count")+
    ggtitle("Overlap rates in each protocol - all rounds combined")+
    theme(plot.title = element_text(hjust = 0.5))+
    scale_fill_manual(values=c(cols[3],cols[4],cols[9]))
)

(plt2_flip = ggplot(all_data,aes(x=X0,col=group))+
    scale_color_manual(values=c(cols[3],cols[4],cols[9]))+
    geom_freqpoly(binwidth = 0.1,size=1.2)+
    #scale_y_continuous(trans = 'log10')+
    facet_grid(round~label)+
    xlab("overlap rate")+
    ggtitle("Overlap rates in each protocol")+
    theme(plot.title = element_text(hjust = 0.5))
)

################################
# calculate bias scores

all_data_bias <- all_data %>%
  mutate(x_bins = cut(X0, breaks = seq(0,1,0.1), include.lowest = T))%>%
  group_by(x_bins,group,label)%>%
  summarise(count=n())%>%
  ungroup()%>%
  spread(label,count)

entailment_bias <- all_data_bias%>%
  mutate(over_N = entailment - neutral,
         over_C = entailment - contradiction,
         over_E = NA
         )%>%
  mutate(bias = "entailment_bias")

neutral_bias <- all_data_bias%>%
  mutate(over_E = neutral - entailment,
         over_C = neutral - contradiction,
         over_N = NA
  )%>%
  mutate(bias = "neutral_bias")

contradiction_bias <- all_data_bias%>%
  mutate(over_N = contradiction - neutral,
         over_E = contradiction - entailment,
         over_C = NA
  )%>%
  mutate(bias = "contradiction_bias")

all_biases <- rbind(entailment_bias,neutral_bias,contradiction_bias)

all_biases2<-all_biases%>%
  select(-entailment,-contradiction,-neutral)%>%
  gather("comparison","diff_score",-x_bins,-group,-bias)

(plt_bias = ggplot(all_biases2,aes(x=x_bins,y=diff_score,col=comparison,fill=comparison))+
    geom_bar(stat="identity",position=position_dodge())+
    theme(axis.text.x = element_text(angle = 90, vjust = 1, hjust=1))+
    facet_grid(group~bias)+
    ggtitle("Overlap rate bias scores")+
    theme(plot.title = element_text(hjust = 0.5))
  )

ggsave(paste0("figures/CorpusStats/OverlapRate_biasScore_",round,".png"), plot=plt_bias, width = 10, height = 7)

all_biases3<-all_biases2%>%
  mutate(full_bias = paste0(bias,"_",comparison))

(plt_bias2 = ggplot(all_biases3,aes(x=x_bins,y=diff_score,fill=group))+
    geom_bar(stat="identity",position=position_dodge())+
    theme(axis.text.x = element_text(angle = 90, vjust = 1, hjust=1))+
    facet_wrap(~full_bias)+
    ggtitle("Overlap rate bias scores")+
    theme(plot.title = element_text(hjust = 0.5))+
    scale_fill_manual(values=c(cols[3],cols[4],cols[9]))
)

ggsave(paste0("figures/CorpusStats/OverlapRate_biasScore2_",round,".png"), plot=plt_bias2, width = 10, height = 7)


