library(tidyverse)

setwd("C:/Users/NYUCM Loaner Access/Documents/GitHub/ling_in_loop/scripts")

base_base<-read.csv("files/WRITING_csv_for_mturk_upload/round3_group1_batch5_OLD.csv")
LotS_base<-read.csv("files/WRITING_csv_for_mturk_upload/round3_group2_batch5_OLD.csv")
#LitL_base<-read.csv("files/WRITING_csv_for_mturk_upload/round3_group3_batch5_OLD.csv")
LitL_base<-read.csv("files/WRITING_csv_for_mturk_upload/round3_group3_repost.csv")
  
base_done<-read.csv("../../SECRET/ling_in_loop_SECRET/raw_mturk_files/Group1_baseline/round3_writing/Batch_4249362_batch_results.csv")
LotS_done<-read.csv("../../SECRET/ling_in_loop_SECRET/raw_mturk_files/Group2_ling_on_side/round3_writing/Batch_4249363_batch_results.csv")
#LitL_done<-read.csv("../../SECRET/ling_in_loop_SECRET/raw_mturk_files/Group3_ling_in_loop/round3_writing/Batch_4249376_batch_results.csv")
LitL_done<-read.csv("../../SECRET/ling_in_loop_SECRET/raw_mturk_files/Group3_ling_in_loop/round3_writing/Batch_4249540_batch_results.csv")

base_completed_ids<-base_done$Input.promptID
LotS_completed_ids<-LotS_done$Input.promptID
LitL_completed_ids<-LitL_done$Input.promptID

base_new<-base_base%>%
  filter(!promptID %in% base_completed_ids)

LotS_new<-LotS_base%>%
  filter(!promptID %in% LotS_completed_ids)

LitL_new<-LitL_base%>%
  filter(!promptID %in% LitL_completed_ids)

write.csv(file="files/WRITING_csv_for_mturk_upload/round3_group1_repost.csv",base_new,row.names=FALSE)
write.csv(file="files/WRITING_csv_for_mturk_upload/round3_group2_repost.csv",LotS_new,row.names=FALSE)
write.csv(file="files/WRITING_csv_for_mturk_upload/round3_group3_repost2.csv",LitL_new,row.names=FALSE)
