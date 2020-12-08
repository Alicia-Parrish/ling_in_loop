import argparse
import os
import re
import json

import pandas as pd
import numpy as np
from move_best_preds import move_best as val_and_itereval_move
from summarize_evals import summarize_itereval
from summarize_dataset import move_preds as mnli_move
from summarize_dataset import summarize_preds_and_tables as mnli_summarize
from summarize_dataset import split_run_name

'''
move_best(args, iteration_only=-1, post=None, return_preds=False)

    parser.add_argument('--model', help='name of pretrained model', required=True)

    # Optional arguments
    parser.add_argument('--best_runs', help='file name of best runs', default='')
    parser.add_argument('--exp_dir', help='base dir of experiment runs', default='')
'''

'''
summarize_itereval(args)

    # Required arguments
    parser.add_argument('data', help='name of val file')
    parser.add_argument('preds', help='model predictions')

    # Optional arguments
    parser.add_argument('--out_dir', help='directory for results', default='')
'''

def summarize_sampled(args):
    treat2dir = {
        'baseline': '1_Baseline_protocol',
        'LotS': '2_Ling_on_side_protocol',
        'LitL': '3_Ling_in_loop_protocol',
    }

    repo = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath('__file__'))))
    if args.experiment_base == '':
        args.experiment_base = os.path.join(repo, 'experiments', args.model, f'{args.dataset_name}_evals')
    if args.target_base == '':
        args.target_base = os.path.join(repo, 'predictions', args.model, f'{args.dataset_name}_evals')

    pred_dir = os.path.join(repo, 'predictions', args.model)
    if args.best_runs == '':
        best_configs_fname = os.path.join(pred_dir, 'best_configs', 'best_configs.csv')
    else:
        best_configs_fname = args.best_runs

    best_configs = pd.read_csv(best_configs_fname, index_col=False, names=['run', 'hyperparams', 'acc'])

    collected_evals = []
    for idx, row in best_configs.iterrows():
        treat, iteration, comb = split_run_name(row['run'])
        if int(iteration) != args.round:
            continue

        best_base = os.path.join(repo, 'experiments', args.model, row['run'], args.sample_name)
        for partition in args.partitions.split(','):

            single_acc = {
                'run': row['run'],
                'hyperparams': row['hyperparams'],
                'sample_type': args.sample_name,
                'sample_partition': partition,
            }
            best_dir = os.path.join(best_base, partition, row['hyperparams'])
            with open(os.path.join(best_dir, args.metrics_fname), 'r') as f:
                single_acc['acc'] = json.load(f)[args.metrics_key]
            collected_evals.append(single_acc)

    if not args.no_heldout:
        iterevals = []
        mnli_evals = []
        for partition in args.partitions.split(','):
            post = f'{os.path.join(args.sample_name, partition)}'

            # Move all val and itereval preds for given round and partition
            _, itereval_dirs, itereval_names = val_and_itereval_move(
                args,
                iteration_only=args.round,
                post=post,
                return_preds=True,
                sample=True,
            )

            assert len(itereval_dirs) == len(itereval_names), f'Names: {itereval_names}\nDirs: {itereval_dirs}'

            # Get summary tables for moved iterevals
            itereval_accs = []
            for itereval_dir, itereval_name in zip(itereval_dirs, itereval_names):
                itereval_acc_dict = summarize_itereval(
                    args,
                    data=args.itereval_data,
                    preds=os.path.join(itereval_dir, post, args.fname),
                    out_dir=os.path.join(itereval_dir, post),
                    with_return=True,
                )
                treat, iteration, comb = split_run_name(itereval_name)

                accs_list = []
                for dataset, itereval_acc in itereval_acc_dict.items():
                    itereval_acc['dataset'] = dataset
                    itereval_acc['treat'] = treat
                    itereval_acc['iter'] = iteration
                    itereval_acc['comb'] = comb
                    itereval_acc['sample_type'] = args.sample_name
                    itereval_acc['sample_partition'] = partition
                    accs_list.append(itereval_acc)

                itereval_accs.append(pd.concat(accs_list, ignore_index=True))
            iterevals.append(pd.concat(itereval_accs, ignore_index=True))


            # Move all mnli predictions for given round and partition
            mnli_pred_dicts = mnli_move(
                args.experiment_base, args.target_base, args.fname,
                treat2dir,
                iteration_only=args.round,
                post=post,
            )

            # Get mnli summaries for each run
            mnli_summaries = mnli_summarize(
                mnli_pred_dicts,
                args.dataset_data,
                args.fname,
                args.breakdown,
                post=post,
            )

            mnli_summaries_df = pd.DataFrame(mnli_summaries)
            mnli_summaries_df['sample_type'] = args.sample_name
            mnli_summaries_df['sample_partition'] = partition
            mnli_evals.append(mnli_summaries_df)

    if args.sample_out == '':
        args.sample_out = os.path.join(repo, 'eval_summary', args.model, 'sample', args.sample_name, f'r{args.round}')
    os.makedirs(args.sample_out, exist_ok=True)

    collected_out = os.path.join(args.sample_out, 'collected.csv')
    pd.DataFrame(collected_evals).to_csv(collected_out)
    print(f'Write out collected_out to\n{collected_out}')

    if not args.no_heldout:
        itereval_out = os.path.join(args.sample_out, 'itereval.csv')
        mnli_out = os.path.join(args.sample_out, 'mnli.csv')

        pd.concat(iterevals, ignore_index=True).to_csv(itereval_out)
        print(f'Write out itereval to\n{itereval_out}')
        pd.concat(mnli_evals, ignore_index=True).to_csv(mnli_out)
        print(f'Write out mnlieval to\n{mnli_out}')
        print('='*90+'Complete'+'='*90)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()

    repo = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath('__file__'))))

    parser.add_argument('--model', help='name of pretrained model', required=True)
    parser.add_argument('--itereval_data', help='name of itereval file', required=True)
    parser.add_argument('--dataset_data', required=True)

    # Sample arguments
    parser.add_argument('--sample_name', default='cross_eval')
    parser.add_argument('--partitions', default='0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1.0')
    parser.add_argument('--sample_out', default='')
    parser.add_argument('--no_heldout', action='store_true')

    # Optional arguments
    parser.add_argument('--dataset_name', default='mnli')
    parser.add_argument('--round', default=5, type=int)

    # From move best
    parser.add_argument('--best_runs', help='file name of best runs', default='')
    parser.add_argument('--exp_dir', help='base dir of experiment runs', default='')

    # From dataset summary
    parser.add_argument('--out_dir', help='directory for results', default='')
    parser.add_argument('--target_base', default='')
    parser.add_argument('--experiment_base', default='')
    parser.add_argument('--fname', default='val_preds.p')
    parser.add_argument('--breakdown', default='')

    # For collected data
    parser.add_argument('--metrics_fname', help='file name of metrics', default='val_metrics.json')
    parser.add_argument('--metrics_key', help='key to get metric', default='aggregated')

    args = parser.parse_args()

    summarize_sampled(args)
