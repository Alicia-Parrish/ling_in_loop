cd ..

sh summarize-evals-all.sh 1 roberta-large true false false
sh summarize-evals-all.sh 2 roberta-large false false false
sh summarize-evals-all.sh 3 roberta-large false false false
sh summarize-evals-all.sh 4 roberta-large false false false
sh summarize-evals-all.sh 5 roberta-large false false true

sh summarize-evals-all.sh 1 roberta-large-mnli true false false
sh summarize-evals-all.sh 2 roberta-large-mnli false false false
sh summarize-evals-all.sh 3 roberta-large-mnli false false false
sh summarize-evals-all.sh 4 roberta-large-mnli false false false
sh summarize-evals-all.sh 5 roberta-large-mnli false false true