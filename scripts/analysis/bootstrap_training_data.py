import os
import argparse
import json
import pandas as pd
import numpy as np
import shutil


def read_examples(fname):
    with open(fname, 'r') as f:
        return [json.loads(ex) for ex in f]


def get_files_by_type(fdir, ftype='.jsonl', start='train'):
    all_files = next(os.walk(fdir))[2]

    return [file for file in all_files if file.endswith(ftype) and file.startswith(start)]


def write_jsonl(df, fname):
    with open(fname, 'w') as f:
        for idx, row in df.iterrows():
            f.write(f'{json.dumps(row.to_dict())}\n')


def parse_fname(file, split_by='_'):
    fname = file.split('.')[0]
    fname_list = fname.split(split_by)

    iteration = fname_list[1][-1]
    comb = '_separate' if len(fname_list) == 3 else ''

    return iteration, comb, fname


def cross_val(df, leave_p=0.1, sort_by='AnonId'):
    rows, cols = df.shape

    if sort_by is None:
        df_sorted = df
    else:
        df_sorted = df.sort_values(sort_by, ignore_index=True)

    sampled = []
    step = int(leave_p * rows)
    prev = 0
    stop = rows + step if rows % step == 0 else rows
    for split in np.arange(step, stop, step):
        sampled.append(pd.concat([
            df_sorted.iloc[:prev, :],
            df_sorted.iloc[split:, :]
        ]))

        prev = split
    return sampled

def boostrap_training_data(args):
    overwrite = True
    leave_p = 0.1
    sort_by = 'AnonId'
    repo = args.repo
    data = os.path.join(repo, 'NLI_data')
    out_base = os.path.join(repo, 'tasks', 'data')
    treats = {
        '1_Baseline_protocol': 'baseline',
        '2_Ling_on_side_protocol': 'LotS',
        '3_Ling_in_loop_protocol': 'LitL',
    }

    for treat_in, treat_out in treats.items():
        treat_dir = os.path.join(data, treat_in)
        files = get_files_by_type(treat_dir)

        for file in files:
            iteration, comb, fname = parse_fname(file)

            run_dir = os.path.join(out_base, f'{treat_out}_{iteration}{comb}')
            cross_dir = os.path.join(run_dir, 'cross_eval')
            if overwrite and os.path.exists(cross_dir):
                shutil.rmtree(cross_dir)

            samples = cross_val(
                pd.DataFrame(read_examples(os.path.join(treat_dir, file))),
                leave_p=leave_p,
                sort_by=sort_by,
                iteration=iteration
            )

            for idx, sample in enumerate(samples):
                out_dir = os.path.join(cross_dir, f'{(idx + 1) * leave_p:.1f}')
                os.makedirs(out_dir, exist_ok=True)

                write_jsonl(sample, os.path.join(out_dir, file))

if __name__ == '__main__':
    parser = argparse.ArgumentParser()

    # Required arguments
    parser.add_argument('--repo', help='repo directory', required=True)

    args = parser.parse_args()

    boostrap_training_data(args)
