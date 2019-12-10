#!/bin/bash

scorer_dir="reference-coreference-scorers"
bca_dir="/mnt/nfs/work1/mccallum/coref/bca-output"

model_output_dir="best_spanbert_pred_outputs"

current_bca_dir="$bca_dir/$model_output_dir"

key="$current_bca_dir/output.gold"

out_dir="bca_scores"
mkdir -p $out_dir

#for metric in bcub ceafe muc lea; do
#  for corrected_file in $(ls $current_bca_dir/output.corrected.*); do
#    echo $metric $corrected_file
#    just_fname=${corrected_file##*/}
#    perl $scorer_dir/scorer.pl $metric $key $corrected_file > $out_dir/$just_fname.eval.$metric
#  done
#done

mention_score_outfile=$out_dir/scores.mentions
echo -e "name\ttp\ttpfn\tr\ttp\ttpfn\tp\tf1\t"> $mention_score_outfile

for metric in bcub ceafe muc lea; do
  metric_score_outfile=$out_dir/scores.$metric
  echo -e "name\ttp\ttpfn\tr\ttp\ttpfn\tp\tf1\t"> $metric_score_outfile
done

for corrected_file in $(ls $current_bca_dir/output.corrected.*); do

  just_fname=${corrected_file##*/}
  scores=$(grep "Identification of Mentions: Recall:" $out_dir/$just_fname.eval.lea | \
           sed 's/[(%)]//g' | \
           awk '{print $5"\t"$7"\t"$8"\t"$10"\t"$12"\t"$13"\t"$15}')
  echo -e $just_fname"\t"$scores >> $mention_score_outfile

  for metric in bcub ceafe muc lea; do
      metric_score_outfile=$out_dir/scores.$metric
      scores=$(grep "Coreference: Recall:" $out_dir/$just_fname.eval.$metric | \
      sed 's/[(%)]//g' | \
      awk '{print $3"\t"$5"\t"$6"\t"$8"\t"$10"\t"$11"\t"$13}')
      echo -e $just_fname"\t"$scores >> $metric_score_outfile
    done
done