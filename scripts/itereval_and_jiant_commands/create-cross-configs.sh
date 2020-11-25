ROUND=$1
HYP=$2

cd ..
cd ..
BASE_DIR=$PWD

DATA_DIR=${BASE_DIR}/tasks/data
ITEREVAL=${BASE_DIR}/tasks/data/iterative_eval/val_itercombined.jsonl
MODELS_DIR=${BASE_DIR}/models

export PYTHONPATH=${BASE_DIR}/jiant:$PYTHONPATH

echo $DATA_DIR

if [ -z "$HYP" ] 
then
    echo Standard

    python jiant/jiant/scripts/preproc/litl/make_cross_config.py \
    --data_base ${DATA_DIR} \
    --round ${ROUND}

elif [ "$HYP" == "true" ] 
then
    echo Hypothesis only

    python jiant/jiant/scripts/preproc/litl/make_cross_config.py \
    --data_base ${DATA_DIR} \
    --round ${ROUND} \
    --hypothesis
fi