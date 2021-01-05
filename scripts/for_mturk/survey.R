library(tidyverse)
library(ggplot2)

setwd("C:/Users/NYUCM Loaner Access/Documents/GitHub/ling_in_loop/scripts")

g1<-read.csv("../../SECRET/ling_in_loop_SECRET/raw_mturk_files/group1_outro.csv")
g2<-read.csv("../../SECRET/ling_in_loop_SECRET/raw_mturk_files/group2_outro.csv")
g3<-read.csv("../../SECRET/ling_in_loop_SECRET/raw_mturk_files/group3_outro.csv")
anon_codes = read.csv("../../SECRET/ling_in_loop_SECRET/anonymized_id_links.csv")

g1.qual<-g1 %>% select(WorkerId,Answer.enjoyableness,Answer.usefulnessFAQ,Answer.valDifficulty,Answer.writingDifficulty)
names(g1.qual) <- sub("Answer.", "", names(g1.qual))
g1.qual$Checkbox = 0
g1.qual$CheckboxClarity = 0
g1.qual$Higher_bonus = 0
g1.qual$SlackFreq = 0
g1.qual$usefulnessSlack = 0

g2.qual<-g2 %>% select(WorkerId,Answer.enjoyableness,Answer.usefulnessFAQ,Answer.valDifficulty,Answer.writingDifficulty,Answer.Checkbox,Answer.CheckboxClarity,Answer.Higher_bonus)
names(g2.qual) <- sub("Answer.", "", names(g2.qual))
g2.qual$SlackFreq = 0
g2.qual$usefulnessSlack = 0

g3.qual<-g3 %>% select(WorkerId,Answer.enjoyableness,Answer.usefulnessFAQ,Answer.valDifficulty,Answer.writingDifficulty,Answer.Checkbox,Answer.CheckboxClarity,Answer.Higher_bonus,Answer.SlackFreq,Answer.usefulnessSlack)
names(g3.qual) <- sub("Answer.", "", names(g3.qual))

all.qual = merge(anon_codes, rbind(g1.qual,g2.qual,g3.qual), by="WorkerId")
all.qual = select(all.qual, -WorkerId)

all.qual2 = all.qual %>%
  gather("Question", "Score", -group, -AnonId, -Removed)

all.qual3 <- all.qual2 %>%
  group_by(Question,Score,group)%>%
  summarise(count=n())

#for_plt1 = all.qual2 %>% filter(Question != "enjoyableness", Question != "Higher_bonus")

all_qs <- data.frame("Question" = unique(all.qual2$Question),
                     "QText" = c("How does this study compare to recent \n Mechanical Turk studies you have participated in?",
                                "How useful was the FAQ document for completing the tasks? \n (1 = not at all useful. 5 = very useful.)",
                                "How would you rate the level of difficulty of the validation task \n (1 = too easy. 3 = just right. 5 = too difficult.)",
                                "How would you rate the level of difficulty of the writing task \n (1 = too easy. 3 = just right. 5 = too difficult.)",
                                "In your estimation, how much of the time \n did you attempt the optional checkbox challenges? \n (1 = never. 5 = nearly every HIT.)",
                                "How clear were the instructions clear for the checkbox challenges? \n (1 = very unclear. 5 = very clear.)",
                                "If the bonuses had been higher, \n would you have completed more checkbox challenges?",
                                "In your estimation, how much did you participate \n in the Slack forum while completing HITs? \n (1 = never. 5 = nearly every batch.)",
                                "How useful was the slack forum for completing the tasks? \n (1 = not at all useful. 5 = very useful.)")
)

for(i in 1:nrow(all_qs)){
  for_plt = all.qual2 %>% filter(Question == all_qs$Question[i])
  plt<-ggplot(data=for_plt, aes(x=factor(Score)))+
    geom_histogram(stat="count")+
    ggtitle(all_qs$QText[i])+
    xlab("Rating")+
    theme(plot.title = element_text(hjust = 0.5, size = 8),
          axis.text = element_text(size=6),
          axis.title = element_text(size=8))+
    facet_wrap(~group)
  if(all_qs$Question[i]=="enjoyableness"){plt=plt+theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust=1))}
  ggsave(paste0("figures/SurveyResults/",all_qs$Question[i],".png"),plot=plt,width=3.5,height=3)
}
