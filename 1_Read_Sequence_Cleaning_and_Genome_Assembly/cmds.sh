# Create mamba env
mamba create -n ex3 -y
# Install packages
mamba install -c bioconda -c conda-forge entrez-direct sra-tools fastqc trimmomatic skesa spades pigz -y
# Activate env
mamba activate ex3
# Make dir to store raw data
mkdir -pv ~/exercise_3/raw_data
# Get raw data
fasterq-dump \
 SRR26244988  
 --threads 1 \
 --outdir ~/7210/Read_cleaning_GS/exercise_3/raw_data \
 --split-files \
 --skip-technical
# Compress files
pigz -9f ~/7210/Read_cleaning_GS/exercise_3/raw_data/*.fastq 
# Make dir to store qc data
mkdir -v ~/7210/Read_cleaning_GS/exercise_3/raw_qa
# Run fastqc
fastqc \
 --threads 2 \
 --outdir ~/7210/Read_cleaning_GS/exercise_3/raw_qa \
 ~/7210/Read_cleaning_GS/exercise_3/raw_data/SRR26244988_1.fastq.gz \
 ~/7210/Read_cleaning_GS/exercise_3/raw_data/SRR26244988_2.fastq.gz
# Remove low quality reads using exercise step
trimmomatic PE -phred33 \
 ~/7210/Read_cleaning_GS/exercise_3/raw_data/SRR26244988_1.fastq.gz \
 ~/7210/Read_cleaning_GS/exercise_3/raw_data/SRR26244988_2.fastq.gz \
 ~/7210/Read_cleaning_GS/exercise_3/trim1/r1.paired.fq.gz \
 ~/7210/Read_cleaning_GS/exercise_3/trim1/r1_unpaired.fq.gz \
 ~/exercise_3/trim1/r2.paired.fq.gz \
 ~/7210/Read_cleaning_GS/exercise_3/trim1/r2_unpaired.fq.gz \
 SLIDINGWINDOW:5:30 AVGQUAL:30 \
 1> trimmo.stdout.log \
 2> trimmo.stderr.log
# Remove low quality reads using extra flags step
trimmomatic PE -phred33 \
 ~/7210/Read_cleaning_GS/exercise_3/raw_data/SRR26244988_1.fastq.gz \
 ~/7210/Read_cleaning_GS/exercise_3/raw_data/SRR26244988_2.fastq.gz \
 ~/7210/Read_cleaning_GS/exercise_3/trim1/r1.paired.fq.gz \
 ~/7210/Read_cleaning_GS/exercise_3/trim1/r1_unpaired.fq.gz \
 ~/7210/Read_cleaning_GS/exercise_3/trim1/r2.paired.fq.gz \
 ~/7210/Read_cleaning_GS/exercise_3/trim1/r2_unpaired.fq.gz \
 SLIDINGWINDOW:5:30 AVGQUAL:30 \
 LEADING:30 \
 TRAILING:30 \
 1> trimmo.stdout.log \
 2> trimmo.stderr.log
# Make dir to store assembly output
mkdir -v ~/exercise_3/asm1
# DoWnload SPAdes
wget http://cab.spbu.ru/files/release3.15.5/SPAdes-3.15.5-Linux.tar.gz
tar -xzf SPAdes-3.15.5-Linux.tar.gz
cd SPAdes-3.15.5-Linux/bin/
# Verify INStallation
spades.py --test
# RUn SPAdes Assembler
spades.py \
 -1 ~/7210/Read_cleaning_GS/exercise_3/trim2/r1.paired.fq.gz \
 -2 ~/7210/Read_cleaning_GS/exercise_3/trim2/r2.paired.fq.gz \
 -o ~/7210/Read_cleaning_GS/exercise_3/asm1/
# Make dir to store assembly output
mkdir -v ~/exercise_3/asm2
# RUn SPAdes Assembler with --careful flag
spades.py \
 --careful \
 -1 ~/7210/Read_cleaning_GS/exercise_3/trim2/r1.paired.fq.gz \
 -2 ~/7210/Read_cleaning_GS/exercise_3/trim2/r2.paired.fq.gz \
 -o ~/7210/Read_cleaning_GS/exercise_3/asm2/
# SEtup new python env
mamba deactivate
mamba create -n filtcotigs -y
mamba activate filtcotigs
mamba install python=2.7
mamba install bioconda::biopython
# get filter.contigs.py
cd ~/7210/Read_cleaning_GS/exercise_3/
git clone https://github.com/chrisgulvik/genomics_scripts
cd genomic_scripts
# figure out how to use filter.contigs.py
python filter.contigs.py --help
# RUN filter.contigs.py
python filter.contigs.py \
 -i ~/7210/Read_cleaning_GS/exercise_3/asm1/contigs.fasta > output.fna
# Count number of contigs
grep ">" ../output.fna | wc -l
# Try different flags
python filter.contigs.py \
 -i ~/7210/Read_cleaning_GS/exercise_3/asm2/contigs.fasta \
 -c 0.95 \
 -l 700 \
 --silent \
 > ../output2.fna
grep ">" ../output2.fna | wc -l #88

python filter.contigs.py \
 -i ~/7210/Read_cleaning_GS/exercise_3/asm2/contigs.fasta \
 -c 1 \
 -l 500 \
 --silent \
 > ../output3.fna
grep ">" ../output3.fna | wc -l #95

python filter.contigs.py \
 -i ~/7210/Read_cleaning_GS/exercise_3/asm2/contigs.fasta \
 -c 1 \
 -l 700 \
 --silent \
 > ../output4.fna
grep ">" ../output4.fna | wc -l #90

python filter.contigs.py \
 -i ~/7210/Read_cleaning_GS/exercise_3/asm2/contigs.fasta \
 -c 1 \
 -l 1000 \
 --silent \
 > ../output5.fna
grep ">" ../output5.fna | wc -l #88

## Select the one I thought was right
python filter.contigs.py \
 -i ~/7210/Read_cleaning_GS/exercise_3/asm2/contigs.fasta \
 -c 1 \
 -l 1000 \
 --silent \
 > ../filtered_assembly.fna
grep ">" ../filtered_assembly.fna | wc -l #88
# Compress filtered_assembly.fna and spades.log
mamba deactivate
mamba activate ex3
pigz -9f filtered_assembly.fna 
pigz -9f ~/7210/Read_cleaning_GS/exercise_3/asm2/spades.log 
# Make tarball
tar \
 -czf assembly.tar.gz \
 ~/7210/Read_cleaning_GS/exercise_3/asm2/spades.log.gz \
 ~/7210/Read_cleaning_GS/exercise_3/filtered_assembly.fna.gz \
 ~/7210/Read_cleaning_GS/exercise_3/cmds.sh