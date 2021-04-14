rounds=('1' '2' '3' '4' '5')
models=('roberta-large' 'roberta-large-mnli')

cd ..
analysis_dir=$PWD/analysis
cd ..
repo=$PWD
cd scripts/itereval_and_jiant_commands


for model in "${models[@]}"
do
	for round in "${rounds[@]}"
	do
		echo ${model}, round ${round}
		sh summarize-evals-sampled.sh ${model} cross_eval ${round}
	done
	python ${analysis_dir}/anli_breakdown.py --model ${model} --repo ${repo}
done