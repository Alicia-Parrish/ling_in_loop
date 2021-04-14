# ling_in_loop

## About The Project
This repo was used to collect and evaluate the project for "Does putting a linguist in the loop improve NLU data collection."

## The dataset
You can find annotations from each experimental protocol in the folder [NLI_data](https://github.com/Alicia-Parrish/ling_in_loop/tree/master/NLI_data). 
The subfolders 1_Baseline_protocol, 2_Ling_on_side_protocol, and 3_Ling_in_loop_protocol contain all data collected for this project. 
Within those subfolders, `train_round5_{{PROTOCOL}}_combined.jsonl` contains the full training set from all 5 rounds of data collection from that protocol, 
and `val_round5_{{PROTOCOL}}_combined.jsonl` contains the full validation set from all 5 rounds of data collection from that protocol.

The `.jsonl` files are structured as follows:
  - `AnonId`: (only in train datasets) A unique identifier for the MTurk worker who wrote the hypothesis for this example
  - `annotator_ids`: (only in val datasets) A list of unique identifiers for the MTurk workers who validated the example. The first element of the list was the original annotator who wrote the hypothesis.
  - `group`: Which protocol the worker had been assigned to
  - `round`: Which round of data collection the example was written in
  - `annotator_labels`: A list of labels assigned to this example. In the train dataset, the list will only contain one element
  - 'label`: The gold label assigned via majority vote of annotators. In the train dataset, this is just the label the example was written as
  - `pairID`: MNLI identifier
  - `promptID`: MNLI identifier
  - `premise`: Text taken from MNLI presented to the worker
  - `hypothesis`: Annotation written by the worker

## The dataset evaluations

### Set Up
Use the following commands to set up this repo and the `jiant` submodule.
```
git clone https://github.com/Alicia-Parrish/ling_in_loop.git
cd ling_in_loop
git submodule init
git submodule update
cd jiant
git checkout litl
```

Use the following command to set up the virtual environment in `ling_in_loop`.

```
conda env create -p ./env -f env.yml
```

### Produce Figures

To reproduce figures, use the notebook `/scripts/final_plots.ipynb`. In the first cell block, set the variables

- `_model` to the desired model 
  - either `roberta-large` or `roberta-large-mnli`
- `overwrite_plotting_data` 
  - `False` if running without new experiment results, otherwise `True` 

Then run the entire notebook. Plots can be found under `eval_summary/plots/<_model>`.

### Run Experiments

Experiments are run on NYU's computing cluster managed with Slurm. We provide shell scripts in `scripts/run_exp` to rerun experiments training on our collected data. 

To rerun experiments, first use the following commands to set up models, tokenize and cache data, and generate run configurations.

```
cd scripts/run_exp
sh export_models.sh
sh setup_tune_and_train.sh
```

Use the following command to tune and train models for each round.

```
sh tune_and_train.sh
```

Once models are finished training, use the following command to evaluate the best model for each round on evaluation sets.

```
sh evaluate_best_models_full.sh
```

When evaluations are complete, use the following command to summarize results.

```
sh summarize_best_results_full.sh
```

Once the above steps are complete, use the following commands to obtain results for subsampled training data. Similarly, please wait for models to finish training before evaluating and to finish evaluating before summarization.

```
sh train_subsampled.sh
sh evaluate_best_models_sampled.sh
sh summarize_best_results_sampled.sh
```

We provide shell scripts in `scripts/itereval_and_jiant_commands/mnli-only-training` to establish MNLI trained baselines. We first tune a model on MNLI using

```
cd scripts/itereval_and_jiant_commands/mnli-only-training
sh full-run.sh
```

Results can be found in `models/roberta-large-mnli_only-custom`.  Using the best learning rate (`lr`) and batch size (`bs`), we use the following commands to run, evaluate, and summarize MNLI trained models using 10 different restarts.

```
sh run_tuning-best_random_restarts.sh 10 <lr> <bs>
sh eval-mnli_only-best_random_restarts.sh 10
sh summarize_best_random_restarts.sh
```


## Full file structure
- HIT_templates
  - Description: This folder contains the html templates uploaded to MTurk each round (writing and validation HITs), as well as the pre-test, introductory HIT and exit survey.
- NLI_data
  - Description: This folder contains all data collected during the course of this experiment. See "The dataset" above for details
- corpus_stats
  - Description: This folder contains the following iterative metrics: hypothesis length, overlap rate, PMI. 
  - Rn refers to the round of data collection
    - n_{{PROTOCOL}}_protocol refers to the protocol the data comes from
      - combined is the full dataset for the protocol collected up until that round (so, in `r3`, it contains data from rounds 1, 2, and 3)
      - separate is the dataset from only that round and protocol (so, in `r3`, it only contains round 3 data)
- eval_summary
  - Description: This folder contains evaluation summary statistics from model runs on planned metrics
- predictions
  - Description: This folder contains model predictions for each subset of data
- scripts
  - Description: Data processing and analysis scripts
  - analysis contains scripts for analyzing model output
  - figures contains various visualizations created during the iterative analyses and for final evaluations
  - files contains the data preprocessed for uploading to MTurk
  - for_mturk contains scripts for pre-processing text, assessing crowdworker performance, and tracking data collection
  - run_exp contains shell scripts to train and evaluate models and summarize results
  - itereval_and_jiant_commands contains additional control shell scripts
  - plotting_scripts contains scripts for plotting model output results
- slack_data
  - Description: This folder contains anonymized data exported from slack to track worker engagement
- tasks
  - Description: `jiant` configurations and configured data for experiments
  - configs contains `jiant` run configurations
  - data contains `jiant` configured data
