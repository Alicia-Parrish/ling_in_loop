rounds=('1' '2' '3' '4' '5')
models=('roberta-large' 'roberta-large-mnli')

cd ..
cd itereval_and_jiant_commands

for model in "${models[@]}"
do
	for round in "${rounds[@]}"
	do
		echo ${model}, round ${round}
		sh get-best-all.sh ${round} ${model}
	done

	sh get_best_runscripts.sh ${model}
	sh get_mnli_best_runscripts.sh ${model}
	sh get_anli_best_runscripts.sh ${model}
	
	sh ${model}_run.sh
	sh ${model}_mnli_run.sh
	sh ${model}_anli_run.sh
done