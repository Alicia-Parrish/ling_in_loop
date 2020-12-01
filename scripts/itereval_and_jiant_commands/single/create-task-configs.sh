TASK_NAME=$1
HYP=$2

cd ..
cd ..
BASE_DIR=$PWD

DATA_DIR=${BASE_DIR}/tasks/data/${TASK_NAME}
ITEREVAL=${BASE_DIR}/tasks/data/iterative_eval/val_itercombined.jsonl
ANLIEVAL=${BASE_DIR}/tasks/data/anli_combined/val_anli.jsonl
MODELS_DIR=${BASE_DIR}/models

export PYTHONPATH=${BASE_DIR}/jiant:$PYTHONPATH

echo $DATA_DIR

if [ -z "$HYP" ] 
then
    echo Standard

    python jiant/jiant/scripts/preproc/litl/make_task_config.py \
    --data_path ${DATA_DIR} \
    --itereval_path ${ITEREVAL} \
    --anlieval_path ${ANLIEVAL}

elif [ "$HYP" == "true" ] 
then
    echo Hypothesis only

    python jiant/jiant/scripts/preproc/litl/make_task_config.py \
    --data_path ${DATA_DIR} \
    --itereval_path ${ITEREVAL} \
    --anlieval_path ${ANLIEVAL} \
    --hypothesis
fi
