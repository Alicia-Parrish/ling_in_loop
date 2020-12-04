TASK_NAME=$1
HYP=$2

cd ..
cd ..
BASE_DIR=$PWD

DATA_DIR=${BASE_DIR}/tasks/data/${TASK_NAME}
ITEREVAL=${BASE_DIR}/tasks/data/iterative_eval/val_itercombined.jsonl
MNLIEVAL=${BASE_DIR}/tasks/data/mnli_mismatched/val_mnli.jsonl
MODELS_DIR=${BASE_DIR}/models

export PYTHONPATH=${BASE_DIR}/jiant:$PYTHONPATH

echo $DATA_DIR

if [ -z "$HYP" ] 
then
    echo Standard

    python jiant/jiant/scripts/preproc/litl/make_task_config.py \
    --data_path ${DATA_DIR} \
    --itereval_path ${ITEREVAL} \
    --mnlieval_path ${MNLIEVAL}

elif [ "$HYP" == "true" ] 
then
    echo Hypothesis only

    python jiant/jiant/scripts/preproc/litl/make_task_config.py \
    --data_path ${DATA_DIR} \
    --itereval_path ${ITEREVAL} \
    --mnlieval_path ${MNLIEVAL} \
    --hypothesis
fi
