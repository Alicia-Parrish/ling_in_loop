round=$1

cd ..
SCRIPT_DIR=$PWD/analysis
cd ..

BASE_DIR=$PWD
NLI_DATA=${BASE_DIR}/NLI_data
PRED_DATA=${BASE_DIR}/predictions

ITEREVAL=${NLI_DATA}/4_iterevals/val_itercombined.jsonl

treatments=( 'baseline' 'LotS' 'LitL' )
declare -A treat2nlidir=( ["baseline"]="1_Baseline_protocol" ["LotS"]="2_Ling_on_side_protocol" ["LitL"]="3_Ling_in_loop_protocol" )

combineds=( 'combined' 'separate' )
inputs=( 'full' 'hyp' )

python ${SCRIPT_DIR}/move_best_preds.py

for treatment in "${treatments[@]}"
do
	treat_dir=${treat2nlidir[$treatment]}

	# # training data stats
	python ${SCRIPT_DIR}/corpus_stats.py \
		--verbose \
		--pushstats \
		--round ${round} \
		--fname ${NLI_DATA}/${treat_dir}/train_round${round}_${treatment}.jsonl

	echo ${NLI_DATA}/${treat_dir}/train_round${round}_${treatment}.jsonl

	# predictions
	if [ $treatment == 'baseline' ]
	then
		valname=val_round${round}_base.jsonl
	else
		valname=val_round${round}_${treatment}.jsonl
	fi

	for combined in "${combineds[@]}"
	do
		# in-distribution validations
		for input in "${inputs[@]}"
		do
			python ${SCRIPT_DIR}/summarize_evals.py \
				${NLI_DATA}/${treat_dir}/${valname} \
				${PRED_DATA}/${treat_dir}/r${round}/${combined}/${input}/val_preds.p
		done

		# iterative evaluations
		python ${SCRIPT_DIR}/summarize_evals.py \
			${ITEREVAL} \
			${PRED_DATA}/4_iterevals/${treat_dir}/r${round}/${combined}/val_preds.p
	done
done

python ${SCRIPT_DIR}/get_plots_tables.py
python ${SCRIPT_DIR}/get_plots_tables.py --combined