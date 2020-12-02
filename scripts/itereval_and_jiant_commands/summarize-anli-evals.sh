model=$1

SH_SCRIPT_DIR=$PWD
cd ..
SCRIPT_DIR=$PWD/analysis
cd ..

BASE_DIR=$PWD
ANLI_FILE=${BASE_DIR}/tasks/data/anli_combined/val_anli.jsonl
echo $ANLI_FILE

cd ${SH_SCRIPT_DIR}
python ${SCRIPT_DIR}/summarize_anli.py ${ANLI_FILE} --model ${model}
