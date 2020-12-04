TASK_NAME=$1
MODEL_TYPE=$2
SIZE=$3
SAMPLE=$4
LR=$5
TRAIN_BATCH=$6
HYP=$7

NO_IMP=10

SCRIPT_DIR=$PWD
cd ..
cd ..
BASE_DIR=$PWD

MODELS_DIR=${BASE_DIR}/models
DATA_DIR=${BASE_DIR}/tasks
CACHE_DIR=${BASE_DIR}/cache
RUN_CONFIG_DIR=${BASE_DIR}/run_configs/${SAMPLE}

export PYTHONPATH=${BASE_DIR}/jiant:$PYTHONPATH

EVAL_BATCH_MULT=2
EPOCHS=20

if [ -z "$HYP" ] 
then
    TASK_NAME_HYP=${TASK_NAME}
    MNLI_HYP=mnli
elif [ "$HYP" == "true" ] 
then
    TASK_NAME_HYP=${TASK_NAME}_hyp
    MNLI_HYP=mnli_hyp
fi

echo Task config ${TASK_NAME_HYP}
echo ${MNLI_HYP}

if [[ "${MODEL_TYPE}" == *"roberta-large"* ]]
then
    CACHE_MODEL="roberta-large"
else
    CACHE_MODEL=${MODEL_TYPE}
fi

echo CACHE MODEL: $CACHE_MODEL


VAL_INTERVAL=$(( SIZE / TRAIN_BATCH ))
echo LR: $LR, BATCH: $TRAIN_BATCH, VAL_INT: $VAL_INTERVAL, MODEL: $MODEL_TYPE

OUTPUT_DIR=${BASE_DIR}/experiments/${MODEL_TYPE}/${TASK_NAME_HYP}/${SAMPLE}/${LR}_${TRAIN_BATCH}
RUN_CONFIG=${RUN_CONFIG_DIR}/${MODEL_TYPE}/${SAMPLE}/${TASK_NAME_HYP}_${LR}_${TRAIN_BATCH}.json

echo ${CACHE_DIR}/${CACHE_MODEL}/${SAMPLE}/${TASK_NAME_HYP}

# Generate run configs
python jiant/jiant/proj/main/scripts/configurator.py \
    SingleTaskConfigurator ${RUN_CONFIG} \
    --task_name ${MNLI_HYP} \
    --train_batch_size ${TRAIN_BATCH} \
    --task_config_path ${DATA_DIR}/configs/${SAMPLE}/${TASK_NAME_HYP}_config.json \
    --task_cache_path ${CACHE_DIR}/${CACHE_MODEL}/${SAMPLE}/${TASK_NAME_HYP} \
    --eval_batch_multiplier ${EVAL_BATCH_MULT} \
    --epochs ${EPOCHS} \
    --do_train \
    --do_val

sbatch --export=NO_IMP=$NO_IMP,DATA_DIR=$DATA_DIR,MODELS_DIR=$MODELS_DIR,CACHE_DIR=$CACHE_DIR,RUN_CONFIG=$RUN_CONFIG,OUTPUT_DIR=$OUTPUT_DIR,TASK_NAME=$TASK_NAME,MODEL_TYPE=$MODEL_TYPE,VAL_INTERVAL=$VAL_INTERVAL,LR=$LR ${SCRIPT_DIR}/litl.sbatch
    