models=('roberta-large' 'roberta-large-mnli')

cd ..
analysis_dir=$PWD/analysis
cd ..
repo=$PWD
cd scripts/itereval_and_jiant_commands


for model in "${models[@]}"
do
	sh summarize-evals-all.sh 1 ${model} true false false
	sh summarize-evals-all.sh 2 ${model} false false false
	sh summarize-evals-all.sh 3 ${model} false false false
	sh summarize-evals-all.sh 4 ${model} false false false
	sh summarize-evals-all.sh 5 ${model} false false true

	sh summarize-cross-evals.sh ${model}
	sh summarize-anli-evals.sh ${model}
	sh summarize-mnli-evals.sh ${model}

	python ${analysis_dir}/anli_breakdown.py --model ${model} --repo ${repo}
done

