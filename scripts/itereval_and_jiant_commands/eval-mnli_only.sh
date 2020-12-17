SCRIPT_DIR=$PWD
cd ..
cd ..
BASE_DIR=$PWD

MODELS_DIR=${BASE_DIR}/models
DATA_DIR=${BASE_DIR}/tasks
CACHE_DIR=${BASE_DIR}/cache
RUN_CONFIG_DIR=${BASE_DIR}/run_configs

export PYTHONPATH=${BASE_DIR}/jiant:$PYTHONPATH

# tasks=( 'baseline_5' 'LitL_5' 'LotS_5' 'eval_baseline_1' 'anlieval_baseline_1' 'mnlieval_baseline_1' )
tasks=( 'mnlieval_baseline_1' )

MODEL_PATH=${MODELS_DIR}/roberta-large-mnli_only-custom/best_model.p

MODEL_TYPE=roberta-large-mnli
EVAL_BATCH_MULT=2
TRAIN_BATCH=32

for TASK_NAME in "${tasks[@]}"
do
	echo ${TASK_NAME}
	OUTPUT_DIR=${BASE_DIR}/experiments/roberta-large-mnli_only/${TASK_NAME}
	RUN_CONFIG=${RUN_CONFIG_DIR}/roberta-large-mnli_only/${TASK_NAME}.json


	# Generate run configs
	python jiant/jiant/proj/main/scripts/configurator.py \
	    SingleTaskConfigurator ${RUN_CONFIG} \
	    --task_name mnli \
	    --train_batch_size ${TRAIN_BATCH} \
	    --task_config_path ${DATA_DIR}/configs/${TASK_NAME}_config.json \
	    --task_cache_path ${CACHE_DIR}/roberta-large/${TASK_NAME} \
	    --eval_batch_multiplier ${EVAL_BATCH_MULT} \
	    --do_val

	sbatch --export=MODEL_PATH=$MODEL_PATH,MODELS_DIR=$MODELS_DIR,RUN_CONFIG=$RUN_CONFIG,OUTPUT_DIR=$OUTPUT_DIR,TASK_NAME=$TASK_NAME,MODEL_TYPE=$MODEL_TYPE ${SCRIPT_DIR}/litl_mnli_eval.sbatch
done
