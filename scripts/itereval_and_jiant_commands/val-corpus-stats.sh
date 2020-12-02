round=$1

cd ..
SCRIPT_DIR=$PWD/analysis
cd ..

BASE_DIR=$PWD
NLI_DATA=${BASE_DIR}/NLI_data

treatments=( 'base' 'LotS' 'LitL' )
declare -A treat2nlidir=( ["base"]="1_Baseline_protocol" ["LotS"]="2_Ling_on_side_protocol" ["LitL"]="3_Ling_in_loop_protocol" )

cd ${SCRIPT_DIR}

for treatment in "${treatments[@]}"
do
	treat_dir=${treat2nlidir[$treatment]}

	python ${SCRIPT_DIR}/corpus_stats.py \
		--verbose \
		--pushstats \
		--round ${round} \
		--fname ${NLI_DATA}/${treat_dir}/val_round${round}_${treatment}.jsonl \
		--out_dir ${BASE_DIR}/corpus_stats/r${round}/${treat_dir}/val/separate

	python ${SCRIPT_DIR}/corpus_stats.py \
		--verbose \
		--pushstats \
		--round ${round} \
		--fname ${NLI_DATA}/${treat_dir}/val_round${round}_${treatment}_combined.jsonl \
		--out_dir ${BASE_DIR}/corpus_stats/r${round}/${treat_dir}/val/combined
done