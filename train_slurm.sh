timestamp=`date +%Y-%m-%d-%H-%M-%S`
PROJ_ROOT=/private/home/strubell/research/coref
JOBSCRIPTS=scripts
mkdir -p ${JOBSCRIPTS}
queue=learnfair
SAVE_ROOT=$PROJ_ROOT/models
#mkdir -p stdout stderr
#for cname in train_spanbert_large_conll12 ;
#for cname in train_spanbert_base_conll12 \
#             train_spanbert_base_conll12_gold \
#             train_spanbert_large_conll12 \
#             train_spanbert_large_conll12_gold ;
for cname in train_spanbert_base_preco \
             train_spanbert_base_preco_gold \
             train_spanbert_large_preco \
             train_spanbert_large_preco_gold \
             train_spanbert_base_preco_mult \
             train_spanbert_base_preco_mult_gold \
             train_spanbert_large_preco_mult \
             train_spanbert_large_preco_mult_gold ;
do
    MEM="32g"
#    name=${cname#train_}
    SAVE="${SAVE_ROOT}/${cname}"
    mkdir -p ${SAVE}
    SCRIPT=${JOBSCRIPTS}/run.${cname}.sh
    SLURM=${JOBSCRIPTS}/run.${cname}.slrm
    echo "#!/bin/sh" > ${SCRIPT}
    echo "#!/bin/sh" > ${SLURM}
#    echo "source activate py36" >> ${SLURM}
    echo "#SBATCH --job-name=$cname" >> ${SLURM}
    echo "#SBATCH --output=$SAVE/$timestamp.out" >> ${SLURM}
    echo "#SBATCH --error=$SAVE/$timestamp.err" >> ${SLURM}
    echo "#SBATCH --signal=USR1@120" >> ${SLURM}
    echo "#SBATCH --partition=${queue}" >> ${SLURM}
  #    echo "#SBATCH --comment=ICRLDEADLINE" >> ${SLURM}
  #    echo "#SBATCH --nodes=${num_nodes}" >> ${SLURM}
  #    echo "#SBATCH --ntasks-per-node=8" >> ${SLURM}
    echo "#SBATCH --mem=$MEM" >> ${SLURM}
    echo "#SBATCH --gres=gpu:1" >> ${SLURM}
#    echo "#SBATCH --cpus-per-task 8" >> ${SLURM}
    echo "#SBATCH --time=72:00:00" >> ${SLURM}
    if [[ $cname =~ "large" ]]; then
        echo "#SBATCH --constraint=volta32gb" >> ${SLURM}
    fi
    echo "srun sh ${SCRIPT}" >> ${SLURM}
#    echo "source activate py36" >> ${SCRIPT}
    echo "echo \$SLURM_JOB_ID >> jobs" >> ${SCRIPT}
    echo "{ " >> ${SCRIPT}
    echo "echo $cname " >> ${SCRIPT}
    echo "cd $PROJ_ROOT" >> ${SCRIPT}
    echo "python3 -O train.py $cname" >> ${SCRIPT}
    echo "kill -9 \$\$" >> ${SCRIPT}
    echo "} & " >> ${SCRIPT}
    echo "child_pid=\$!" >> ${SCRIPT}
    echo "trap \"echo 'TERM Signal received';\" TERM" >> ${SCRIPT}
    echo "trap \"echo 'Signal received'; if [ \"\$SLURM_PROCID\" -eq \"0\" ]; then sbatch ${SLURM}; fi; kill -9 \$child_pid; \" USR1" >> ${SCRIPT}
    echo "while true; do     sleep 1; done" >> ${SCRIPT}
    echo "Created scripts: ${SLURM} ${SCRIPT}"
    echo "Writing output: $SAVE/$timestamp.out"
    sbatch ${SLURM}
done
