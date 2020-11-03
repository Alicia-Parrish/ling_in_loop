MODEL_TYPE=$1

cd ..
cd ..
BASE_DIR=$PWD

export PYTHONPATH=${BASE_DIR}/jiant:$PYTHONPATH

python jiant/jiant/proj/main/export_model.py \
    --model_type ${MODEL_TYPE} \
    --output_base_path ${BASE_DIR}/models/${MODEL_TYPE}

echo Downloaded ${MODEL_TYPE}