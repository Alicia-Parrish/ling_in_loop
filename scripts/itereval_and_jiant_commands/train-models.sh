TASK_NAME=$1
MODEL_TYPE=$2
SIZE=$3
HYP=$4

NO_IMP=10

cd ..
cd ..
BASE_DIR=$PWD

MODELS_DIR=${BASE_DIR}/models
DATA_DIR=${BASE_DIR}/tasks
CACHE_DIR=${BASE_DIR}/cache
RUN_CONFIG_DIR=${BASE_DIR}/run_configs

export PYTHONPATH=${BASE_DIR}/jiant:$PYTHONPATH

EVAL_BATCH_MULT=2

LRS=(0.000005 0.00001 0.00002 0.00003)
BATCHES=(16 32)
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

for LR in "${LRS[@]}"
do
    for TRAIN_BATCH in "${BATCHES[@]}"
    do
        VAL_INTERVAL=$(( SIZE / TRAIN_BATCH ))
        echo LR: $LR, BATCH: $TRAIN_BATCH, VAL_INT: $VAL_INTERVAL

        OUTPUT_DIR=${BASE_DIR}/experiments/${TASK_NAME_HYP}/${LR}_${TRAIN_BATCH}
        RUN_CONFIG=${RUN_CONFIG_DIR}/${MODEL_TYPE}/${TASK_NAME_HYP}_${LR}_${TRAIN_BATCH}.json

        # Generate run configs
        python jiant/jiant/proj/main/scripts/configurator.py \
            SingleTaskConfigurator ${RUN_CONFIG} \
            --task_name ${MNLI_HYP} \
            --train_batch_size ${TRAIN_BATCH} \
            --task_config_path ${DATA_DIR}/configs/${TASK_NAME_HYP}_config.json \
            --task_cache_path ${CACHE_DIR}/${MODEL_TYPE}/${TASK_NAME_HYP} \
            --eval_batch_multiplier ${EVAL_BATCH_MULT} \
            --epochs ${EPOCHS} \
            --do_train \
            --do_val

        sbatch --export=NO_IMP=$NO_IMP,DATA_DIR=$DATA_DIR,MODELS_DIR=$MODELS_DIR,CACHE_DIR=$CACHE_DIR,RUN_CONFIG=$RUN_CONFIG,OUTPUT_DIR=$OUTPUT_DIR,TASK_NAME=$TASK_NAME,MODEL_TYPE=$MODEL_TYPE,VAL_INTERVAL=$VAL_INTERVAL,LR=$LR litl.sbatch
    done
done