import os
import argparse
import pandas as pd
import numpy as np
import torch
import pickle
import joblib

def get_anli_acc(
        preds,
        anli_annotated,
        pred2annot,
        int2pred={0: 'contradiction', 1: 'entailment', 2: 'neutral'},
        subset_col=None,
        verbose=False,
):
    temp = anli_annotated

    skipped = 0
    # get predictions
    for idx, pred in enumerate(preds):
        try:
            temp.loc[pred2annot[idx], 'pred'] = int2pred[pred]
        except KeyError as ke:
            if verbose:
                print(f'Warning: {ke}')
            skipped += 1
    if verbose:
        print(skipped)

    assert temp['pred'].isna().sum() == 0

    temp['correct'] = temp['gold_label'] == temp['pred']

    if not subset_col is None and subset_col != 'combined':
        temp = temp.loc[temp[subset_col].ne('none'), :]

    return temp['correct'].sum() / temp.shape[0]

def get_anli_breakdowns(
    preds,
    anli_annotated,
    pred2annot,
    int2pred={0:'c', 1:'e', 2:'n'},
    breakdowns = [
        'combined',
        'Basic',
        'EventCoref',
        'Imperfection',
        'Numerical',
        'Reasoning',
        'Reference',
        'Tricky',
    ],
    verbose=False,
):
    ans = {}
    for breakdown in breakdowns:
        ans[breakdown] = get_anli_acc(
            preds,
            anli_annotated,
            pred2annot,
            subset_col=breakdown,
            verbose=verbose,
            int2pred=int2pred,
        )
    return ans

def anli_breakdown(args):
    verbose = args.verbose
    model = args.model
    repo = args.repo

    anli_annot_fname = os.path.join(repo, 'NLI_data', '5_ANLI', 'anli_annot_v0.2_combined_A1A2')
    pred2annot_dicts = os.path.join(repo, 'NLI_data', '5_ANLI', 'ANLI_dicts.p')

    anli_annot = joblib.load(anli_annot_fname)

    with open(pred2annot_dicts, 'rb') as f:
        pred2annot = pickle.load(f)['idxo2idxa']

    eval_dir = os.path.join(repo, 'eval_summary', model)
    sample_partitions = np.linspace(0.1, 1, 10)
    treats = {
        'baseline': '1_Baseline_protocol',
        'LotS': '2_Ling_on_side_protocol',
        'LitL': '3_Ling_in_loop_protocol',
    }
    rounds = range(1, 6)
    combineds = ['combined', 'separate']
    sampling = 'cross_eval'

    pred_base = os.path.join(repo, 'predictions', model, 'anli_evals')

    anli_accs = []
    for treat, treat_dir in treats.items():
        for r in rounds:
            for combined in combineds:
                print(treat, f'{r:.1f}', combined)
                # breakdown for collected
                ext_base = os.path.join(pred_base, treat_dir, f'r{r}', combined)
                breakdowns = get_anli_breakdowns(
                    torch.load(os.path.join(ext_base, 'val_preds.p'))['mnli']['preds'],
                    anli_annot,
                    pred2annot,
                    verbose=verbose,
                )
                for breakdown, acc in breakdowns.items():
                    anli_accs.append(
                        {
                            'treat': treat,
                            'iter': int(r),
                            'comb': combined,
                            'breakdown': breakdown,
                            'acc': acc,
                            'sample_partition': None,
                        }
                    )

                # breakdown for sampled collected
                for sample_partition in sample_partitions:
                    extext_base = os.path.join(ext_base, sampling, f'{sample_partition:.1f}')
                    breakdowns = get_anli_breakdowns(
                        torch.load(os.path.join(extext_base, 'val_preds.p'))['mnli']['preds'],
                        anli_annot,
                        pred2annot,
                        verbose=verbose,
                    )
                    for breakdown, acc in breakdowns.items():
                        anli_accs.append(
                            {
                                'treat': treat,
                                'iter': int(r),
                                'comb': combined,
                                'breakdown': breakdown,
                                'acc': acc,
                                'sample_partition': sample_partition,
                            }
                        )
    anli_accs_df = pd.DataFrame(anli_accs)

    out_dir = os.path.join(eval_dir, 'sample', sampling, 'final')
    os.makedirs(out_dir, exist_ok=True)
    anli_accs_df.to_csv(os.path.join(out_dir, 'anli_by_annotation.csv'))
    if verbose:
        print(f'Saved to {os.path.join(out_dir, "anli_by_annotation.csv")}')

if __name__ == '__main__':
    parser = argparse.ArgumentParser()

    # Required arguments
    parser.add_argument('--model', choices=['roberta-large', 'roberta-large-mnli'],
                        help='model results to summarize', required=True)
    parser.add_argument('--repo', help='repo directory', required=True)

    # Optional arguments(
    parser.add_argument('--verbose', help='whether to print statements', action='store_true')

    args = parser.parse_args()

    anli_breakdown(args)

