TASK_NAME=$1
MODEL_TYPE=$2
LR=$3
EPOCHS=$4
TRAIN_BATCH=$5

BASE_DIR=/scratch/wh629/research/irt/new_tasks
MODELS_DIR=${BASE_DIR}/models
DATA_DIR=${BASE_DIR}/tasks
CACHE_DIR=${BASE_DIR}/cache
RUN_CONFIG_DIR=${BASE_DIR}/run_configs

module purge
module load anaconda3/5.3.1
module load cuda/10.0.130
module load gcc/6.3.0

source activate ./env
export PYTHONPATH=jiant/

EVAL_BATCH_MULT=2

if [ ${TRAIN_BATCH} == 8 ]
then
	VAL_INTERVAL=5118
elif [ ${TRAIN_BATCH} == 16 ]
then
	VAL_INTERVAL=2559
fi

OUTPUT_DIR=${BASE_DIR}/experiments/${MODEL_TYPE}/${TASK_NAME}/${LR}_${TRAIN_BATCH}_${EPOCHS}
RUN_CONFIG=${RUN_CONFIG_DIR}/${MODEL_TYPE}/${TASK_NAME}.json

# Generate run configs
/scratch/wh629/research/irt/new_tasks/env/bin/python jiant/jiant/proj/main/scripts/configurator.py \
    SimpleAPIMultiTaskConfigurator ${RUN_CONFIG} \
    --task_config_base_path ${DATA_DIR}/configs \
    --task_cache_base_path ${CACHE_DIR}/${MODEL_TYPE} \
    --train_task_name_list ${TASK_NAME} \
    --val_task_name_list ${TASK_NAME} \
    --train_batch_size ${TRAIN_BATCH} \
    --eval_batch_multiplier ${EVAL_BATCH_MULT} \
    --epochs ${EPOCHS}

sbatch --export=DATA_DIR=$DATA_DIR,MODELS_DIR=$MODELS_DIR,CACHE_DIR=$CACHE_DIR,RUN_CONFIG=$RUN_CONFIG,OUTPUT_DIR=$OUTPUT_DIR,TASK_NAME=$TASK_NAME,MODEL_TYPE=$MODEL_TYPE,VAL_INTERVAL=$VAL_INTERVAL,LR=$LR task_noseed.sbatch