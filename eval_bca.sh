#!/bin/bash

scorer_dir="reference-coreference-scorers"
bca_dir="/mnt/nfs/work1/mccallum/coref/bca-output"

model_output_dir="best_spanbert_pred_outputs"

current_bca_dir="$bca_dir/$model_output_dir"

key="$current_bca_dir/output.gold"

out_dir="bca_scores"
mkdir -p $out_dir

for metric in bcub ceafe muc lea; do
  for corrected_file in $(ls $current_bca_dir/output.corrected.*); do
    just_fname=${corrected_file##*/}
    perl $scorer_dir/scorer.pl $metric $key $corrected_file > $out_dir/$just_fname.eval.$metric
  done
done