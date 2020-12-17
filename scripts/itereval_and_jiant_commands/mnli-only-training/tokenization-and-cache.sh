TASK=$1
MODEL_TYPE=$2

cd ..
cd ..
cd ..

BASE_DIR=$PWD
echo $BASE_DIR

export PYTHONPATH=${BASE_DIR}/jiant:$PYTHONPATH

python ${BASE_DIR}/jiant/jiant/proj/main/tokenize_and_cache.py \
    --task_config_path ${BASE_DIR}/tasks/configs/${TASK}_config.json \
    --model_type ${MODEL_TYPE} \
    --model_tokenizer_path ${BASE_DIR}/models/${MODEL_TYPE}/tokenizer \
    --output_dir ${BASE_DIR}/cache/${MODEL_TYPE}/${TASK} \
    --phases train,val,test \
    --max_seq_length 128 \
    --do_iter \
    --smart_truncate

ls ${BASE_DIR}/cache/${MODEL_TYPE}/${TASK}