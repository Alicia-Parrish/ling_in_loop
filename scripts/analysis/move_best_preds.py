import argparse
import pandas as pd
import os
from shutil import copyfile


def move_best(args):
    treat2dir = {
        'baseline': '1_Baseline_protocol',
        'LotS': '2_Ling_on_side_protocol',
        'LitL': '3_Ling_in_loop_protocol',
    }

    repo = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath('__file__'))))
    pred_dir = os.path.join(repo, 'predictions', args.model)

    if args.best_runs == '':
        best_configs_fname = os.path.join(pred_dir, 'best_configs', 'best_configs.csv')
    else:
        best_configs_fname = args.best_runs
    exp_dir = os.path.join(repo, 'experiments') if args.exp_dir == '' else args.exp_dir

    best_configs = pd.read_csv(best_configs_fname, index_col=False, names=['run', 'hyperparams', 'acc'])

    target_dirs = []
    for idx, row in best_configs.iterrows():
        run_list = row['run'].split('_')

        treat = run_list[0]
        iteration = run_list[1]
        if len(run_list) == 2:
            comb = 'combined'
            input_type = 'full'
        elif len(run_list) == 3:
            if run_list[2] == 'separate':
                comb = run_list[2]
                input_type = 'full'
            elif run_list[2] == 'hyp':
                comb = 'combined'
                input_type = run_list[2]
            else:
                raise KeyError(f'{len(run_list)} with index 2 {run_list[2]}')
        elif len(run_list) == 4:
            comb = run_list[2]
            input_type = run_list[3]
        else:
            raise KeyError(f'Run list has length {len(run_list)}')

        target_dir = os.path.join(pred_dir, treat2dir[treat], f'r{iteration}', comb, input_type)

        if os.path.isdir(target_dir):
            continue

        os.makedirs(target_dir, exist_ok=True)
        source_dir = os.path.join(exp_dir, row['run'], row['hyperparams'])
        copyfile(os.path.join(source_dir, 'val_preds.p'), os.path.join(target_dir, 'val_preds.p'))
        target_dirs.append(target_dir)

        # for iterative evals
        if input_type == 'full':
            target_dir = os.path.join(pred_dir, '4_iterevals', treat2dir[treat], f'r{iteration}', comb)
            os.makedirs(target_dir, exist_ok=True)
            source_dir = os.path.join(exp_dir, 'iterative_evals', row['run'])
            copyfile(os.path.join(source_dir, 'val_preds.p'), os.path.join(target_dir, 'val_preds.p'))
            target_dirs.append(target_dir)

    print(f'Complete\nCopied {len(target_dirs)} files')
    print('='*90)
    for target_dir in target_dirs:
        print(target_dir)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()

    parser.add_argument('--model', help='name of pretrained model', required=True)

    # Optional arguments
    parser.add_argument('--best_runs', help='file name of best runs', default='')
    parser.add_argument('--exp_dir', help='base dir of experiment runs', default='')

    args = parser.parse_args()

    move_best(args)
