rounds=('1' '2' '3' '4' '5')
models=('roberta-large' 'roberta-large-mnli')

cd ..
cd itereval_and_jiant_commands

for model in "${models[@]}"
do
	for round in "${rounds[@]}"
	do
		echo ${model}, round ${round}
		sh get_best_runscripts-sampled.sh ${model} ${round} cross_eval
		sh ${model}_sampled_cross_eval_${round}_run.sh
	done
done