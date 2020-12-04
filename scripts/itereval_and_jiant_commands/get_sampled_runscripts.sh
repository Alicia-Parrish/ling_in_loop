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
python ${SCRIPT_DIR}/get_sampled_train_script.py ${BEST} \
	--sample ${sample} \
	--round ${round}