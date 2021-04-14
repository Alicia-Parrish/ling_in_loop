TASK_NAME=$1
MODEL_TYPE=$2
TRAIN_SIZE=$3
TRIALS=$4
LR=$5
TRAIN_BATCH=$6

cd ..
SCRIPT_DIR=$PWD
cd ..
cd ..

BASE_DIR=$PWD
echo $BASE_DIR

MODELS_DIR=${BASE_DIR}/models
DATA_DIR=${BASE_DIR}/tasks
CACHE_DIR=${BASE_DIR}/cache
RUN_CONFIG_DIR=${BASE_DIR}/run_configs

export PYTHONPATH=${BASE_DIR}/jiant:$PYTHONPATH

# Submit task
EPOCHS=10
EVAL_BATCH_MULT=2
NO_IMP=10
echo $TRAIN_BATCH
VAL_INTERVAL=$((TRAIN_SIZE / ${TRAIN_BATCH}))
echo LR: $LR EPOCH: $EPOCHS BATCH: $TRAIN_BATCH VAL_INT: $VAL_INTERVAL

for i in $(seq 1 $TRIALS)
do
	echo $i
	OUTPUT_DIR=${BASE_DIR}/models/roberta-large-mnli_only-custom/best/${i}
	RUN_CONFIG=${BASE_DIR}/models/roberta-large-mnli_only-custom/run_configs/best/${i}.json

	# Generate run configs
	${BASE_DIR}/env/bin/python ${BASE_DIR}/jiant/jiant/proj/main/scripts/configurator.py \
	    SimpleAPIMultiTaskConfigurator ${RUN_CONFIG} \
	    --task_config_base_path ${DATA_DIR}/raw_data/${TASK_NAME}/configs \
	    --task_cache_base_path ${CACHE_DIR}/${MODEL_TYPE} \
	    --train_task_name_list ${TASK_NAME} \
	    --val_task_name_list ${TASK_NAME} \
	    --train_batch_size ${TRAIN_BATCH} \
	    --eval_batch_multiplier ${EVAL_BATCH_MULT} \
	    --epochs ${EPOCHS}

	sbatch --export=MODELS_DIR=$MODELS_DIR,RUN_CONFIG=$RUN_CONFIG,OUTPUT_DIR=$OUTPUT_DIR,TASK_NAME=$TASK_NAME,MODEL_TYPE=$MODEL_TYPE,VAL_INTERVAL=$VAL_INTERVAL,LR=$LR,NO_IMP=$NO_IMP,BASE_DIR=$BASE_DIR ${SCRIPT_DIR}/litl.sbatch
done