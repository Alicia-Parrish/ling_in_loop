import argparse
import pandas as pd
import os
import json
import csv


def get_best(args):
    dirs = []
    for (dirpath, dirnames, filenames) in os.walk(args.exp_dir):
        dirs.extend(dirnames)
        break

    metrics = {}
    for dir in dirs:
        with open(os.path.join(args.exp_dir, dir, args.metrics_fname), 'r') as f:
            metrics[dir] = json.load(f)[args.metrics_key]

    metrics_s = pd.Series(metrics)

    if args.best_config_dir == '':
        repo = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath('__file__'))))
        best_config_dir = os.path.join(repo, 'best_configs')

    os.makedirs(best_config_dir, exist_ok=True)
    with open(os.path.join(best_config_dir, 'best_configs.csv'), 'a', newline='') as f:
        write = csv.writer(f)
        write.writerow([os.path.basename(args.exp_dir), metrics_s.idxmax(), metrics_s.max()])
    print(f'Complete\nSaved at {best_config_dir}')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()

    # Required arguments
    parser.add_argument('--exp_dir', help='directory for runs to compare', required=True)

    # Optional arguments
    parser.add_argument('--metrics_fname', help='file name of metrics', default='val_metrics.json')
    parser.add_argument('--metrics_key', help='key to get metric', default='aggregated')
    parser.add_argument('--best_config_dir', help='file name of best config', default = '')

    args = parser.parse_args()

    get_best(args)
