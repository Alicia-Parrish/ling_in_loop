library(dplyr)
library(xgboost)

set.seed(42)

# get Train data
rounds <- c("r1","r2","r3","r4","r5")
labels <- c("entailment","neutral","contradiction")
groups <- c("Baseline", "Ling_on_side", "Ling_in_loop")
group_nums <- c("1","2","3")
g_label = c("base","LotS","LitL")
round = "round5"

overlap_data_train<-NULL
for(g in 1:length(groups)){
  for(i in 1:length(rounds)){
    for(j in 1:length(labels)){
      dat<-read.csv(paste0("../corpus_stats/",rounds[i],"/",group_nums[g],"_",groups[g],"_protocol/separate/overlap_",labels[j],".csv"))
      dat$label <- labels[j]
      #dat$round <- rounds[i]
      dat$group <- groups[g]
      overlap_data_train = rbind(overlap_data_train,dat)
    }
  }
}

# Get test data
overlap_data_test = NULL
for(g in 1:length(groups)){
  for(j in 1:length(labels)){
    dat<-read.csv(paste0("../corpus_stats/r5/",group_nums[g],"_",groups[g],"_protocol/val/combined/overlap_",labels[j],".csv"))
    dat$label <- labels[j]
    dat$group <- groups[g]
    overlap_data_test = rbind(overlap_data_test,dat)
  }
}

# Combine data
overlap_data_test2 <- overlap_data_test %>% select(-X, -pairID) %>% mutate(split = "test")
overlap_data_train2 <- overlap_data_train %>% select(-X) %>% rename("overlap" = X0) %>% mutate(split = "train")
overlap_data = rbind(overlap_data_test2,overlap_data_train2)
overlap_data$label <- as.factor(overlap_data$label)

# do separately for each protocol 
all_group = c("Baseline","Ling_on_side","Ling_in_loop")
results = data.frame(result = c(NA,NA,NA))

for(i in 1:length(all_group)){
  
  # Just this group
  dat<-overlap_data %>% filter(group==all_group[i])
  
  # Convert the label factor to an integer class starting at 0
  labels = dat$label
  label = as.integer(dat$label)-1
  dat$label = label
  
  # Make splits
  train.data = as.matrix(dat$overlap[dat$split=="train"])
  train.label = dat$label[dat$split=="train"]
  test.data = as.matrix(dat$overlap[dat$split=="test"])
  test.label = dat$label[dat$split=="test"]
  
  # Transform data into xgb.Matrix
  xgb.train = xgb.DMatrix(data=train.data,label=train.label)
  xgb.test = xgb.DMatrix(data=test.data,label=test.label)
  
  # Define parameters
  num_class = length(levels(labels))
  params = list(
    booster="gblinear",
    objective="multi:softprob",
    eval_metric="mlogloss",
    num_class=num_class
  )
  
  # Cross validation to determine nrounds
  xgbcv <- xgb.cv(data = xgb.train, 
                  params = params,
                  nrounds = 100, nfold = 5, showsd = T, 
                  print_every_n = 25, early_stopping_rounds = 10, maximize = F,
                  metrics = list("mlogloss"))
  
  best_iter = xgbcv$best_iteration
  
  # Train the classifer
  xgb.fit=xgb.train(
    params=params,
    data=xgb.train,
    nrounds=best_iter,
    verbose=0
  )
  
  # Review the final model and results
  # xgb.fit
  
  # Predict outcomes with the test data
  xgb.pred = predict(xgb.fit,test.data,reshape=T)
  xgb.pred = as.data.frame(xgb.pred)
  colnames(xgb.pred) = levels(labels)
  
  # Use the predicted label with the highest probability
  xgb.pred$prediction = apply(xgb.pred,1,function(x) colnames(xgb.pred)[which.max(x)])
  xgb.pred$label = levels(labels)[test.label+1]
  
  # Accuracy
  result = sum(xgb.pred$prediction==xgb.pred$label)/nrow(xgb.pred)
  #print(paste("Final Accuracy for",this_group,"=",sprintf("%1.2f%%", 100*result)))
  results$result[i] = paste("Final Accuracy for",all_group[i],"=",100*result)
}

#####################################
# simpler: just make linear model 

dat<-overlap_data %>% filter(group==all_group[3])

train = dat %>% filter(split=='train')
test_X = dat %>% filter(split=='test') %>% select(overlap)
test_y = dat %>% filter(split=='test') %>% select(label)

#model <- glm(label ~ overlap, family=multinom, data=train)  
#summary(model)
#pred <- predict(model, test_X, type="class", interval="confidence")  
#table(pred,test_y)

model <- multinom(label ~ overlap, data=train)
summary(model)
pred <- predict(model, test_X, type="class", interval="confidence") 
preds = cbind(test_y,pred)
preds2 <- preds %>%
  mutate(corr = case_when(label==pred ~ 1,
                          label!=pred ~ 0))
mean(preds2$corr)

43.74496-34.22 # baseline
42.54457-34.48 # lots
43.13402-36.25 # litl