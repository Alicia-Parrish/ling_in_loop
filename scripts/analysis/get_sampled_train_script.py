import argparse
import pandas as pd
import os

def write_sampled_train_script(args):
    if args.model == '':
        args.model = os.path.basename(os.path.dirname(os.path.dirname(args.best_runs)))

    best_runs = pd.read_csv(args.best_runs, names=['run', 'params', 'acc'])
    write_runs = []

    added_runs = {}
    for idx, run_row in best_runs.iterrows():
        run_name, params = run_row['run'], run_row['params']
        treat, iteration = run_name.split('_')[0], int(run_name.split('_')[1])
        lr, bs = params.split('_')

        if iteration != args.round:
            continue

        run_dict = {'name': run_name, 'lr': lr, 'bs': bs, 'round': iteration}

        if treat in added_runs.keys():
            added_runs[treat].append(run_dict)
        else:
            added_runs[treat] = [run_dict]

    for treat, runs in added_runs.items():
        for run in runs:
            for split in args.splits.split(','):
                command = f'sh {args.train_shell} {run["name"]} {args.model} {args.round*int(args.size)} {args.sample}/{split} {run["lr"]} {run["bs"]}'

                write_runs.append(f'{command}\n')
                # write_runs.append(f'{command} true\n')

    out_name = os.path.join(args.out_dir, f'{args.model}_sampled_{args.sample}_{args.round}_run.sh')
    with open(out_name, 'w') as f:
        f.write(''.join(write_runs))

    print('='*90+'Complete'+'='*90)
    print(f"Written to\n{out_name}")


if __name__ == '__main__':
    parser = argparse.ArgumentParser()

    parser.add_argument('best_runs', help='path to best runs')

    # Optional arguments
    parser.add_argument('--sample', default='cross_eval')
    parser.add_argument('--splits', default='0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1.0')
    parser.add_argument('--size', default='2700')
    parser.add_argument('--round', help='upper limit of rounds to include', default=5, type=int)
    parser.add_argument('--model', help='name of model. if empty, inferred from best_runs', default='')
    parser.add_argument('--out_dir', help='where to write run script', default='.')
    parser.add_argument('--train_shell', help='name of eval shell script', default='train-models-sample.sh')

    args = parser.parse_args()

    write_sampled_train_script(args)
