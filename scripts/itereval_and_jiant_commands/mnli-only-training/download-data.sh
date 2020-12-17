TASK=$1

cd ..
cd ..
cd ..

BASE_DIR=$PWD
echo $BASE_DIR

export PYTHONPATH=${BASE_DIR}/jiant:$PYTHONPATH
python ${BASE_DIR}/jiant/jiant/scripts/download_data/runscript.py \
	download \
    --tasks ${TASK} \
    --output_path ${BASE_DIR}/tasks/raw_data/${TASK}

echo Downloaded ${TASK}