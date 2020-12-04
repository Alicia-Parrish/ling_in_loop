model=$1

SH_SCRIPT_DIR=$PWD
cd ..
SCRIPT_DIR=$PWD/analysis
cd ..

BASE_DIR=$PWD
BEST=${BASE_DIR}/predictions/${model}/best_configs/best_configs.csv
echo $BEST

cd ${SH_SCRIPT_DIR}
python ${SCRIPT_DIR}/get_eval_run_script.py ${BEST} \
	--eval_shell mnli-eval-models.sh \
	--mod _mnli \
	--no_cross