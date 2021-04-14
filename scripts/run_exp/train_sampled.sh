rounds=('1' '2' '3' '4' '5')
models=('roberta-large' 'roberta-large-mnli')

cd ..
cd itereval_and_jiant_commands

for model in "${models[@]}"
do
	for round in "${rounds[@]}"
	do
		echo ${model}, round ${round}
		sh get_sampled_runscripts.sh ${round} ${model} cross_eval
		sh ${model}_train_sampled_cross_eval_${round}_run.sh
	done
done