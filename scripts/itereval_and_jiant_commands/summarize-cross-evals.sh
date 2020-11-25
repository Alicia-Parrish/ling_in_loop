cd ..
SCRIPT_DIR=$PWD/analysis
cd ..

REPO=$PWD
echo ${REPO}

CROSS_BASE=${REPO}/experiments/cross_evals


cd ${SCRIPT_DIR}
python summarize_cross_preds.py ${CROSS_BASE}
