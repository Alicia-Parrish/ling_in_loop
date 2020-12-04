ROUND=$1
SAMPLE=$2

cd ..
cd ..
BASE_DIR=$PWD

DATA_DIR=${BASE_DIR}/tasks/data
ITEREVAL=${BASE_DIR}/tasks/data/iterative_eval/val_itercombined.jsonl
MNLIEVAL=${BASE_DIR}/tasks/data/mnli_mismatched/val_mismatched_mnli.jsonl
MODELS_DIR=${BASE_DIR}/models

export PYTHONPATH=${BASE_DIR}/jiant:$PYTHONPATH

echo $DATA_DIR


python jiant/jiant/scripts/preproc/litl/make_sampled_configs.py \
--data_base ${DATA_DIR} \
--itereval_path ${ITEREVAL} \
--mnlieval_path ${MNLIEVAL} \
--round ${ROUND} \
--sample ${SAMPLE}

echo Hypothesis only

python jiant/jiant/scripts/preproc/litl/make_sampled_configs.py \
--data_base ${DATA_DIR} \
--itereval_path ${ITEREVAL} \
--mnlieval_path ${MNLIEVAL} \
--sample ${SAMPLE} \
--round ${ROUND} \
--hypothesis
