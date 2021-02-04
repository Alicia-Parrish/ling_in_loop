library(quanteda)
library(tokenizers)
library(tidyverse)

setwd("C:/Users/NYUCM Loaner Access/Documents/GitHub/ling_in_loop/scripts")

STOPWORDS = c("i", "me", "my", "myself", "we", "our", "ours", "ourselves", "you", "your", "yours", "yourself", "yourselves", "he", "him", "his", "himself", "she", "her", "hers", "herself", "it", "its", "itself", "they", "them", "their", "theirs", "themselves", "what", "which", "who", "whom", "this", "that", "these", "those", "am", "is", "are", "was", "were", "be", "been", "being", "have", "has", "had", "having", "do", "does", "did", "doing", "a", "an", "the", "and", "but", "if", "or", "because", "as", "until", "while", "of", "at", "by", "for", "with", "about", "against", "between", "into", "through", "during", "before", "after", "above", "below", "to", "from", "up", "down", "in", "out", "on", "off", "over", "under", "again", "further", "then", "once", "here", "there", "when", "where", "why", "how", "all", "any", "both", "each", "few", "more", "most", "other", "some", "such", "no", "nor", "not", "only", "own", "same", "so", "than", "too", "very", "s", "t", "can", "will", "just", "don", "should", "now")
STOPWORDS2 = c('i', 'me', 'my', 'myself', 'we', 'our', 'ours', 'ourselves', 'you', "you're", "you've", "you'll", "you'd", 'your', 'yours', 'yourself', 'yourselves', 'he', 'him', 'his', 'himself', 'she', "she's", 'her', 'hers', 'herself', 'it', "it's", 'its', 'itself', 'they', 'them', 'their', 'theirs', 'themselves', 'what', 'which', 'who', 'whom', 'this', 'that', "that'll", 'these', 'those', 'am', 'is', 'are', 'was', 'were', 'be', 'been', 'being', 'have', 'has', 'had', 'having', 'do', 'does', 'did', 'doing', 'a', 'an', 'the', 'and', 'but', 'if', 'or', 'because', 'as', 'until', 'while', 'of', 'at', 'by', 'for', 'with', 'about', 'against', 'between', 'into', 'through', 'during', 'before', 'after', 'above', 'below', 'to', 'from', 'up', 'down', 'in', 'out', 'on', 'off', 'over', 'under', 'again', 'further', 'then', 'once', 'here', 'there', 'when', 'where', 'why', 'how', 'all', 'any', 'both', 'each', 'few', 'more', 'most', 'other', 'some', 'such', 'no', 'nor', 'not', 'only', 'own', 'same', 'so', 'than', 'too', 'very', 's', 't', 'can', 'will', 'just', 'don', "don't", 'should', "should've", 'now', 'd', 'll', 'm', 'o', 're', 've', 'y', 'ain', 'aren', "aren't", 'couldn', "couldn't", 'didn', "didn't", 'doesn', "doesn't", 'hadn', "hadn't", 'hasn', "hasn't", 'haven', "haven't", 'isn', "isn't", 'ma', 'mightn', "mightn't", 'mustn', "mustn't", 'needn', "needn't", 'shan', "shan't", 'shouldn', "shouldn't", 'wasn', "wasn't", 'weren', "weren't", 'won', "won't", 'wouldn', "wouldn't")

round = "round5"
base_val_combined<-read_json_lines(paste0("../NLI_data/1_Baseline_protocol/val_",round,"_base_combined.jsonl"))
LotS_val_combined<-read_json_lines(paste0("../NLI_data/2_Ling_on_side_protocol/val_",round,"_LotS_combined.jsonl"))
LitL_val_combined<-read_json_lines(paste0("../NLI_data/3_Ling_in_loop_protocol/val_",round,"_LitL_combined.jsonl"))

base_train_combined<-read_json_lines(paste0("../NLI_data/1_Baseline_protocol/train_",round,"_baseline_combined.jsonl"))
LotS_train_combined<-read_json_lines(paste0("../NLI_data/2_Ling_on_side_protocol/train_",round,"_LotS_combined.jsonl"))
LitL_train_combined<-read_json_lines(paste0("../NLI_data/3_Ling_in_loop_protocol/train_",round,"_LitL_combined.jsonl"))

bases <- rbind(base_val_combined %>% select(hypothesis,round),base_train_combined%>% select(hypothesis,round))
LotSs <- rbind(LotS_val_combined %>% select(hypothesis,round),LotS_train_combined%>% select(hypothesis,round))
LitLs <- rbind(LitL_val_combined %>% select(hypothesis,round),LitL_train_combined%>% select(hypothesis,round))

get_stats = function(vec){
  tokens(tokenizers::tokenize_words(paste(vec, collapse = ' '),stopwords = STOPWORDS2), remove_punct = TRUE, split_hyphens = TRUE) %>%
    textstat_lexdiv(measure = c("TTR", "CTTR", "K"))
}

get_stats2 = function(vec){
  tokens(tokenizers::tokenize_word_stems(paste(vec, collapse = ' '),stopwords = STOPWORDS2), remove_punct = TRUE, split_hyphens = TRUE) %>%
    textstat_lexdiv(measure = c("TTR", "CTTR", "K"))
}

texts = NULL
for(roundd in c("round1","round2","round3","round4","round5")){
  a = get_stats(bases$hypothesis[bases$round==roundd])
  b = get_stats(LotSs$hypothesis[LotSs$round==roundd])
  c = get_stats(LitLs$hypothesis[LitLs$round==roundd])
  a$group = "1"
  b$group = "2"
  c$group = "3"
  abc = rbind(a,b,c)
  abc$round = roundd
  texts = rbind(texts,abc)
}

(plt<-ggplot(data=texts,aes(x=round,y=TTR,col=group,group=group))+
    geom_line())