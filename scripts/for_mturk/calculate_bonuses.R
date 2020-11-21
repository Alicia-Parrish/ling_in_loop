#library(plyr)
library(dplyr)
library(tidyverse)
library(rjson)
library(jsonlite)
library(data.table)

setwd("C:/Users/NYUCM Loaner Access/Documents/GitHub/ling_in_loop/scripts")

set.seed(42)
round = "round3"

# function for reading in .jsonl files
read_json_lines <- function(file){
  con <- file(file, open = "r")
  on.exit(close(con))
  jsonlite::stream_in(con, verbose = FALSE)
}

######### get all the data you'll ever need...
anon_codes = read.csv(paste0("../../SECRET/ling_in_loop_SECRET/anonymized_id_links.csv"))
base_writing<-read_json_lines(paste0("../NLI_data/1_Baseline_protocol/train_",round,"_baseline.jsonl"))
LotS_writing<-read_json_lines(paste0("../NLI_data/2_Ling_on_side_protocol/train_",round,"_LotS.jsonl"))
LitL_writing<-read_json_lines(paste0("../NLI_data/3_Ling_in_loop_protocol/train_",round,"_LitL.jsonl"))
base_val<-read_json_lines(paste0("../../SECRET/ling_in_loop_SECRET/full_validation_files/val_",round,"_base_alldata.jsonl"))
LotS_val<-read_json_lines(paste0("../../SECRET/ling_in_loop_SECRET/full_validation_files/val_",round,"_LotS_alldata.jsonl"))
LitL_val<-read_json_lines(paste0("../../SECRET/ling_in_loop_SECRET/full_validation_files/val_",round,"_LitL_alldata.jsonl"))

base_val_final<-read_json_lines(paste0("../NLI_data/1_Baseline_protocol/val_",round,"_base.jsonl"))
LotS_val_final<-read_json_lines(paste0("../NLI_data/2_Ling_on_side_protocol/val_",round,"_LotS.jsonl"))
LitL_val_final<-read_json_lines(paste0("../NLI_data/3_Ling_in_loop_protocol/val_",round,"_LitL.jsonl"))

######### calculate number of HITs bonus #########
calculate_numHIT_bonus<-function(writing_file,validation_file,multiplier){
  val_completions<-validation_file$annotator_ids
  val_completions2<-unlist(lapply(val_completions, function(x) x[2:5]))
  val_completions_summary<-ceiling(table(val_completions2)/6)
  
  wri_completions_from_val<-unlist(lapply(val_completions, function(x) x[1]))
  wri_completions_from_val_summary<-ceiling(table(wri_completions_from_val)/3)
  
  wri_completions<-writing_file$AnonId
  wri_completions_summary<-ceiling(table(wri_completions)/3)
  
  if(writing_file$group[1]=="group1"){all_ids<-c(101:145)}
  if(writing_file$group[1]=="group2"){all_ids<-c(201:245)}
  if(writing_file$group[1]=="group3"){all_ids<-c(301:345)}
  
  totals = data.frame(matrix(ncol = 4, nrow = length(all_ids)))
  colnames(totals)<-c("AnonId","validations","writing_val","writing_train")
  
  for(i in 1:length(all_ids)){
    totals$AnonId[i] = all_ids[i]
    totals$validations[i] = val_completions_summary[as.character(all_ids[i])]
    totals$writing_val[i] = wri_completions_from_val_summary[as.character(all_ids[i])]
    totals$writing_train[i] = wri_completions_summary[as.character(all_ids[i])]
  }
  
  totals[, 2:4] <- sapply(totals[, 2:4], as.numeric)
  
  numHIT_totals <- totals %>%
    replace(is.na(.), 0) %>%
    mutate(sum = rowSums(.[2:4]))%>%
    mutate(numHIT_bonus = ifelse(sum>=100, 16*multiplier,
                                 ifelse(sum>=50, 6*multiplier,
                                        ifelse(sum>=10,1*multiplier,0))))
  return(numHIT_totals)
}

# BASELINE
base_numHIT_totals=calculate_numHIT_bonus(base_writing,base_val,1.1)
# round 4: for worker AP..........K add 10 to final HITs number when calculating bonus
do thing

# LING ON SIDE
LotS_numHIT_totals=calculate_numHIT_bonus(LotS_writing,LotS_val,1.1)

# LING IN LOOP
LitL_numHIT_totals=calculate_numHIT_bonus(LitL_writing,LitL_val,1.1)


######### calculate validation pass bonus #########
calculate_validation_bonus<-function(validation_file){
  if(validation_file$group[1]=="group1"){all_ids<-c(101:145)}
  if(validation_file$group[1]=="group2"){all_ids<-c(201:245)}
  if(validation_file$group[1]=="group3"){all_ids<-c(301:345)}
  
  validation_file<-filter(validation_file,label!="no_winner")
  
  check_correct = data.frame(matrix(ncol = 3, nrow = nrow(validation_file)))
  colnames(check_correct)<-c("AnonId","original_label","validated_label")
  
  for(i in 1:nrow(validation_file)){
    check_correct$AnonId[i] = unlist(validation_file$annotator_ids[i])[1]
    check_correct$original_label[i] = unlist(validation_file$annotator_labels[i])[1]
    check_correct$validated_label[i] = validation_file$label[i]
  }
  
  check_correct2<-check_correct%>%
    mutate(same=case_when(original_label==validated_label ~ 1,
                          original_label!=validated_label ~0))%>%
    group_by(AnonId)%>%
    summarise(mean_agree=mean(same),count=n())
  
  check_correct3<-merge(data.frame(AnonId=all_ids),check_correct2,by="AnonId",all=T)
  
  check_correct4<-check_correct3%>%
    replace(is.na(.), 0) %>%
    mutate(validation_bonus = case_when(mean_agree>=0.95 ~ 5,
                                        mean_agree<95 ~ 0))
  
  return(check_correct4)
}

# BASELINE
base_validation_totals<-calculate_validation_bonus(base_val)
# calcuate weighted mean for total validation
weighted.mean(base_validation_totals$mean_agree,base_validation_totals$count)

# LING ON SIDE
LotS_validation_totals<-calculate_validation_bonus(LotS_val)
# calcuate weighted mean for total validation
weighted.mean(LotS_validation_totals$mean_agree,LotS_validation_totals$count)

# LING IN LOOP
LitL_validation_totals<-calculate_validation_bonus(LitL_val)
# calcuate weighted mean for total validation
weighted.mean(LitL_validation_totals$mean_agree,LitL_validation_totals$count)


######### check accuracy within validation items too #########
# (this doesn't affect the bonus, but it's good info to have in case considering removing someone) #
calculate_validation_accuracy<-function(validation_file){
    if(validation_file$group[1]=="group1"){all_ids<-c(101:145)}
    if(validation_file$group[1]=="group2"){all_ids<-c(201:245)}
    if(validation_file$group[1]=="group3"){all_ids<-c(301:345)}
  
    validation_file<-filter(validation_file,label!="no_winner")
    
    checks_full = NULL
    
    for(j in 2:5){
      checks_temp = data.frame(matrix(ncol = 3, nrow = nrow(validation_file)))
      colnames(checks_temp)<-c("AnonId","original_label","validated_label")
      for(i in 1:nrow(validation_file)){
        checks_temp$AnonId[i] = unlist(validation_file$annotator_ids[i])[j]
        checks_temp$original_label[i] = unlist(validation_file$annotator_labels[i])[j]
        checks_temp$validated_label[i] = validation_file$label[i]
      }
      checks_full = rbind(checks_full,checks_temp)
    }
    
    checks_full2<-checks_full%>%
      mutate(same=case_when(original_label==validated_label ~ 1,
                            original_label!=validated_label ~0))%>%
      group_by(AnonId)%>%
      summarise(mean_agree=mean(same),count=n())
    
    checks_full3<-merge(data.frame(AnonId=all_ids),checks_full2,by="AnonId",all=T)
    
    return(checks_full3)
}

# BASELINE
base_val_accuracies<-calculate_validation_accuracy(base_val)
weighted.mean(base_val_accuracies$mean_agree,base_val_accuracies$count,na.rm=T)

# LING ON SIDE
LotS_val_accuracies<-calculate_validation_accuracy(LotS_val)
weighted.mean(LotS_val_accuracies$mean_agree,LotS_val_accuracies$count,na.rm=T)

# LING IN LOOP
LitL_val_accuracies<-calculate_validation_accuracy(LitL_val)
weighted.mean(LitL_val_accuracies$mean_agree,LitL_val_accuracies$count,na.rm=T)

######### calculate heuristic checkboxes bonus #########
# this one used in round 2, not relevant after that
# calculate_checkbox_numbers<-function(dat){
#   dat2<-dat%>%
#     group_by(AnonId,heuristic_checked)%>%
#     summarise(count_writing=n()/3)%>%
#     rename("writer_label"=heuristic_checked)
# }

calculate_checkbox_numbers<-function(dat){
  bonus_amts<-read.csv(paste0("for_mturk/heuristic_payment_",round,".csv"))
  dat2<-merge(dat,bonus_amts,all=T)
  dat3<-dat2%>%
    group_by(AnonId,heuristic_checked)%>%
    summarise(chkbox_amt_writing = sum(bonus), count_writing=n())%>%
    rename("writer_label"=heuristic_checked)
  return(dat3)
}

calculate_checkbox_accuracy<-function(dat,by_heur=F){
  dat$writer_label=NA
  dat$AnonId=NA
  for(i in 1:nrow(dat)){
    dat$writer_label[i]<-dat$heuristic_labels[i][[1]][1]
    dat$AnonId[i]<-dat$annotator_ids[i][[1]][1]
  }
  
  bonus_amts<-read.csv(paste0("for_mturk/heuristic_payment_",round,".csv"))
  dat2<-merge(dat,bonus_amts,all=T)
  
  dat_accuracy<-dat2%>%
    mutate(accuracy=case_when(heuristic_gold_label==writer_label ~ 1,
                              heuristic_gold_label!=writer_label ~0))%>%
    {if(by_heur) dplyr::group_by(.,AnonId,heuristic,writer_label) else . } %>%
    {if(!by_heur) dplyr::group_by(.,AnonId,writer_label) else . } %>%
    dplyr::summarise(pct_correct = mean(accuracy), 
                     chkbox_amt_val = sum(bonus),
                     count_vals=dplyr::n())
  return(dat_accuracy)
}

calculate_wighted_heuristics<-function(dat){
  dat2<-dat%>%
    #mutate(weighted_total = (count_writing + count_vals)*plyr::round_any(pct_correct, .1, f = ceiling))%>%
    mutate(weighted_total = (chkbox_amt_writing + chkbox_amt_val)*plyr::round_any(pct_correct, .1, f = ceiling))%>%
    #mutate(weighted_total = ifelse(is.na(count_vals), count_writing, weighted_total))%>%
    mutate(weighted_total = ifelse(is.na(chkbox_amt_val), chkbox_amt_writing, weighted_total))%>%
    mutate(weighted_total = case_when(writer_label=="No" ~ 0,
                                      writer_label=="Yes" ~ weighted_total))%>%
    mutate(heur_bonus_total = round(weighted_total, digits=2))%>%
    filter(writer_label=="Yes")
  return(dat2)
}

# LING ON SIDE
LotS_heur_numbers<-calculate_checkbox_numbers(LotS_writing)
LotS_heur_accuracy<-calculate_checkbox_accuracy(LotS_val_final)

LotS_heuristics <- merge(LotS_heur_numbers,LotS_heur_accuracy, all=T)
LotS_weighted_heuristics <- calculate_wighted_heuristics(LotS_heuristics)
#see how each individual did in different heuristicss
LotS_heur_by_worker <- calculate_checkbox_accuracy(LotS_val_final, by_heur=T)

# LING IN LOOP
LitL_heur_numbers<-calculate_checkbox_numbers(LitL_writing)
LitL_heur_accuracy<-calculate_checkbox_accuracy(LitL_val_final)

LitL_heuristics <- merge(LitL_heur_numbers,LitL_heur_accuracy, all=T)
LitL_weighted_heuristics <- calculate_wighted_heuristics(LitL_heuristics)
#see how each individual did in different heuristicss
LitL_heur_by_worker <- calculate_checkbox_accuracy(LitL_val_final, by_heur=T)

LitL_heur_by_worker2<-LitL_heur_by_worker %>% mutate(count_vals = count_vals*3)
write.csv(LitL_heur_by_worker2,paste0("files/worker_data/",round,"_worker_heuristic_error_rates.csv"))


######### calculate slack participation bonus #########
# LING IN LOOP
slack<-read.csv("../slack_data/slack-data-11-10-to-11-16.csv",stringsAsFactors = F)
slack<-rename(slack,"AnonId"=anon_id)
slack_names<-read.csv("../../SECRET/ling_in_loop_SECRET/anon_slack_names.csv")
slacks=merge(slack,slack_names,by="AnonId",all=T)

slack_bonus<-slacks%>%
  select(AnonId,Slack_name,total_msgs)%>%
  filter(AnonId!="admin")%>%
  filter(!is.na(total_msgs))%>%
  mutate(slack_bonus = ifelse(total_msgs>10,10,
                              ifelse(total_msgs>0,1.5,0)))

# Add any per-person adjustmetnts to the bonus here
smaller_bonus<-c('336') # these workers had a high number of interactions, but it was mostly to ask when more HITs are coming
higher_bonus<-c('')
for(i in 1:length(smaller_bonus)){
  slack_bonus$slack_bonus[slack_bonus$AnonId==smaller_bonus[i]]<-1.5
  slack_bonus$slack_bonus[slack_bonus$AnonId==higher_bonus[i]]<-10
}

# This person added a helpful comment after data was pulled, so including them here
#slack_bonus[nrow(slack_bonus) + 1,] = c("342","TK",1,1.5)


######### TOTAL BONUSES FOR EACH WORKER #########
all_bonuses_numHITs<-rbind(base_numHIT_totals,LotS_numHIT_totals,LitL_numHIT_totals)
all_bonuses_validated<-rbind(base_validation_totals,LotS_validation_totals,LitL_validation_totals)
all_bonuses_heuristics<-rbind(LotS_weighted_heuristics,LitL_weighted_heuristics)
all_bonuses<-merge(all_bonuses_numHITs, all_bonuses_validated, by = "AnonId",all = TRUE)
all_bonuses2<-merge(all_bonuses, all_bonuses_heuristics, by = "AnonId", all=TRUE)
all_bonuses3<-merge(all_bonuses2, slack_bonus, by = "AnonId", all = TRUE)
all_bonuses4<-merge(all_bonuses3, anon_codes, by = "AnonId", all = TRUE)

total_bonuses<-all_bonuses4%>% 
  replace_na(list(slack_bonus=0))%>%
  replace_na(list(heur_bonus_total=0))%>%
  mutate(validation_bonus = ifelse((writing_val+writing_train)<25,0,validation_bonus))%>%
  mutate(total_bonus = numHIT_bonus+validation_bonus+as.numeric(slack_bonus)+as.numeric(heur_bonus_total))%>%
  select(AnonId, WorkerId, numHIT_bonus, validation_bonus, heur_bonus_total, slack_bonus, total_bonus)

# for push to repo
to_push<-select(total_bonuses, -WorkerId)
write.csv(to_push,paste0("files/worker_data/",round,"_bonuses.csv"))

# for actually paying
ass_ids<-read.csv("../../SECRET/ling_in_loop_SECRET/assignment_ids.csv")
bonus_with_ass_ids<-merge(total_bonuses,ass_ids[2:3],by="WorkerId",all=T)

pay_bonus<-filter(bonus_with_ass_ids,total_bonus!=0)

write.csv(pay_bonus,paste0("../../SECRET/ling_in_loop_SECRET/",round,"_bonuses.csv"))

# update_bonus<-pay_bonus%>%
#   select(WorkerId,AssignmentId,AnonId,total_bonus,numHIT_bonus)%>%
#   mutate(updated_bonus = case_when(numHIT_bonus == 1 ~ 0.05,
#                                    numHIT_bonus == 6 ~ 0.3,
#                                    numHIT_bonus == 16 ~ 0.8,
#                                    numHIT_bonus == 0 ~ 0))%>%
#   select(-numHIT_bonus,-total_bonus)%>%
#   filter(updated_bonus!=0)
# write.csv(update_bonus,paste0("../../SECRET/ling_in_loop_SECRET/",round,"_UPDATED_bonuses.csv"))
# to_push2<-select(update_bonus, -WorkerId)
# write.csv(to_push2,paste0("files/worker_data/",round,"_UPDATED_bonuses.csv"))

######### AGGREGATE ERROR RATES PER WORKER #########
all_validation_rates<-rbind(base_val_accuracies,LotS_val_accuracies,LitL_val_accuracies)
errors<-merge(all_validation_rates,all_bonuses_validated,by="AnonId")

errors2<-errors%>%
  rename("mean_agree_validating"=mean_agree.x,
         "mean_validated"=mean_agree.y,
         "count_validations"=count.x,
         "count_writing"=count.y)%>%
  select(-validation_bonus)%>%
  mutate(mean_validated=na_if(mean_validated,0))%>%
  mutate(count_writing=na_if(count_writing,0))%>%
  filter(!(is.na(count_validations)&is.na(count_writing)))%>%
  mutate("low_raw_agreement" = ifelse(mean_agree_validating < 0.7 | mean_validated < 0.7,"low","good"))%>%
  replace_na(list(low_raw_agreement = "good"))

write.csv(errors2,paste0("files/worker_data/",round,"_worker_error_rates.csv"))
         