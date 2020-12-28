TASK=mnli
MODEL=roberta-large
SIZE=392702

sh download-data.sh ${TASK}
sh tokenization-and-cache.sh ${TASK} ${MODEL}
sh tuning.sh ${TASK} ${MODEL} ${SIZE}
