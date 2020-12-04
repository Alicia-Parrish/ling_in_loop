cd ..

sh get-sampled-configs-all.sh 1 cross_eval
sh get-sampled-configs-all.sh 2 cross_eval
sh get-sampled-configs-all.sh 3 cross_eval
sh get-sampled-configs-all.sh 4 cross_eval

sh tokenization-and-cache-all-cross_eval.sh 1 roberta-large
sh tokenization-and-cache-all-cross_eval.sh 2 roberta-large
sh tokenization-and-cache-all-cross_eval.sh 3 roberta-large
sh tokenization-and-cache-all-cross_eval.sh 4 roberta-large