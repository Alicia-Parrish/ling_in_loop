rounds=('1' '2' '3' '4' '5')
models=('roberta-large' 'roberta-large-mnli')

cd ..
cd itereval_and_jiant_commands

for model in "${models[@]}"
do
	for round in "${rounds[@]}"
	do
		echo ${model}, round ${round}, "$((${round}*3000))"
		sh train-models-all.sh ${round} ${model} "$((${round}*3000))"
	done
done