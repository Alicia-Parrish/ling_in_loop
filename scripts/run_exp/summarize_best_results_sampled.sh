rounds=('1' '2' '3' '4' '5')
models=('roberta-large' 'roberta-large-mnli')

cd ..
cd itereval_and_jiant_commands

for model in "${models[@]}"
do
	for round in "${rounds[@]}"
	do
		echo ${model}, round ${round}
		sh summarize-evals-sampled.sh ${model} cross_eval ${round}
	done
done