ROUND=$1
SAMPLE=$2

cd ..
cd ..
BASE_DIR=$PWD

DATA_DIR=${BASE_DIR}/tasks/data
ITEREVAL=${BASE_DIR}/tasks/data/iterative_eval/val_itercombined.jsonl
MNLIEVAL=${BASE_DIR}/tasks/data/mnli_mismatched/val_mismatched_mnli.jsonl
ANLIEVAL=${BASE_DIR}/tasks/data/anli_combined/val_anli.jsonl
MODELS_DIR=${BASE_DIR}/models

export PYTHONPATH=${BASE_DIR}/jiant:$PYTHONPATH

echo $DATA_DIR

# echo MNLI
# python jiant/jiant/scripts/preproc/litl/make_sampled_configs.py \
# --data_base ${DATA_DIR} \
# --itereval_path ${ITEREVAL} \
# --eval_paths ${MNLIEVAL},${ANLIEVAL} \
# --eval_names mnlieval,anlieval \
# --round ${ROUND} \
# --sample ${SAMPLE}

# echo Hypothesis only

# python jiant/jiant/scripts/preproc/litl/make_sampled_configs.py \
# --data_base ${DATA_DIR} \
# --itereval_path ${ITEREVAL} \
# --eval_paths ${MNLIEVAL},${ANLIEVAL} \
# --eval_names mnlieval,anlieval \
# --sample ${SAMPLE} \
# --round ${ROUND} \
# --hypothesis

python jiant/jiant/scripts/preproc/litl/make_sampled_configs.py \
--data_base ${DATA_DIR} \
--eval_paths ${ANLIEVAL} \
--eval_names anlieval \
--round ${ROUND} \
--sample ${SAMPLE} \
--no_indomain