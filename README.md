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


## Full file structure
- HIT_templates
  - Description: This folder contains the html templates uploded to MTurk each round (writing and validaiton HITs), as well as the pre-test, introductory HIT and exit survey.
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
  - itereval_and_jiant_commands
  - plotting_scripts contains scripts for plotting model output results
- slack_data
  - Description: This folder contains anonymized data exported from slack to track worker engagement
- tasks
