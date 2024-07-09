## Specific Objectives
1. fetch raw FastQ data from NCBI
1. quickly assess read quality
1. use a read cleaning tool that does some (but not all) sequence filtering/removal
1. quickly assemble an isolate genome
1. identify the value of post-process filtering of a raw assembly


##### Create conda environment with software for this exercise
`conda create -n ex3 -y`


##### Go into the ex3 environment and install utilities from the bioconda channel
`conda activate ex3`
`conda install -c bioconda -c conda-forge entrez-direct sra-tools fastqc trimmomatic skesa spades pigz -y`


##### Fetch FastQ data
`mkdir -pv ~/exercise_3/raw_data`
`fasterq-dump --version` # mine was fasterq-dump : 3.0.10
```
fasterq-dump \
 SRR15276224 
 --threads 1 \
 --outdir ~/exercise_3/raw_data \
 --split-files \
 --skip-technical
```
- backup webpage GUI download option https://trace.ncbi.nlm.nih.gov/Traces/?view=run_browser&acc=SRR15276224&display=download select "FastQ" format to download
`pigz -9f ~/exercise_3/raw_data/*.fastq`
- **NOTE**: *never* store FastQ uncompressed!


#### View quality assessment
`mkdir -v ~/exercise_3/raw_qa`
`fastqc --version` # mine was FastQC v0.12.1
```
fastqc \
 --threads 2 \
 --outdir ~/exercise_3/raw_qa \
 ~/exercise_3/raw_data/SRR15276224_1.fastq.gz \
 ~/exercise_3/raw_data/SRR15276224_2.fastq.gz
```
`google-chrome ~/exercise_3/raw_qa/*.html`


#### Remove low quality reads
`mkdir -v ~/exercise_3/trim`
`cd ~/exercise_3/trim`
`trimmomatic -version` # mine was 0.39
```
trimmomatic PE -phred33 \
 ~/exercise_3/raw_data/SRR15276224_1.fastq.gz \
 ~/exercise_3/raw_data/SRR15276224_2.fastq.gz \
 ~/exercise_3/trim/r1.paired.fq.gz \
 ~/exercise_3/trim/r1_unpaired.fq.gz \
 ~/exercise_3/trim/r2.paired.fq.gz \
 ~/exercise_3/trim/r2_unpaired.fq.gz \
 SLIDINGWINDOW:5:30 AVGQUAL:30 \
 1> trimmo.stdout.log \
 2> trimmo.stderr.log
```
`cat ~/exercise_3/trim/r1_unpaired.fq.gz ~/exercise_3/trim/r2_unpaired.fq.gz > ~/exercise_3/trim/singletons.fq.gz`
`rm -v ~/exercise_3/trim/*unpaired*`
`tree ~/exercise_3/trim`


#### Assemble with SKESA
`mkdir -v ~/exercise_3/asm`
`cd ~/exercise_3/asm`
`skesa --version` # mine was SKESA 2.5.1
```
skesa \
 --reads ~/exercise_3/trim/r1.paired.fq.gz ~/exercise_3/trim/r2.paired.fq.gz \
 --contigs_out ~/exercise_3/asm/skesa_assembly.fna \
 1> skesa.stdout.txt \
 2> skesa.stderr.txt
 ```
- view how many contigs
`grep -c '>' *fna`


#### Extra Resources
1. use https://github.com/chrisgulvik/genomics_scripts/blob/master/filter.contigs.py (need Python 2.7 with Biopython installed in a conda environment) to evaluate how filtering parameters (e.g., contig coverage, contig length, etc.) affect your output genome size.
