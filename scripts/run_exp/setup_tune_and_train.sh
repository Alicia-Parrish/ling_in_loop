rounds=('1' '2' '3' '4' '5')
models=('roberta-large' 'roberta-large-mnli')

cd ..
analysis_dir=$PWD/analysis
cd ..
repo=$PWD
echo ${repo}
cd scripts/itereval_and_jiant_commands

python ${analysis_dir}/bootstrap_training_data.py --repo ${repo}


for round in "${rounds[@]}"
do
	echo Creating configs for round ${round}
	sh create-task-configs-all.sh ${round} ${model}
	sh get-sampled-configs-all.sh ${round} cross_eval
done

for model in "${models[@]}"
do
	for round in "${rounds[@]}"
	do
		echo Tokenize and cache for ${model} round ${round}
		sh tokenization-and-cache-all.sh ${round} ${model}
		sh tokenization-and-cache-all-cross_eval ${round} ${model}
	done
done