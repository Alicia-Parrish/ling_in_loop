library(tidyverse)

setwd("C:/Users/NYUCM Loaner Access/Documents/GitHub/ling_in_loop/scripts")

anon_codes = read.csv("../../SECRET/ling_in_loop_SECRET/anonymized_id_links.csv")

LitL_files = list.files("../../SECRET/ling_in_loop_SECRET/raw_mturk_files/Group3_ling_in_loop/Intro",full.names=T)

LitL=NULL
for(i in 1:length(LitL_files)){
  temp = read.csv(LitL_files[i])
  LitL = rbind(LitL,temp)
}

slack_names<-LitL%>%
  select(WorkerId,Answer.slack_name)%>%
  rename("Slack_name"=Answer.slack_name)

anon_slack<-merge(slack_names,anon_codes,by="WorkerId")

anon_slack2<-anon_slack %>% select(Slack_name,AnonId)

write.csv(anon_slack2,"../../SECRET/ling_in_loop_SECRET/anon_slack_names.csv")
