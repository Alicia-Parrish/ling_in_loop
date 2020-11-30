TASK_NAME=$1
MODEL_TYPE=$2

cd ..
cd ..
BASE_DIR=$PWD

EXP_DIR=${BASE_DIR}/experiments/${MODEL_TYPE}/${TASK_NAME}

cd ${BASE_DIR}/scripts/analysis/

echo $PWD

python get_best_run.py \
	--exp_dir $EXP_DIR \
	--model $MODEL_TYPE
