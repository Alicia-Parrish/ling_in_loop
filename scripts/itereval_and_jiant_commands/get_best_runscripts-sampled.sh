model=$1
round=$2
sample=$3

SH_SCRIPT_DIR=$PWD
cd ..
SCRIPT_DIR=$PWD/analysis
cd ..

BASE_DIR=$PWD
BEST=${BASE_DIR}/predictions/${model}/best_configs/best_configs.csv
echo $BEST

cd ${SH_SCRIPT_DIR}
python ${SCRIPT_DIR}/get_eval_run_script.py ${BEST} \
	--sampled \
	--sample_name ${sample} \
	--eval_press eval,mnlieval \
	--round_only ${round}
