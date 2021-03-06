timestamp=`date +%Y-%m-%d-%H-%M-%S`
PROJ_ROOT=/private/home/strubell/research/coref
JOBSCRIPTS=scripts
mkdir -p ${JOBSCRIPTS}
queue=dev
#queue=learnfair
SAVE_ROOT=$PROJ_ROOT/models
PRED_ROOT=$PROJ_ROOT/predictions/mentions-$timestamp
mkdir -p $PRED_ROOT
#mkdir -p $SAVE_ROOT

# write current model performance to file in predictions dir
# shellcheck disable=SC2045
#for d in $(ls $SAVE_ROOT); do
#  dir="$SAVE_ROOT/$d/stdout.log";
#  echo "$dir $(grep evaL $dir | tail -1 | awk '{print $10}')";
#done > $PRED_ROOT/model_f1s.txt

#mkdir -p stdout stderr
#for cname in train_spanbert_large_conll12 ;
for cname in train_spanbert_base_conll12 \
             train_spanbert_large_conll12 \
             train_bert_base_conll12 \
             train_bert_large_conll12 ;
#for cname in train_spanbert_base_preco \
#             train_spanbert_base_preco_gold \
#             train_spanbert_large_preco \
#             train_spanbert_large_preco_gold \
#             train_spanbert_base_preco_mult \
#             train_spanbert_base_preco_mult_gold \
#             train_spanbert_large_preco_mult \
#             train_spanbert_large_preco_mult_gold ;
do
  for top_span_ratio in 0.4 0.8 2.0; do
    MEM="32g"
    SAVE="${SAVE_ROOT}/${cname}"
    mkdir -p ${SAVE}
    SCRIPT="${JOBSCRIPTS}/mentions-eval-${top_span_ratio}.${cname}.sh"
    SLURM="${JOBSCRIPTS}/mentions-eval-${top_span_ratio}.${cname}.slrm"
    output_prefix="$SAVE/mentions-eval-${top_span_ratio}-$timestamp"
    echo "#!/bin/sh" > ${SCRIPT}
    echo "#!/bin/sh" > ${SLURM}
#    echo "source activate py36" >> ${SLURM}
    echo "#SBATCH --job-name=eval-$cname" >> ${SLURM}
    echo "#SBATCH --output=$output_prefix.out" >> ${SLURM}
    echo "#SBATCH --error=$output_prefix.err" >> ${SLURM}
    echo "#SBATCH --signal=USR1@120" >> ${SLURM}
    echo "#SBATCH --partition=${queue}" >> ${SLURM}
  #    echo "#SBATCH --comment=ICRLDEADLINE" >> ${SLURM}
  #    echo "#SBATCH --nodes=${num_nodes}" >> ${SLURM}
  #    echo "#SBATCH --ntasks-per-node=8" >> ${SLURM}
    echo "#SBATCH --mem=$MEM" >> ${SLURM}
    echo "#SBATCH --gres=gpu:1" >> ${SLURM}
#    echo "#SBATCH --cpus-per-task 8" >> ${SLURM}
    echo "#SBATCH --time=72:00:00" >> ${SLURM}

    # this is the correct file for bert_large and spanbert_base
    dev_file=/private/home/strubell/research/data/spanbert_data_clean/dev.english.384.jsonlines

    if [[ $cname =~ "large" ]]; then
      if [[ $cname =~ "_spanbert_" ]]; then
        # spanbert_large
        dev_file=/private/home/strubell/research/data/spanbert_data_clean/dev.english.512.jsonlines
      fi
    else
      if [[ $cname =~ "_bert_" ]]; then
        # bert_base
        dev_file=/private/home/strubell/research/data/spanbert_data_clean/dev.english.128.jsonlines
      fi
    fi

    out_file="$PRED_ROOT/detected-mentions_${cname}_$top_span_ratio.jsonl"

    if [[ $cname =~ "large" ]]; then
        echo "#SBATCH --constraint=volta32gb" >> ${SLURM}
    fi
    echo "srun sh ${SCRIPT}" >> ${SLURM}
#      echo "cp ${SAVE}/preds.conll $PRED_ROOT/preds-$cname.conll" >> ${SLURM}

#    echo "source activate py36" >> ${SCRIPT}
    echo "echo \$SLURM_JOB_ID >> jobs" >> ${SCRIPT}
    echo "{ " >> ${SCRIPT}
    echo "echo $cname " >> ${SCRIPT}
    echo "cd $PROJ_ROOT" >> ${SCRIPT}
    # mentions_and_scores.py models/train_spanbert_base_conll12 ~/research/spanbert_data_clean/dev.english.384.jsonlines 0.8 detected-mentions_spanbert-base_conll-dev_0-8.jsonl
    echo "python3 -O mentions_and_scores.py $cname $dev_file $top_span_ratio $out_file" >> ${SCRIPT}
    echo "kill -9 \$\$" >> ${SCRIPT}
    echo "} & " >> ${SCRIPT}
    echo "child_pid=\$!" >> ${SCRIPT}
    echo "trap \"echo 'TERM Signal received';\" TERM" >> ${SCRIPT}
    echo "trap \"echo 'Signal received'; if [ \"\$SLURM_PROCID\" -eq \"0\" ]; then sbatch ${SLURM}; fi; kill -9 \$child_pid; \" USR1" >> ${SCRIPT}
    echo "while true; do     sleep 1; done" >> ${SCRIPT}
    echo "Created scripts: ${SLURM} ${SCRIPT}"
    echo "Writing output: $output_prefix.out"
    sbatch ${SLURM}
  done
done
