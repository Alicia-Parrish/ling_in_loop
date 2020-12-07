import argparse
import pandas as pd
import os
import json
from shutil import copyfile
import torch

from move_best_preds import move_single_pred


def split_run_name(run_name, split_by='_'):
    name_list = run_name.split(split_by)
    if len(name_list) == 2:
        comb = 'combined'
    else:
        comb = name_list[-1]

    return name_list[0], name_list[1], comb


def move_preds(current_base, target_base, fname, treat2dir, iteration_only=-1, post=None):
    current_subdirs = next(os.walk(current_base))[1]
    print(current_subdirs)

    moved = []
    target_dirs = []
    for run_name in current_subdirs:
        treat, iteration, comb = split_run_name(run_name)

        if iteration_only > 0 and int(iteration) != iteration_only:
            continue

        target_dir = os.path.join(
            target_base,
            treat2dir[treat],
            f'r{iteration}',
            comb,
        )

        target_dirs.append({'name': run_name, 'target_dir': target_dir})

        check_dir = os.path.join(target_dir, post) if not post is None else target_dir
        if os.path.exists(os.path.join(check_dir, fname)):
            continue

        os.makedirs(target_dir, exist_ok=True)
        move_single_pred(os.path.join(current_base, run_name), target_dir, post=post, fname=fname)
        moved.append(run_name)

    print('='*90+'Move Complete'+'='*90)
    print(f'Moved {len(moved)}')
    return target_dirs


def summarize_preds_and_tables(targets, gold, preds_fname, breakdown_tag=None, post=None):
    pred2label={
        0: "contradiction",
        1: "entailment",
        2: "neutral",
    }

    with open(gold, 'r') as f:
        exs = [json.loads(ex) for ex in f.readlines()]

    summaries = []
    for target_dict in targets:
        run_name, target_dir = target_dict['name'], target_dict['target_dir']
        treat, iteration, comb = split_run_name(run_name)

        if not post is None:
            target_dir = os.path.join(target_dir, post)

        with open(os.path.join(target_dir, preds_fname), 'rb') as f:
            preds = torch.load(f)['mnli']['preds']

        assert len(exs) == len(preds), f'Length mismatch\nExamples: {len(exs)}\nPreds: {len(preds)}'

        summary = pd.DataFrame(exs)
        summary['pred'] = pd.Series(preds).apply(lambda x: pred2label[x])
        summary['correct'] = summary['label'].eq(summary['pred'])

        summary.to_csv(os.path.join(target_dir, f'{os.path.basename(gold).split(".")[0]}_preds.csv'))

        row_template = {'treat': treat, 'iter': iteration, 'comb': comb}

        temp_row = {key: value for key, value in row_template.items()}

        if breakdown_tag is None:
            temp_row[breakdown_tag] = 'combined'
        else:
            temp_row['breakdown'] = 'combined'
        temp_row['acc'] = summary['correct'].sum() / summary.shape[0]
        summaries.append(temp_row)

        if not breakdown_tag is None:
            for breakdown in summary[breakdown_tag].unique():
                temp_summary = summary.loc[summary[breakdown_tag] == breakdown, :]
                temp_row = {key: value for key, value in row_template.items()}
                temp_row[breakdown_tag] = breakdown
                temp_row['acc'] = temp_summary['correct'].sum() / temp_summary.shape[0]
                summaries.append(temp_row)

    return summaries


def summarize(args):
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
    if args.eval_out == '':
        args.eval_out = os.path.join(repo, 'eval_summary', args.model, f'{args.dataset_name}_evals')

    target_dirs = move_preds(args.experiment_base, args.target_base, args.fname, treat2dir)

    if args.breakdown == '':
        summaries = summarize_preds_and_tables(target_dirs, args.file, args.fname)
    else:
        summaries = summarize_preds_and_tables(target_dirs, args.file, args.fname, args.breakdown)

    os.makedirs(args.eval_out, exist_ok=True)
    out_name = os.path.join(args.eval_out, 'eval_summaries.jsonl')
    with open(out_name, 'w') as f:
        for row in summaries:
            f.write(f'{json.dumps(row)}\n')

    print('='*90+'Complete'+'='*90)
    print(f'Summarized accs saved to {out_name}')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()

    parser.add_argument('file')
    parser.add_argument('--model', help='name of pretrained model', required=True)

    # Optional arguments
    parser.add_argument('--breakdown', default='')
    parser.add_argument('--target_base', default='')
    parser.add_argument('--experiment_base', default='')
    parser.add_argument('--fname', default='val_preds.p')
    parser.add_argument('--eval_out', default='')
    parser.add_argument('--dataset_name', default='mnli')

    args = parser.parse_args()

    summarize(args)