#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=2
#SBATCH --time=72:00:00
#SBATCH --mem=40GB
#SBATCH --mail-type=ALL
#SBATCH --mail-user=wh629@nyu.edu
#SBATCH --output=/scratch/wh629/research/litl/logs/slurm_%j.out
#SBATCH --job-name=sample-tok

BASE_DIR=/scratch/wh629/research/litl/ling_in_loop

venv_path=${BASE_DIR}/env
source activate $venv_path

JIANT_PATH=${BASE_DIR}/jiant/jiant
export PYTHONPATH=jiant/

timestamp=$(date +%s)

cd $BASE_DIR/scripts/itereval_and_jiant_commands/ad_hoc
sh cross_eval-configs-tok.sh