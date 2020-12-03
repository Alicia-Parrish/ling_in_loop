library(dplyr)
library(xgboost)

set.seed(42)

# set the group to look at
this_group = "Baseline" # "Ling_on_side" # "Ling_in_loop" #

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

dat<-overlap_data %>% filter(group==this_group)

# Convert the Species factor to an integer class starting at 0 .. it's a requirement for XGBoost
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

#cv <- xgb.cv(data = xgb.train, nrounds = 3, nthread = 2, nfold = 5, metrics = list("mlogloss"),
#             max_depth = 3, eta = 1, objective = "multi:softprob", num_class=num_class)

# Define parameters
num_class = length(levels(labels))
params = list(
  booster="gblinear",
  objective="multi:softprob",
  #eval_metric="mlogloss",
  num_class=num_class
)

# Train the classifer
xgb.fit=xgb.train(
  params=params,
  data=xgb.train,
  nrounds=1000,
  nthreads=1,
  early_stopping_rounds=10,
  watchlist=list(val1=xgb.train,val2=xgb.test),
  verbose=0
)

# Review the final model and results
xgb.fit

# Predict outcomes with the test data
xgb.pred = predict(xgb.fit,test.data,reshape=T)
xgb.pred = as.data.frame(xgb.pred)
colnames(xgb.pred) = levels(labels)

# Use the predicted label with the highest probability
xgb.pred$prediction = apply(xgb.pred,1,function(x) colnames(xgb.pred)[which.max(x)])
xgb.pred$label = levels(labels)[test.label+1]

# Accuracy
result = sum(xgb.pred$prediction==xgb.pred$label)/nrow(xgb.pred)
print(paste("Final Accuracy for",this_group,"=",sprintf("%1.2f%%", 100*result)))

