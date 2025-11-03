Part B: A TrimGalore batch job
You’ll start with the TrimGalore script you just created, which should be much like that from last week’s exercises. But this time, instead of running the TrimGalore script “directly” with bash, you will submit it as a batch job. Then, in the next section, you will submit many batch jobs at the same time: one for each sample.
### **6. Add Sbatch options to the top of the TrimGalore shell script to specify:**
**1. The account/project you want to use**

**2. The number of cores you want to reserve: use 8**

**3. The amount of time you want to reserve: use 30 minutes**

**4. The desired file name of Slurm log file**

**5. That Slurm should email you upon job failure**

**Optional: you can try other Sbatch options you’d like to test**

Input into trimgalore.sh: 
```bash 
#SBATCH --account=PAS2880
#SBATCH --cpus-per-task=8
#SBATCH --time=30
#SBATCH --output=slurm-tg-%j.out
#SBATCH --mail-type=FAIL
#SBATCH --cpus-per-task=8
```
---
### **7. By printing and scanning through the TrimGalore help info once again (see last week’s exercises), find the TrimGalore option that specifies how many cores it can use – add the relevant line(s) from the TrimGalore help info to your README.md. In the script, change the trim_galore command accordingly to use the available number of cores.**

input: 
```bash 
TG=oras://community.wave.seqera.io/library/trim-galore:0.6.10--bc38c9238980c80e
apptainer exec $TG trim_galore --help

```
Output: 
```bash 
-j/--cores      ...
It seems that --cores 4 could be a sweet spot, anything above has diminishing returns
```

So I added `#SBATCH --cpus-per-task=8` to the header and `--cores 8` under `# Run TrimGalore`.

---
### **8. To test the script and batch job submission, submit the script as a batch job only for sample ERR10802863.**

Input:
```bash 
sbatch scripts/trimgalore.sh data/ERR10802863_R1.fastq.gz data/ERR10802863_R2.fastq.gz results/trimgalore 
```
---
### **9. Monitor the job, and when it’s done, check that everything went well (if it didn’t, redo until you get it right). In your README.md, explain your monitoring and checking process. Then, remove all outputs (Slurm log files and TrimGalore output files) produced by this test-run.**

I checked the status of the program with
```bash 
squeue -u $USER -l
``` 
and got the output: 
```bash 
Thu Oct 16 17:09:13 2025
             JOBID PARTITION     NAME     USER    STATE       TIME TIME_LIMI  NODES NODELIST(REASON)
          37841627 cpu,cpu-e trimgalo bateman1  PENDING       0:00     30:00      1 (Reservation)
          37840730   cpu-exp ondemand bateman1  RUNNING    1:57:42   2:00:00      1 p0832
```
I had to refresh the page once the job was gone from the squeue to see the slurm file and the output files in results/trimgalore, meaning the job was successful.

---
### **10. Illumina sequencing uses colors to distinguish between nucleotides as they are being added during the sequencing-by-synthesis process. However, newer Illumina machines (Nextseq and Novaseq) use a different color chemistry than older ones, and this newer chemistry suffers from an artefact that can erroneously produce strings of Gs (“poly-G”) with high quality scores. Those Gs should really be Ns instead, and occur especially at the end of reverse (R2) reads.** 
In the FastQC outputs for the R2 file that you just produced with TrimGalore (recall that it runs FastQC after trimmming!), do you see any evidence for this problem? Explain.


I downloaded the R1 and R2 fastq.gz and found in R2 the file:  


**Overrepresented sequences**

Sequence	Count	Percentage	Possible Source

GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG	1140	0.24461157184392066	No Hit" 


In addition, there is an increase in the GC content of the R2 at the end of the "Per sequence GC content" chart, where the number of reads with the GC content of 99 to 100 spikes when it should be close to or at zero, indicative of a poly-G artifact. 

-----
### **11. We’ll assume that the data was indeed produced with the newer Illumina color chemistry. In the TrimGalore help info, find the relevant TrimGalore option to deal with the poly-G probelm, and again add the relevant line(s) from the help info to your README.md. Then, use the TrimGalore option you found, but don’t change the quality score threshold from the default.**

This was really difficult and I did end up having to look it up. I used the `--nextseq 20` command in my script: 
```bash
--2colour/--nextseq INT  This enables the option '--nextseq-trim=3'CUTOFF' within Cutadapt, which will set a quality
 cutoff (that is normally given with -q instead), but qualities of G bases are ignored. This trimming is in common for the NextSeq- and NovaSeq-platforms, where basecalls without any signal are called as high-quality G bases. This is mutually exlusive with '-q INT'.
```
I tried using this command as it said that the qualities of G bases are ignored, its common with NextSeq and Noaseq platforms where basecalls without signal (our poly-G tails that should be Ns) are called high-quality G bases. However, even I tried to use the command, it wouldn't work without using a number after it (INT) and I got the error: 

```bash 
Value "--output_dir" invalid for option nextseq (number expected)
```
This is where I had to look up which number to use, and could that I should use `20` because it matches the trimgalore's quality trim threshold default, which is the standard balance between keeping read length and dropping noisy 3' tails.

-----
### **12. Rerun TrimGalore with the added color-chemistry option. Check all outputs and confirm that usage of this option made a difference. Then, remove all outputs produced by this test-run again.**

The file worked as expected, and when I viewed the file after downloading, the "Overrepresented sequences" `!` marker was gone and the spike in the "Per sequence GC content" graph was also gone. 

----
## **Bonus: Modify the script to rename the output FASTQ files**
### The TrimGalore output FASTQ files are oddly named, ending in _R1_val_1.fq.gz and _R2_val_2.fq.gz – check the output files from your initial run to see this. This is not necessarily a problem, but could trip you up in a next step with these files. Therefore, modify your TrimGalore script to rename the output files after running TrimGalore, giving them the same names as the input files. Then, rerun the script to check that your changes were successful.


I input the variables: 
```bash
nopath1=${R1##*/} 
nopath2=${R2##*/} 
sample1=${nopath1%R1.fastq.gz}
sample2=${nopath2%R2.fastq.gz}
```
What this is doing is stripping the file name (data/ERR108028##.fastq.gz) down to ERR108028##_ for both the R1 and R2 files. The `nopath` variables are removing the data/ path. I had to look this up because I kept getting an error because of the `data/` path in front of the file. `R1##*/` is saying to remove everything up to *and* including the last `/` in R1 (data/ERR108028##.fastq.gz -> ERR108028##.fastq.gz). I could have also used `R1#*/` in this case, which only removes the first `/` present, and would have worked because we only have one `/` in our file name. If I were to use a file that had a path with two slashed (ex: data/fastq/ERR108028##.fastq.gz) `R1#*/` would not work, so `R1##*/` is more veritile. 

After removing the path from both the R1 and R2, I removed the`R1.fastq.gz` with `%` to get ERR108028##. 
I then used the stripped name to apply the mv function to chanege the name of the file from results/trimgalore/ERR108028##_R1_val_1.fq.gz to results/trimgalore/ERR108028##_R1_trimmed.fq.gz, repeating with the R2 and other files produced. 
And the `mv` commands to rename:

```bash 
# Rename outputs
mv "$outdir/${sample1}R1_val_1.fq.gz" "$outdir/${sample1}R1_trimmed.fq.gz"
mv "$outdir/${sample2}R2_val_2.fq.gz" "$outdir/${sample2}R2_trimmed.fq.gz"

mv "$outdir/${sample1}R1_val_1_fastqc.html" "$outdir/${sample1}R1_trimmed.fastqc.html"
mv "$outdir/${sample2}R2_val_2_fastqc.html" "$outdir/${sample2}R2_trimmed.fastqc.html"

mv "$outdir/${sample1}R1_val_1_fastqc.zip" "$outdir/${sample1}R1_trimmed.fastqc.zip"
mv "$outdir/${sample2}R2_val_2_fastqc.zip" "$outdir/${sample2}R2_trimmed.fastqc.zip"
```
After testing the script with:
```bash 
for R1 in data/ERR10802866_R1.fastq.gz; do     R2=${R1/_R1/_R2};     sbatch scripts/trimgalore.sh "$R1" "$R2" results/trimgalore; done
``` 
All of the files came out with the correct names.

----
### **13. Write a for loop in your README.md to submit a TrimGalore batch job for each pair of FASTQ files that you have in your data dir.**

Input: 
``` bash 
for R1 in data/ERR*_R1.fastq.gz; do
    R2=${R1/_R1/_R2}
    sbatch scripts/trimgalore.sh "$R1" "$R2" results/trimgalore
done
```
And got: 
```bash 
Submitted batch job 37901900
Submitted batch job 37901901
Submitted batch job 37901902
Submitted batch job 37901903
Submitted batch job 37901904
Submitted batch job 37901905
Submitted batch job 37901906
Submitted batch job 37901907
Submitted batch job 37901908
Submitted batch job 37901909
Submitted batch job 37901910
Submitted batch job 37901911
Submitted batch job 37901912
Submitted batch job 37901913
Submitted batch job 37901914
Submitted batch job 37901915
Submitted batch job 37901916
Submitted batch job 37901917
Submitted batch job 37901918
Submitted batch job 37901919
Submitted batch job 37901920
Submitted batch job 37901921
```
### **14. Monitor the batch jobs and when they are done, check that everything went well (if it didn’t, redo until you get it right). In your README.md, explain your monitoring and checking process. In this case, it is appropriate to keep the Slurm log files: move them into a dir logs within the TrimGalore output dir.**

To check it I used: 

`squeue -u $USER -l` to see the submitted jobs and which jobs were left, and checked my email to see if the job failed. 

After refreshing my page, I found that all 21 slurm files were there. I knew that all pairs of the fastq files were run as there were a total of 21 pairs, and in each file, I could see that both pairs were run. I double checked to make sure they all ran by looking at the first slurm file and saw that the first fastq files in the list (ERR10802863) was ran, and the last slurm file had the last fastq files (ERR10802886). 

I moved the slrum files into a `logs` dir with:
```bash
mkdir logs 
mv slurm* logs
``` 

