import argparse
import pandas as pd
import os
import json
from shutil import copyfile
import torch


def split_run_name(run_name, split_by='_'):
    name_list = run_name.split(split_by)
    if len(name_list) == 2:
        comb = 'combined'
    else:
        comb = name_list[-1]

    return name_list[0], name_list[1], comb


def move_anli_preds(current_base, target_base, fname, treat2dir):
    current_subdirs = next(os.walk(current_base))[1]
    print(current_subdirs)

    moved = []
    target_dirs = []
    for run_name in current_subdirs:
        treat, iteration, comb = split_run_name(run_name)

        target_dir = os.path.join(
            target_base,
            treat2dir[treat],
            f'r{iteration}',
            comb,
        )

        target_dirs.append({'name': run_name, 'target_dir': target_dir})
        if os.path.isdir(target_dir):
            continue

        os.makedirs(target_dir, exist_ok=True)
        copyfile(os.path.join(current_base, run_name, fname), os.path.join(target_dir, fname))
        moved.append(run_name)

    print('='*90+'Move Complete'+'='*90)
    print(f'Moved {len(moved)}')
    return target_dirs


def summarize_preds_and_tables(targets, anli_gold, preds_fname):
    pred2label={
        0: "contradiction",
        1: "entailment",
        2: "neutral",
    }

    with open(anli_gold, 'r') as f:
        exs = [json.loads(ex) for ex in f.readlines()]

    summaries = []
    for target_dict in targets:
        run_name, target_dir = target_dict['name'], target_dict['target_dir']
        treat, iteration, comb = split_run_name(run_name)

        with open(os.path.join(target_dir, preds_fname), 'rb') as f:
            preds = torch.load(f)['mnli']['preds']

        assert len(exs) == len(preds), f'Length mismatch\nExamples: {len(exs)}\nPreds: {len(preds)}'

        summary = pd.DataFrame(exs)
        summary['pred'] = pd.Series(preds).apply(lambda x: pred2label[x])
        summary['correct'] = summary['label'].eq(summary['pred'])

        summary.to_csv(os.path.join(target_dir, f'{os.path.basename(anli_gold).split(".")[0]}_preds.csv'))

        row_template = {'treat': treat, 'iter': iteration, 'comb': comb}

        temp_row = {key:value for key, value in row_template.items()}
        temp_row['tag'] = 'combined'
        temp_row['acc'] = summary['correct'].sum() / summary.shape[0]
        summaries.append(temp_row)

        for tag in summary['tag'].unique():
            temp_summary = summary.loc[summary['tag'] == tag, :]
            temp_row = {key: value for key, value in row_template.items()}
            temp_row['tag'] = tag
            temp_row['acc'] = temp_summary['correct'].sum() / temp_summary.shape[0]
            summaries.append(temp_row)

    return summaries


def sum_anli(args):
    treat2dir = {
        'baseline': '1_Baseline_protocol',
        'LotS': '2_Ling_on_side_protocol',
        'LitL': '3_Ling_in_loop_protocol',
    }

    repo = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath('__file__'))))
    if args.experiment_base == '':
        args.experiment_base = os.path.join(repo, 'experiments', args.model, 'anli_evals')
    if args.target_base == '':
        args.target_base = os.path.join(repo, 'predictions', args.model, 'anli_evals')
    if args.eval_out == '':
        args.eval_out = os.path.join(repo, 'eval_summary', args.model, 'anli_evals')

    target_dirs = move_anli_preds(args.experiment_base, args.target_base, args.fname, treat2dir)
    summaries = summarize_preds_and_tables(target_dirs, args.anli_file, args.fname)

    os.makedirs(args.eval_out, exist_ok=True)
    with open(os.path.join(args.eval_out, 'eval_summaries.jsonl'), 'w') as f:
        for row in summaries:
            f.write(f'{json.dumps(row)}\n')

    print('='*90+'Complete'+'='*90)
    print(f'Summarized accs saved to {os.path.join(args.eval_out, "eval_summaries.jsonl")}')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()

    parser.add_argument('anli_file')
    parser.add_argument('--model', help='name of pretrained model', required=True)

    # Optional arguments
    parser.add_argument('--target_base', default='')
    parser.add_argument('--experiment_base', default='')
    parser.add_argument('--fname', default='val_preds.p')
    parser.add_argument('--eval_out', default='')

    args = parser.parse_args()

    sum_anli(args)