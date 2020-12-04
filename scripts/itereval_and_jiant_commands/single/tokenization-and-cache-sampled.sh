TASK_NAME=$1
SAMPLE=$2
MODEL_TYPE=$3
HYP=$4

cd ..
cd ..
BASE_DIR=$PWD

MODELS_DIR=${BASE_DIR}/models

export PYTHONPATH=${BASE_DIR}/jiant:$PYTHONPATH

if [ -z "$HYP" ] 
then
    TASK_NAME_HYP=${TASK_NAME}
elif [ "$HYP" == "true" ] 
then
    TASK_NAME_HYP=${TASK_NAME}_hyp
fi

echo Task config ${TASK_NAME_HYP}

python jiant/jiant/proj/main/tokenize_and_cache.py \
    --task_config_path ${BASE_DIR}/tasks/configs/${SAMPLE}/${TASK_NAME_HYP}_config.json \
    --model_type ${MODEL_TYPE} \
    --model_tokenizer_path ${BASE_DIR}/models/${MODEL_TYPE}/tokenizer \
    --output_dir ${BASE_DIR}/cache/${MODEL_TYPE}/${SAMPLE}/${TASK_NAME_HYP} \
    --phases train,val \
    --max_seq_length 128 \
    --do_iter \
    --smart_truncate

ls ${BASE_DIR}/cache/${MODEL_TYPE}/${SAMPLE}/${TASK_NAME_HYP}