timestamp=`date +%Y-%m-%d-%H-%M-%S`
PROJ_ROOT=/private/home/strubell/research/coref
JOBSCRIPTS=scripts
mkdir -p ${JOBSCRIPTS}
queue=dev
#queue=learnfair
SAVE_ROOT=$PROJ_ROOT/models
PRED_ROOT=$PROJ_ROOT/predictions/bronze-$timestamp
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
  for exp in bronze_highp bronze_highr; do
    MEM="32g"
    SAVE="${SAVE_ROOT}/${cname}"
    mkdir -p ${SAVE}
    SCRIPT="${JOBSCRIPTS}/mentions-eval-${exp}.${cname}.sh"
    SLURM="${JOBSCRIPTS}/mentions-eval-${exp}.${cname}.slrm"
    output_prefix="$SAVE/mentions-eval-${exp}-$timestamp"
    echo "#!/bin/sh" > ${SCRIPT}
    echo "#!/bin/sh" > ${SLURM}
    echo "#SBATCH --job-name=eval-$cname-$exp" >> ${SLURM}
    echo "#SBATCH --output=$output_prefix.out" >> ${SLURM}
    echo "#SBATCH --error=$output_prefix.err" >> ${SLURM}
    echo "#SBATCH --signal=USR1@120" >> ${SLURM}
    echo "#SBATCH --partition=${queue}" >> ${SLURM}
    echo "#SBATCH --mem=$MEM" >> ${SLURM}
    echo "#SBATCH --gres=gpu:1" >> ${SLURM}
    echo "#SBATCH --time=72:00:00" >> ${SLURM}

    experiments_file="$exp.experiments.conf"

    if [[ $cname =~ "large" ]]; then
        echo "#SBATCH --constraint=volta32gb" >> ${SLURM}
    fi
    echo "srun sh ${SCRIPT}" >> ${SLURM}

    echo "echo \$SLURM_JOB_ID >> jobs" >> ${SCRIPT}
    echo "{ " >> ${SCRIPT}
    echo "echo $cname " >> ${SCRIPT}
    echo "cd $PROJ_ROOT" >> ${SCRIPT}
    echo "python3 -O evaluate.py $cname $experiments_file" >> ${SCRIPT}
    echo "cp ${SAVE}/preds.conll $PRED_ROOT/preds-$cname-$exp.conll" >> ${SCRIPT}
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
