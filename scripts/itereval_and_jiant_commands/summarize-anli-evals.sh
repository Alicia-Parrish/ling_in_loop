model=$1

SH_SCRIPT_DIR=$PWD
cd ..
SCRIPT_DIR=$PWD/analysis
cd ..

BASE_DIR=$PWD
FILE=${BASE_DIR}/tasks/data/anli_combined/val_anli.jsonl
echo $FILE

cd ${SH_SCRIPT_DIR}
python ${SCRIPT_DIR}/summarize_dataset.py ${FILE} \
	--model ${model} \
	--breakdown tag \
	--dataset_name anli
