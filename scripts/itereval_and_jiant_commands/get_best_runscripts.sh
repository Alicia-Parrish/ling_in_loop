model=$1

cd ..
SCRIPT_DIR=$PWD/analysis
cd ..

BASE_DIR=$PWD
BEST=${BASE_DIR}/predictions/${model}/best_configs/best_configs.csv
echo $BEST

cd ${SCRIPT_DIR}
python get_eval_run_script.py ${BEST}