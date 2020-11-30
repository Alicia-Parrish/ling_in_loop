import argparse
import pandas as pd
import os
import json
import csv
from shutil import copyfile
from summarize_evals import summarize_val


def move_best(args):
    treat2dir = {
        'baseline': '1_Baseline_protocol',
        'LotS': '2_Ling_on_side_protocol',
        'LitL': '3_Ling_in_loop_protocol',
    }

    repo = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath('__file__'))))
    pred_dir = os.path.join(repo, 'predictions', args.model)
    task_configs = os.path.join(repo, 'tasks', 'configs')

    cross_evals = []
    for (dirpath, dirnames, filenames) in os.walk(args.cross_base):
        cross_evals.extend(dirnames)
        break

    moved = []
    summaries = []
    for cross_eval in cross_evals:
        train, val = cross_eval.split('-')
        train_treat, val_treat = train.split('_')[0], val.split('_')[0]
        iteration = train.split('_')[1]
        comb = 'combined' if len(train.split('_')) == 2 else train.split('_')[-1]

        target_dir = os.path.join(
            pred_dir,
            'cross_evals',
            treat2dir[train_treat],
            f'r{iteration}',
            comb,
            treat2dir[val_treat]
        )

        if os.path.isdir(target_dir):
            continue

        os.makedirs(target_dir, exist_ok=True)

        source_dir = os.path.join(
            args.cross_base,
            cross_eval
        )
        copyfile(os.path.join(source_dir, 'val_preds.p'), os.path.join(target_dir, 'val_preds.p'))

        moved.append(cross_eval)

        with open(os.path.join(task_configs, f'{cross_eval}_config.json'), 'r') as f:
            cross_config = json.load(f)
        val_file = cross_config['paths']['val']

        args.out_dir = target_dir
        summary = summarize_val(args, data=val_file, preds=os.path.join(target_dir, 'val_preds.p'), with_return=True)
        summaries.append((cross_eval, summary['correct'].sum()/summary.shape[0]))

    with open(os.path.join(pred_dir,'cross_evals','summary.csv'), 'a') as f:
        writer = csv.writer(f)
        for summ in summaries:
            writer.writerow(summ)

    print(f'Complete\nCopied {len(moved)} files')
    print('='*90)
    for move in moved:
        print(move)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()

    parser.add_argument('cross_base', help='base directory of cross evals')
    parser.add_argument('--model', help='pretrained model name', required=True)

    args = parser.parse_args()

    move_best(args)
