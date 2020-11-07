library(tidyverse)
library(rjson)
library(jsonlite)

setwd("C:/Users/NYUCM Loaner Access/Documents/GitHub/ling_in_loop/scripts")

set.seed(42)
round = "round2"

# banned words
words_e <- c("some", "there", "something", "people")
words_n <- c("many", "most", "may ", "might")
words_c <- c("not","n't","never","none","no")

#################### FUNCTIONS ####################
# function for reading in .jsonl files
read_json_lines <- function(file){
  con <- file(file, open = "r")
  on.exit(close(con))
  jsonlite::stream_in(con, verbose = FALSE)
}

# check for banned word
identify_banned_words<-function(dat){
  dat$present = NA
  for(i in 1:nrow(dat)){
    words = unlist(strsplit(dat$hypothesis[i]," "))
    for(j in 1:length(words)){
      if(dat$label[i]=="entailment" & words[j] %in% words_e){dat$present[i]<-as.character(words[j])}
      if(dat$label[i]=="neutral" & words[j] %in% words_n){dat$present[i]<-as.character(words[j])}
      if(dat$label[i]=="contradiction" & words[j] %in% words_c){dat$present[i]<-as.character(words[j])}
    }
  }
}

# check heuristic: restricted word in another label


# check heuristic: relative clause


#################### READ IN ####################
anon_codes = read.csv("../../SECRET/ling_in_loop_SECRET/anonymized_id_links.csv")
base_val<-read_json_lines(paste0("../NLI_data/1_Baseline_protocol/val_",round,"_baseline.jsonl"))
LotS_val<-read_json_lines(paste0("../NLI_data/2_Ling_on_side_protocol/val_",round,"_LotS.jsonl"))
LitL_val<-read_json_lines(paste0("../NLI_data/3_Ling_in_loop_protocol/val_",round,"_LitL.jsonl"))
base_train<-read_json_lines(paste0("../NLI_data/1_Baseline_protocol/train_",round,"_baseline.jsonl"))
LotS_train<-read_json_lines(paste0("../NLI_data/2_Ling_on_side_protocol/train_",round,"_LotS.jsonl"))
LitL_train<-read_json_lines(paste0("../NLI_data/3_Ling_in_loop_protocol/train_",round,"_LitL.jsonl"))


