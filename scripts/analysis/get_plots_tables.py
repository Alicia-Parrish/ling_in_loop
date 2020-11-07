import argparse
import os
import re

import pandas as pd
import numpy as np

import matplotlib.pyplot as plt


def my_plot(table, plot_args, title, xlabel='iteration', ylabel='accuracy', ylim=[0, 1]):
    fig, ax = plt.subplots()
    lo = ax.plot(
        table.columns.values,
        table.transpose(),
        **plot_args
    )
    ax.legend(iter(lo), table.index.values, loc='best')

    ax.set_title(title)
    ax.set_xlabel(xlabel)
    ax.set_ylabel(ylabel)
    ax.set_ylim(*ylim)

    plt.tight_layout()
    plt.close()
    return fig


# for performance on validation sets
def get_config_table(sub_configs, args):
    sum_table = pd.DataFrame(
        index=sub_configs['treatment'].unique(),
        columns=sub_configs['round'].unique(),
    )

    for treatment in sum_table.index.values:
        for iteration in sum_table.columns.values:
            sum_table.loc[treatment, iteration] = sub_configs[
                (sub_configs['treatment'] == treatment) & (sub_configs['round'] == iteration)
                ]['acc'].item()
    return sum_table


def get_config_plot(table, title, plot_args, args):
    return my_plot(table, plot_args, title)


def summarize_configs(best_configs_fname, plot_args, args):
    cols = ['run_id', 'hyperparams', 'acc']
    best_configs = pd.read_csv(best_configs_fname, header=None, names=cols)
    tables, plots = {}, {}

    breakouts = {
        'treatment': [],
        'round': [],
        'modifier': [],
        'lr': [],
        'batch': [],
    }
    for idx, row in best_configs.iterrows():
        run_id = row['run_id'].split('_')
        lr, bs = row['hyperparams'].split('_')

        breakouts['treatment'].append(run_id[0])
        breakouts['round'].append(run_id[1])

        modifier = 'standard' if len(run_id) == 2 else run_id[2]
        breakouts['modifier'].append(modifier)

        breakouts['lr'].append(float(lr))
        breakouts['batch'].append(int(bs))

    for col, vals in breakouts.items():
        best_configs[col] = vals

    for mod in best_configs['modifier'].unique():
        sub_configs = best_configs.loc[best_configs['modifier'] == mod, :]
        tables[mod] = get_config_table(sub_configs, args)
        plots[mod] = get_config_plot(tables[mod], mod, plot_args, args)

    return {
               'tables': tables,
               'plots': plots
           }, best_configs['round'].max()


def get_dir_names(files_dir):
    dir_list = []
    for root, dirs, files in os.walk(files_dir):
        for dir in dirs:
            dir_list.append(dir)
        break
    return dir_list


def load_itereval_acc(base_dir):
    summary_files = ['glue_summary.csv', 'hans_summary.csv']

    result = None
    for file in summary_files:
        df = pd.read_csv(os.path.join(base_dir, file), header=0, index_col=0)
        df['dataset'] = file.split('_')[0]

        if result is None:
            result = df
        else:
            result = result.append(df)

    return result.reset_index(drop=True, )


# for iterative validations
def get_itereval_tables(base_dir, treatments, rounds, dir2plot, args):
    tables = {'full': None, 'breakdown': {}}
    for treatment in treatments:
        treat_dir = os.path.join(base_dir, treatment)
        treatment_table = None

        for iteration in rounds:
            iter_dir = os.path.join(treat_dir, iteration)

            temp_acc = load_itereval_acc(iter_dir)
            temp_acc['round'] = 1

            if treatment_table is None:
                treatment_table = temp_acc
            else:
                treatment_table = treatment_table.append(temp_acc)
        treatment_table.reset_index(drop=True, inplace=True)
        treatment_table['treatment'] = dir2plot[treatment]

        if tables['full'] is None:
            tables['full'] = treatment_table
        else:
            tables['full'] = tables['full'].append(treatment_table)
    tables['full'].reset_index(drop=True, inplace=True)

    for dataset in tables['full']['dataset'].unique():
        sub_table1 = tables['full'].loc[tables['full']['dataset'] == dataset, :]

        for case in sub_table1['case'].unique():
            sub_table2 = sub_table1.loc[sub_table1['case'] == case, :]

            for subcase in sub_table2['subcase'].unique():
                sub_table3 = sub_table2.loc[sub_table2['subcase'] == subcase, :]

                for label in sub_table3['label'].unique():
                    sub_table4 = sub_table3.loc[sub_table3['label'] == label, :]
                    summary = pd.DataFrame(
                        index=sub_table4['treatment'].unique(),
                        columns=np.sort(sub_table4['round'].unique())
                    )

                    for t in summary.index.values:
                        for r in summary.columns.values:
                            summary.loc[t, r] = sub_table4[
                                (sub_table4['treatment'] == t) & (sub_table4['round'] == r)
                                ]['acc'].item()

                    tables['breakdown'][(
                        dataset,
                        case,
                        subcase,
                        label
                    )] = summary

    return tables


def get_itereval_plots(tables, dir2plot, plot_args, args):
    plots = {}

    for key, table in tables.items():
        title = '-'.join(key)
        plots[key] = my_plot(table, plot_args, title)

    return plots


def summarize_iterevals(base_dir, plot_args, args):
    treatments = get_dir_names(base_dir)
    rounds = get_dir_names(os.path.join(base_dir, treatments[0]))

    dir2plot = {
        '1_Baseline_protocol': 'baseline',
        '2_Ling_on_side_protocol': 'LotS',
        '3_Ling_in_loop_protocol': 'LitL',
    }

    tables = get_itereval_tables(base_dir, treatments, rounds, dir2plot, args)
    plots = get_itereval_plots(tables['breakdown'], dir2plot, plot_args, args)

    return {
        'tables': tables,
        'plots': plots
    }


def save_summaries(summary_dict, out_dir, plot_type, save_plots, summary_type):
    plots = summary_dict['plots']

    if summary_type == 'configs':
        tables = summary_dict['tables']
    elif summary_type == 'iterevals':
        tables = summary_dict['tables']['breakdown']
    else:
        raise KeyError(f'{summary_type}')

    table_dir = os.path.join(out_dir, 'tables')
    os.makedirs(table_dir, exist_ok=True)
    plots_dir = os.path.join(out_dir, 'plots')
    os.makedirs(plots_dir, exist_ok=True)


    rep = {
        '/': '-',
        ';': '--',
    }

    for (key, table), plot in zip(tables.items(), plots.values()):
        fname_key = summary_type
        if summary_type == 'configs':
            fname_key = summary_type + '.' + key
        elif summary_type == 'iterevals':
            fname_key = summary_type + '.' + '.'.join(key)

        for old_char, new_char in rep.items():
            fname_key = fname_key.replace(old_char, new_char)

        table_name = os.path.join(table_dir, f'{fname_key}.csv')
        plot_name = os.path.join(plots_dir, f'{fname_key}.{plot_type}')

        table.to_csv(table_name)
        if save_plots:
            plot.savefig(plot_name)


def summarize(args):
    plot_args = {
        'linestyle': args.ls,
        'marker': args.marker,
    }

    best_configs, iteration = summarize_configs(args.best_config, plot_args, args)
    iterevals = summarize_iterevals(args.itereval_base, plot_args, args)

    print(len(list(iterevals['tables']['breakdown'].keys())))

    out_dir = os.path.join(args.out_base, f'r{iteration}')
    os.makedirs(out_dir, exist_ok=True)

    save_summaries(best_configs, out_dir, args.plot_type, args.save_plots, summary_type='configs')
    save_summaries(iterevals, out_dir, args.plot_type, args.save_plots, summary_type='iterevals')

    return out_dir


if __name__ == '__main__':
    parser = argparse.ArgumentParser()

    repo = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath('__file__'))))
    pred = os.path.join(repo, 'predictions')

    parser.add_argument('--itereval_base',
                        help='base directory of iterative evaluations',
                        default=os.path.join(pred, '4_iterevals'))
    parser.add_argument('--best_config',
                        help='best configuration summary file',
                        default=os.path.join(pred, 'best_configs', 'best_configs.csv'))
    parser.add_argument('--out_base', help='base directory for results', default=os.path.join(repo, 'eval_summary'))
    parser.add_argument('--verbose', help='whether to print statements', action='store_true')

    # plot arguments
    parser.add_argument('--save_plots', help='whether to save plots', action='store_true')
    parser.add_argument('--ls', help='line shape for plots', default='-')
    parser.add_argument('--marker', help='marker for plots', default='o')
    parser.add_argument('--plot_type', help='file type for plots', default='jpg')

    args = parser.parse_args()

    out_dir = summarize(args)

    if args.verbose:
        print(f'Saved summaries in\n{out_dir}')
