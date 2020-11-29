library(tidyverse)
library(rjson)
library(jsonlite)

setwd("C:/Users/NYUCM Loaner Access/Documents/GitHub/ling_in_loop/scripts")

set.seed(42)

anon_codes = read.csv("../../SECRET/ling_in_loop_SECRET/anonymized_id_links.csv")

round = "round5" # change this value each round
groups = c("Group1_baseline","Group2_ling_on_side","Group3_ling_in_loop")
group = groups[2]
split = "validation" # "writing" #  

dat<-NULL
dat_files = list.files(paste0("../../SECRET/ling_in_loop_SECRET/raw_mturk_files/",group,"/",round,"_",split),full.names=T, pattern = "*.csv")
for(i in 1:length(dat_files)){
  temp = read.csv(dat_files[i])
  dat = rbind(dat,temp)
}

dat_anon<-merge(dat,anon_codes,by="WorkerId")
dat_anon_transformed <- dat_anon %>%
  group_by(AnonId, WorkerId)%>%
  summarise(count=n())

View(dat_anon_transformed)

#############################################################
# create n completed for all workers all rounds
add_missing_columns<-function(dat){
  dat$Answer.heuristic_val_1 = NA
  dat$Answer.heuristic_val_2 = NA
  dat$Answer.heuristic_val_3 = NA
  dat$Answer.heuristic_val_4 = NA
  dat$Answer.heuristic_val_5 = NA
  dat$Answer.heuristic_val_6 = NA
  return(dat)
}

groups = c("Group1_baseline","Group2_ling_on_side","Group3_ling_in_loop")
splits = c("validation","writing")  

all_dat=NULL
for(i in c(1:5)){
  for(group in 1:length(groups)){
    for(split in 1:length(splits)){
      dat_files = list.files(paste0("../../SECRET/ling_in_loop_SECRET/raw_mturk_files/",groups[group],"/round",i,"_",splits[split]),full.names=T, pattern = "*.csv")
      dat = NULL
      for(x in 1:length(dat_files)){
        temp = read.csv(dat_files[x])
        temp2 = select(temp, -matches("heuristic_description|heuristic_example")) # get only relevant columns
        if(!"Answer.heuristic_val_1" %in% names(temp2)){temp2=add_missing_columns(temp2)}
        dat = rbind(dat,temp2)
      }
      
      dat_anon<-merge(dat,anon_codes,by="WorkerId")
      dat_anon_transformed <- dat_anon %>%
        group_by(AnonId, WorkerId)%>%
        summarise(count=n())
      
      dat_anon_transformed$group = groups[group]
      dat_anon_transformed$split = splits[split]
      dat_anon_transformed$round = paste0("round",i)
      all_dat = rbind(all_dat, dat_anon_transformed)
    }
  }
}

all_dat_transformed = all_dat%>%
  #spread(split,count)%>%
  ungroup()%>%
  pivot_wider(names_from = c(split,round) , values_from = "count", names_sep="_")%>%
  #mutate(completed=case_when(!is.na(validation)|!is.na(writing) ~ 1,
  #                           is.na(validation)&is.na(writing) ~ 0))%>%
  #pivot_wider(names_from = round, values_from = c("validation","writing"))%>%
  mutate(final_bonus = ifelse((!is.na(validation_round1)|!is.na(writing_round1))&
                              (!is.na(validation_round2)|!is.na(writing_round2))&
                              (!is.na(validation_round3)|!is.na(writing_round3))&
                              (!is.na(validation_round4)|!is.na(writing_round4))&
                              (!is.na(validation_round5)|!is.na(writing_round5)),
                              20,0
    
  ))%>%
  replace(is.na(.), 0)%>%
  mutate(total_hits = rowSums(select(., contains("round"))))


to_push = all_dat_transformed %>% select(-WorkerId)
write.csv(to_push,"files/worker_data/final_total_HITs_completed_allWorkers.csv")
