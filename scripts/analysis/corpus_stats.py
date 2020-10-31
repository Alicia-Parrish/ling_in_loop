import argparse
import pandas as pd
import os
import json
import re
import string
import numpy as np

def normalize_text(s):
    """Lower text and remove punctuation, articles and extra whitespace."""
    def remove_articles(text):
        regex = re.compile(r'\b(a|an|the)\b', re.UNICODE)
        return re.sub(regex, ' ', text)
    def white_space_fix(text):
        return ' '.join(text.split())
    def remove_punc(text):
        exclude = set(string.punctuation)
        return ''.join(ch for ch in text if ch not in exclude)
    def lower(text):
        return text.lower()
    return white_space_fix(remove_articles(remove_punc(lower(s))))


def get_tokens(s):
    if not s: return []
    return normalize_text(s).split()


def get_ex_tokens(ex, hyp_only=True):
    if hyp_only:
        return get_tokens(ex['hypothesis'])
    else:
        return get_tokens(ex['premise'] + ' ' + ex['hypothesis'])


def get_pmi(exs, smooth, alpha, weight):
    total_docs = len(exs)

    counts_by_label = {
        'entailment': {'count': 0., 'word_count': {}},
        'neutral': {'count': 0., 'word_count': {}},
        'contradiction': {'count': 0., 'word_count': {}},
    }

    word_counts = {}

    for ex in exs:
        toks = get_ex_tokens(ex, hyp_only=False)
        counts_by_label[ex['label']]['count'] += 1
        counter = counts_by_label[ex['label']]['word_count']

        for tok in set(toks):
            if counter.get(tok, False):
                counter[tok] += 1
            else:
                counter[tok] = 1.

            if word_counts.get(tok, False):
                word_counts[tok] += 1
            else:
                word_counts[tok] = 1.

    count_stats = {label: {} for label in counts_by_label.keys()}
    vocab_size = len(list(word_counts.keys()))
    for label, count_dict in counts_by_label.items():
        label_count = count_dict['count']
        for word, word_count in word_counts.items():
            count_w_c = counts_by_label[label]['word_count'].get(word, 0.)

            if weight:
                w_pmi = np.log(count_w_c*(total_docs**alpha)/(word_count**alpha)/label_count)
            else:
                w_pmi = np.log((count_w_c+smooth)*(total_docs+smooth*vocab_size*3)/(word_count+smooth*3)/(label_count+smooth*vocab_size))

            count_stats[label][word] = {
                'pmi': w_pmi,
                'pcent': count_w_c/label_count,
            }

    pmi_stats = {
        label: pd.DataFrame.from_dict(count_stats[label], orient='index').sort_values(by='pmi', ascending=False)
        for label in count_stats.keys()
    }

    return pmi_stats


def get_hyp_lengths(exs):
    hyp_lengths = {
        'entailment': [],
        'neutral': [],
        'contradiction': [],
    }

    for ex in exs:
        toks = get_ex_tokens(ex)
        hyp_lengths[ex['label']].append(len(toks))

    hyp_stats = {label: {} for label in hyp_lengths.keys()}

    for label, lengths in hyp_lengths.items():
        l_series = pd.Series(lengths)
        hyp_stats[label]['mean'] = l_series.mean()
        hyp_stats[label]['median'] = l_series.median()
        hyp_stats[label]['std'] = l_series.std()
        hyp_stats[label]['25ptile'] = l_series.quantile(q=0.25)
        hyp_stats[label]['75ptile'] = l_series.quantile(q=0.75)
        hyp_stats[label]['min'] = l_series.min()
        hyp_stats[label]['max'] = l_series.max()

    return hyp_lengths, hyp_stats


def get_stats(args):
    with open(args.fname, 'r') as f:
        ex = [json.loads(line) for line in f]

    if args.out_dir == '':
        repo = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath('__file__'))))
        stats = os.path.join(repo, 'stats')
        task_name = os.path.basename(os.path.dirname(args.fname))

        args.out_dir = os.path.join(stats, task_name)
    os.makedirs(args.out_dir, exist_ok=True)

    pmis = get_pmi(ex, args.smooth, args.alpha, args.weight)
    hyp_lengths, hyp_stats = get_hyp_lengths(ex)

    pd.DataFrame(hyp_stats).to_csv(os.path.join(args.out_dir, 'hyp_length_stats.csv'))

    for (label, pmi), hyp_length in zip(pmis.items(), hyp_lengths.values()):
        pmi.to_csv(os.path.join(args.out_dir, f'pmi_{label}.csv'))
        pd.Series(hyp_length).to_csv(os.path.join(args.out_dir, f'hyp_lenghts_{label}.csv'))

    print("="*45 + f' Complete: {args.out_dir} ' + "="*45)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()

    # Required arguments
    parser.add_argument('--fname', help='absolute path to file to analyze', required=True)

    # Optional arguments(
    parser.add_argument('--smooth', help='amount to smooth pmi', default=100)
    parser.add_argument('--alpha', help='weighting for rare words', default=0.75)
    parser.add_argument('--weight', help='whether to smooth by adding or weighting', action='store_true')
    parser.add_argument('--out_dir', help='where to output summary stats', default='')

    args = parser.parse_args()

    get_stats(args)
