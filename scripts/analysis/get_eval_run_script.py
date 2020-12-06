import argparse
import pandas as pd
import os

def write_eval_run_script(args):
    if args.model == '':
        args.model = os.path.basename(os.path.dirname(os.path.dirname(args.best_runs)))

    best_runs = pd.read_csv(args.best_runs, names=['run', 'params', 'acc'])
    write_runs = []

    added_runs = {}
    for idx, run_row in best_runs.iterrows():
        run_name, params = run_row['run'], run_row['params']
        treat, iteration = run_name.split('_')[0], int(run_name.split('_')[1])
        lr, bs = params.split('_')

        if args.round_only > 0 and iteration != args.round_only:
            continue
        elif iteration > args.round_lim or run_name.split('_')[-1] == 'hyp':
            continue

        run_dict = {'name': run_name, 'lr': lr, 'bs': bs, 'round': iteration}

        if treat in added_runs.keys():
            added_runs[treat].append(run_dict)
        else:
            added_runs[treat] = [run_dict]

    for treat, runs in added_runs.items():
        for run in runs:

            if args.sampled:
                for partition in args.partitions.split(','):
                    for eval_pre in args.eval_pres.split(','):
                        write_runs.append(
                            f'sh {args.sample_shell} {run["name"]} {run["lr"]} {run["bs"]} {args.model} {args.sample_name}/{partition} {eval_pre}\n'
                        )
            else:
                write_runs.append(
                    f'sh {args.eval_shell} {run["name"]} {run["lr"]} {run["bs"]} {args.model}\n'
                )

                if not args.no_cross:
                    for val_treat in added_runs.keys():
                        if treat == val_treat:
                            continue

                        write_runs.append(
                            f'sh {args.cross_shell} {run["name"]} {val_treat}_{run["round"]} {run["lr"]} {run["bs"]} {args.model}\n'
                        )

    if args.sampled:
        args.mod = f'_{args.sample_name}'

    with open(os.path.join(args.out_dir, f'{args.model}{args.mod}_run.sh'), 'w') as f:
        f.write(''.join(write_runs))

    print('='*90+'Complete'+'='*90)
    print(f"Written to\n{os.path.join(args.out_dir, f'{args.model}_run.sh')}")


if __name__ == '__main__':
    parser = argparse.ArgumentParser()

    parser.add_argument('best_runs', help='path to best runs')

    # Optional arguments
    parser.add_argument('--model', help='name of model. if empty, inferred from best_runs', default='')
    parser.add_argument('--round_lim', help='upper limit of rounds to include', default=5, type=int)
    parser.add_argument('--out_dir', help='where to write run script', default='.')
    parser.add_argument('--eval_shell', help='name of eval shell script', default='eval-models.sh')
    parser.add_argument('--cross_shell', help='name of cross eval script', default='cross-eval-models.sh')
    parser.add_argument('--no_cross', help='whether not to do cross eval', action='store_true')
    parser.add_argument('--mod', default='')

    # For sampled
    parser.add_argument('--sampled', action='store_true')
    parser.add_argument('--sample_name', default='cross_eval')
    parser.add_argument('--partitions', default='0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1.0')
    parser.add_argument('--eval_pres', default='eval,mnlieval')
    parser.add_argument('--sample_shell', default='eval-models-sampled.sh')
    parser.add_argument('--round_only', default=-1, type=int)

    args = parser.parse_args()

    write_eval_run_script(args)
