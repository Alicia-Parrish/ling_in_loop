ROUND=$1
SAMPLE=$2
HYP=$3

cd ..
cd ..
BASE_DIR=$PWD

DATA_DIR=${BASE_DIR}/tasks/data
ITEREVAL=${BASE_DIR}/tasks/data/iterative_eval/val_itercombined.jsonl
MNLIEVAL=${BASE_DIR}/tasks/data/mnli_mismatched/val_mnli.jsonl
MODELS_DIR=${BASE_DIR}/models

export PYTHONPATH=${BASE_DIR}/jiant:$PYTHONPATH

echo $DATA_DIR

if [ -z "$HYP" ] 
then
    echo Standard

    python jiant/jiant/scripts/preproc/litl/make_sampled_configs.py \
    --data_base ${DATA_DIR} \
    --itereval_path ${ITEREVAL} \
    --mnlieval_path ${MNLIEVAL} \
    --sample ${SAMPLE}

elif [ "$HYP" == "true" ] 
then
    echo Hypothesis only

    python jiant/jiant/scripts/preproc/litl/make_sampled_configs.py \
    --data_base ${DATA_DIR} \
    --itereval_path ${ITEREVAL} \
    --mnlieval_path ${MNLIEVAL} \
    --sample ${SAMPLE} \
    --hypothesis
fi
