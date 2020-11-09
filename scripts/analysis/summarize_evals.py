import argparse
import pandas as pd
import os
import json
import torch
import numpy as np


def load_data_preds(args):
    with open(args.data, 'r') as f:
        ex = [json.loads(line) for line in f]

    with open(args.preds, 'rb') as f:
        preds = torch.load(f)

    if os.path.basename(os.path.dirname(args.preds)) == 'hyp':
        return ex, preds['mnli_hyp']['preds']
    else:
        return ex, preds['mnli']['preds']


def summarize_itereval(args):
    exs, preds = load_data_preds(args)

    # preprocessed hans non-entailment -> contradiction
    pred2label = {
        'glue': {
            0: "contradiction",
            1: "entailment",
            2: "neutral",
        },
        'hans': {
            0: "non-entailment",
            1: "entailment",
            2: "non-entailment",
        },
    }

    summaries = {
        'glue': [],
        'hans': [],
    }

    subpairsets = {
        'glue': set([]),
        'hans': set([]),
    }

    cases = {
        'glue': set([]),
        'hans': set([]),
    }

    for ex, pred in zip(exs, preds):
        dataset = ex['dataset']
        temp_ex = {key: value for key, value in ex.items()}
        temp_ex['pred'] = pred2label[dataset][pred]

        # unpack case and subcases
        if dataset == 'hans':
            if ex['label'] == 'contradiction':
                temp_ex['label'] = 'non-entailment'
            temp_ex['case'] = ex['case'][0]
            temp_ex['subcase'] = ex['subcase'][0]
            subpairsets[dataset].add((temp_ex['case'], temp_ex['subcase']))
            cases[dataset].add(temp_ex['case'])
        elif dataset == 'glue':
            for case, subcase in zip(temp_ex['case'], temp_ex['subcase']):
                temp_ex[case] = subcase
                subpairsets[dataset].add((case, subcase))
                cases[dataset].add(case)
        else:
            raise KeyError(f'{dataset}')

        temp_ex['correct'] = temp_ex['label'] == pred2label[dataset][pred]
        summaries[dataset].append(temp_ex)

    # summarize and save
    for dataset, summary in summaries.items():
        summary_preds = pd.DataFrame(summary)
        labels = set(list(pred2label[dataset].values()))

        accs = [{
            'case': 'combined',
            'subcase': 'combined',
            'label': 'combined',
            'acc': summary_preds['correct'].sum() / summary_preds.shape[0]
        }]

        for label in labels:
            subtemp = summary_preds.loc[summary_preds['label'] == label, :]
            if subtemp.shape[0] > 0:
                accs.append({
                    'case': 'combined',
                    'subcase': 'combined',
                    'label': label,
                    'acc': subtemp['correct'].sum() / subtemp.shape[0]
                })
            else:
                accs.append({
                    'case': 'combined',
                    'subcase': 'combined',
                    'label': label,
                    'acc': -1
                })

        if dataset == 'hans':
            for case in cases[dataset]:
                temp = summary_preds.loc[summary_preds['case'] == case, :]
                accs.append({
                    'case': case,
                    'subcase': 'combined',
                    'label': 'combined',
                    'acc': temp['correct'].sum() / temp.shape[0]
                })

                for label in labels:
                    subtemp = temp.loc[temp['label'] == label, :]
                    if subtemp.shape[0] > 0:
                        accs.append({
                            'case': case,
                            'subcase': 'combined',
                            'label': label,
                            'acc': subtemp['correct'].sum() / subtemp.shape[0]
                        })
                    else:
                        accs.append({
                            'case': case,
                            'subcase': 'combined',
                            'label': label,
                            'acc': -1
                        })

            for (case, subcase) in subpairsets[dataset]:
                temp = summary_preds.loc[summary_preds['case'] == case, :]
                temp = temp.loc[temp['subcase'] == subcase, :]
                accs.append({
                    'case': case,
                    'subcase': subcase,
                    'label': 'combined',
                    'acc': temp['correct'].sum() / temp.shape[0]
                })

                for label in labels:
                    subtemp = temp.loc[temp['label'] == label, :]
                    if subtemp.shape[0] > 0:
                        accs.append({
                            'case': case,
                            'subcase': subcase,
                            'label': label,
                            'acc': subtemp['correct'].sum() / subtemp.shape[0]
                        })
                    else:
                        accs.append({
                            'case': case,
                            'subcase': subcase,
                            'label': label,
                            'acc': -1
                        })
        elif dataset == 'glue':
            for case in cases[dataset]:
                temp = summary_preds.loc[summary_preds[case].notnull(), :]
                accs.append({
                    'case': case,
                    'subcase': 'combined',
                    'label': 'combined',
                    'acc': temp['correct'].sum() / temp.shape[0]
                })

                for label in labels:
                    subtemp = temp.loc[temp['label'] == label, :]
                    if subtemp.shape[0] > 0:
                        accs.append({
                            'case': case,
                            'subcase': 'combined',
                            'label': label,
                            'acc': subtemp['correct'].sum() / subtemp.shape[0]
                        })
                    else:
                        accs.append({
                            'case': case,
                            'subcase': 'combined',
                            'label': label,
                            'acc': -1
                        })

            for (case, subcase) in subpairsets[dataset]:
                temp = summary_preds.loc[summary_preds[case] == subcase, :]
                accs.append({
                    'case': case,
                    'subcase': subcase,
                    'label': 'combined',
                    'acc': temp['correct'].sum() / temp.shape[0]
                })

                for label in labels:
                    subtemp = temp.loc[temp['label'] == label, :]
                    if subtemp.shape[0] > 0:
                        accs.append({
                            'case': case,
                            'subcase': subcase,
                            'label': label,
                            'acc': subtemp['correct'].sum() / subtemp.shape[0]
                        })
                    else:
                        accs.append({
                            'case': case,
                            'subcase': subcase,
                            'label': label,
                            'acc': -1
                        })
        else:
            raise KeyError(f'{dataset}')

        summary_preds.to_csv(
            os.path.join(
                args.out_dir,
                f'{dataset}_preds.csv'
            )
        )

        pd.DataFrame(accs).to_csv(
            os.path.join(
                args.out_dir,
                f'{dataset}_summary.csv'
            )
        )



def summarize_val(args):
    exs, preds = load_data_preds(args)

    pred2label = {
        0: "contradiction",
        1: "entailment",
        2: "neutral",
    }

    summary = []
    for ex, pred in zip(exs, preds):
        temp_ex = {key: value for key, value in ex.items()}
        temp_ex["pred"] = pred2label[pred]
        temp_ex["correct"] = ex["label"] == pred2label[pred]
        summary.append(temp_ex)

    pd.DataFrame(summary).to_csv(
        os.path.join(
            args.out_dir,
            f'{os.path.basename(args.data).split(".")[0]}_preds.csv'
        )
    )


if __name__ == '__main__':
    parser = argparse.ArgumentParser()

    # Required arguments
    parser.add_argument('data', help='name of val file')
    parser.add_argument('preds', help='model predictions')

    # Optional arguments
    parser.add_argument('--out_dir', help='directory for results', default='')

    args = parser.parse_args()

    # repo = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath('__file__'))))
    if args.out_dir == '':
        args.out_dir = os.path.dirname(args.preds)

    if os.path.basename(args.data) == 'val_itercombined.jsonl':
        summarize_itereval(args)
    else:
        summarize_val(args)

    print('='*45 + f' Complete ' + '='*45 + f'\n{args.out_dir}')
