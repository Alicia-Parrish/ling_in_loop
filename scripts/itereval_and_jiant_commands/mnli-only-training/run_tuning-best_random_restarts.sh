TRIALS=$1
LR=$2
BATCH=$3

TASK=mnli
MODEL=roberta-large
SIZE=392702
# LR=0.00001
# BATCH=32

sh tuning_best_random_restarts.sh ${TASK} ${MODEL} ${SIZE} ${TRIALS} ${LR} ${BATCH}
