model=$1
sample=$2
round=$3

SH_SCRIPT_DIR=$PWD
cd ..
SCRIPT_DIR=$PWD/analysis
cd ..

BASE_DIR=$PWD
ITEREVAL=${BASE_DIR}/NLI_data/4_iterevals/val_itercombined.jsonl
FILE=${BASE_DIR}/tasks/data/mnli_mismatched/val_mismatched_mnli.jsonl
echo $ITEREVAL
echo $FILE

cd ${SH_SCRIPT_DIR}
python ${SCRIPT_DIR}/summarize_sampled.py \
	--model ${model} \
	--itereval_data ${ITEREVAL} \
	--dataset_data ${FILE} \
	--sample_name ${sample} \
	--breakdown genre \
	--dataset_name mnli \
	--round ${round}
