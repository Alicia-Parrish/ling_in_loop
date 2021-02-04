library(tidyverse)

setwd("C:/Users/NYUCM Loaner Access/Documents/GitHub/ling_in_loop/scripts")

round = "round5"
base_val_combined<-read_json_lines(paste0("../NLI_data/1_Baseline_protocol/val_",round,"_base_combined.jsonl"))
LotS_val_combined<-read_json_lines(paste0("../NLI_data/2_Ling_on_side_protocol/val_",round,"_LotS_combined.jsonl"))
LitL_val_combined<-read_json_lines(paste0("../NLI_data/3_Ling_in_loop_protocol/val_",round,"_LitL_combined.jsonl"))

vals = rbind(base_val_combined %>% filter(round=="round5") %>% select(premise,hypothesis,label,pairID,promptID,group),
             LotS_val_combined %>% filter(round=="round5") %>% select(premise,hypothesis,label,pairID,promptID,group),
             LitL_val_combined %>% filter(round=="round5") %>% select(premise,hypothesis,label,pairID,promptID,group))

vals2 = vals %>%
  group_by(promptID,label)%>%
  mutate(count1 = n())%>%
  ungroup() %>%
  filter(count1 == 3)%>%
  group_by(promptID) %>%
  mutate(count2 = n())%>%
  ungroup() %>%
  filter(count2 == 9)

promptids <- unique(vals2$promptID)
idx <- sample(1:length(promptids), 8, replace=F)
promtids_sample = promptids[idx]
vals_sample = vals %>% filter(promptID %in% promtids_sample)