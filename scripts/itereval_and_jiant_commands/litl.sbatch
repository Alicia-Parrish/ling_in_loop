#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=2
#SBATCH --gres=gpu:p40:1
#SBATCH --time=72:00:00
#SBATCH --mem=40GB
#SBATCH --mail-type=ALL
#SBATCH --mail-user=wh629@nyu.edu
#SBATCH --output=/scratch/wh629/research/litl/logs/slurm_%j.out

BASE_DIR=/scratch/wh629/research/litl/ling_in_loop

venv_path=${BASE_DIR}/env
source activate $venv_path

JIANT_PATH=${BASE_DIR}/jiant/jiant
echo $RUN_CONFIG
echo $TASK_NAME
echo $MODELS_DIR
echo $MODEL_TYPE
echo $RUN_CONFIG
export PYTHONPATH=jiant/

timestamp=$(date +%s)

$venv_path/bin/python \
    $JIANT_PATH/proj/main/runscript.py   \
    run \
       --ZZsrc ${MODELS_DIR}/${MODEL_TYPE}/config.json \
       --jiant_task_container_config_path ${RUN_CONFIG} \
       --model_load_mode from_transformers \
       --learning_rate $LR \
       --force_overwrite \
       --do_train \
       --do_val \
       --do_save \
       --eval_every_steps $VAL_INTERVAL \
       --no_improvements_for_n_evals $NO_IMP \
       --save_checkpoint_every_steps $VAL_INTERVAL \
       --output_dir ${OUTPUT_DIR} \
       --write_val_preds 
