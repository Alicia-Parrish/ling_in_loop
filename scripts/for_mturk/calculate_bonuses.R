library(tidyverse)
library(rjson)
library(jsonlite)
library(data.table)

setwd("C:/Users/NYUCM Loaner Access/Documents/GitHub/ling_in_loop/scripts")

set.seed(42)

# function for reading in .jsonl files
read_json_lines <- function(file){
  con <- file(file, open = "r")
  on.exit(close(con))
  jsonlite::stream_in(con, verbose = FALSE)
}

######### get all the data you'll ever need...
anon_codes = read.csv("../../SECRET/ling_in_loop_SECRET/anonymized_id_links.csv")
base_writing<-read_json_lines("../NLI_data/1_Baseline_protocol/train_round1_baseline.jsonl")
LotS_writing<-read_json_lines("../NLI_data/2_Ling_on_side_protocol/train_round1_LotS.jsonl")
LitL_writing<-read_json_lines("../NLI_data/3_Ling_in_loop_protocol/train_round1_LitL.jsonl")
base_val<-read_json_lines("../../SECRET/ling_in_loop_SECRET/full_validation_files/val_round1_base_alldata.jsonl")
LotS_val<-read_json_lines("../../SECRET/ling_in_loop_SECRET/full_validation_files/val_round1_LotS_alldata.jsonl")
LitL_val<-read_json_lines("../../SECRET/ling_in_loop_SECRET/full_validation_files/val_round1_LitL_alldata.jsonl")


######### calculate number of HITs bonus #########
calculate_numHIT_bonus<-function(writing_file,validation_file){
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
    mutate(numHIT_bonus = ifelse(sum>=100, 16,
                                 ifelse(sum>=50, 6,
                                        ifelse(sum>=10,1,0))))
  return(numHIT_totals)
}

# BASELINE
base_numHIT_totals=calculate_numHIT_bonus(base_writing,base_val)

# LING ON SIDE
LotS_numHIT_totals=calculate_numHIT_bonus(LotS_writing,LotS_val)

# LING IN LOOP
LitL_numHIT_totals=calculate_numHIT_bonus(LitL_writing,LitL_val)


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

# LING ON SIDE
LotS_validation_totals<-calculate_validation_bonus(LotS_val)

# LING IN LOOP
LitL_validation_totals<-calculate_validation_bonus(LitL_val)


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

# LING ON SIDE
LotS_val_accuracies<-calculate_validation_accuracy(LotS_val)

# LING IN LOOP
LitL_val_accuracies<-calculate_validation_accuracy(LitL_val)

######### calculate heuristic checkboxes bonus #########
# LING ON SIDE


# LING IN LOOP



######### calculate slack participation bonus #########
# LING IN LOOP
slack<-read.csv("../slack_data/slack_data_11-2-2020.csv")
slack<-rename(slack,"AnonId"=anon_id)
slack_names<-read.csv("../../SECRET/ling_in_loop_SECRET/anon_slack_names.csv")
slacks=merge(slack,slack_names,by="AnonId")

slack_bonus<-slacks%>%
  select(AnonId,Slack_name,total_msgs)%>%
  filter(AnonId!="admin")%>%
  mutate(slack_bonus = ifelse(total_msgs>10,10,
                              ifelse(total_msgs>0,1.5,0)))

# Add any per-person adjustmetnts to the bonus here
smaller_bonus<-c('315','336') # these workers had a high number of interactions, but it was mostly to ask when more HITs are coming
for(i in 1:length(smaller_bonus)){
  slack_bonus$slack_bonus[slack_bonus$AnonId==smaller_bonus[i]]<-1.5
}


######### TOTAL BONUSES FOR EACH WORKER #########
all_bonuses_numHITs<-rbind(base_numHIT_totals,LotS_numHIT_totals,LitL_numHIT_totals)
all_bonuses_validated<-rbind(base_validation_totals,LotS_validation_totals,LitL_validation_totals)
all_bonuses<-merge(all_bonuses_numHITs, all_bonuses_validated, by = "AnonId",all = TRUE)
all_bonuses2<-merge(all_bonuses, slack_bonus, by = "AnonId",all = TRUE)# still need to merge slack bonus
all_bonuses3<-merge(all_bonuses2, anon_codes, by = "AnonId",all = TRUE)

total_bonuses<-all_bonuses3%>% 
  replace_na(list(slack_bonus=0))%>%
  mutate(total_bonus = numHIT_bonus+validation_bonus+slack_bonus)%>%
  select(AnonId, WorkerId, numHIT_bonus, validation_bonus, slack_bonus, total_bonus)

# for push to repo
to_push<-select(total_bonuses, -WorkerId)
write.csv(to_push,"files/worker_data/round1_bonuses.csv")

# for actually paying
ass_ids<-read.csv("../../SECRET/ling_in_loop_SECRET/assignment_ids.csv")
bonus_with_ass_ids<-merge(total_bonuses,ass_ids[2:3],by="WorkerId",all=T)

pay_bonus<-filter(bonus_with_ass_ids,total_bonus!=0)

write.csv(total_bonuses,"../../SECRET/ling_in_loop_SECRET/round1_bonuses.csv")




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

write.csv(errors2,"files/worker_data/round1_worker_error_rates.csv")
         