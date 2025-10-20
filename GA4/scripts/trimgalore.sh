#!/bin/bash
#SBATCH --account=PAS2880
#SBATCH --cpus-per-task=8
#SBATCH --time=30
#SBATCH --output=slurm-tg-%j.out
#SBATCH --mail-type=FAIL
set -euo pipefail

# Constants
TRIMGALORE_CONTAINER=oras://community.wave.seqera.io/library/trim-galore:0.6.10--bc38c9238980c80e

# Copy the placeholder variables
R1="$1"
R2="$2"
outdir="$3"
nopath1=${R1##*/} 
nopath2=${R2##*/} 
sample1=${nopath1%R1.fastq.gz}
sample2=${nopath2%R2.fastq.gz}

# Report
echo "# Starting script trimgalore.sh"
date
echo "# Input R1 FASTQ file:      $R1"
echo "# Input R2 FASTQ file:      $R2"
echo "# Output dir:               $outdir"
echo


# Run TrimGalore
apptainer exec "$TRIMGALORE_CONTAINER" \
    trim_galore \
    --paired \
    --fastqc \
    --cores=8 \
    --nextseq 20 \
    --output_dir "$outdir" \
    "$R1" \
    "$R2"

# Report
echo
echo "# TrimGalore version:"
apptainer exec "$TRIMGALORE_CONTAINER" \
  trim_galore -v
echo "# Successfully finished script trimgalore.sh"
date


# Rename outputs
mv "$outdir/${sample1}R1_val_1.fq.gz" "$outdir/${sample1}R1_trimmed.fq.gz"
mv "$outdir/${sample2}R2_val_2.fq.gz" "$outdir/${sample2}R2_trimmed.fq.gz"

mv "$outdir/${sample1}R1_val_1_fastqc.html" "$outdir/${sample1}R1_trimmed.fastqc.html"
mv "$outdir/${sample2}R2_val_2_fastqc.html" "$outdir/${sample2}R2_trimmed.fastqc.html"

mv "$outdir/${sample1}R1_val_1_fastqc.zip" "$outdir/${sample1}R1_trimmed.fastqc.zip"
mv "$outdir/${sample2}R2_val_2_fastqc.zip" "$outdir/${sample2}R2_trimmed.fastqc.zip"