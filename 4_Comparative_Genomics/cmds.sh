# Make exercise dir
mkdir ex6
cd ex6/

# MAke dir to store raw data
mkdir Raw_FastQs
cd Raw_FastQs/

# Get raw data using accession and fasterq-dump
mamba activate ex3
for accession in SRR1993270 SRR1993271 SRR1993272 SRR2984947 SRR2985018 SRR3214715 SRR3215024 SRR3215107 SRR3215123 SRR3215124; do
  fasterq-dump \
   "${accession}" 
   --outdir . \
   --split-files \
   --skip-technical
done
pigz -9 *.fastq # .gz using pigz
cd ..

# Make dir to store trimmed/cleaned data
mkdir Cleaned_FastQs

# Clean raw data using fastp
fastp -i Raw_FastQs/SRR1993270_1.fastq.gz -I Raw_FastQs/SRR1993270_2.fastq.gz -o ~/7210/ex6/Cleaned_FastQs/SRR1993270.R1.fq.gz -O ~/7210/ex6/Cleaned_FastQs/SRR1993270.R2.fq.gz --json ~/7210/ex6/Cleaned_FastQs/SRR1993270.json --html ~/7210/ex6/Cleaned_FastQs/SRR1993270.html
fastp -i Raw_FastQs/SRR1993271_1.fastq.gz -I Raw_FastQs/SRR1993271_2.fastq.gz -o ~/7210/ex6/Cleaned_FastQs/SRR1993271.R1.fq.gz -O ~/7210/ex6/Cleaned_FastQs/SRR1993271.R2.fq.gz --json ~/7210/ex6/Cleaned_FastQs/SRR1993271.json --html ~/7210/ex6/Cleaned_FastQs/SRR1993271.html
fastp -i Raw_FastQs/SRR1993272_1.fastq.gz -I Raw_FastQs/SRR1993272_2.fastq.gz -o ~/7210/ex6/Cleaned_FastQs/SRR1993272.R1.fq.gz -O ~/7210/ex6/Cleaned_FastQs/SRR1993272.R2.fq.gz --json ~/7210/ex6/Cleaned_FastQs/SRR1993272.json --html ~/7210/ex6/Cleaned_FastQs/SRR1993272.html
fastp -i Raw_FastQs/SRR2984947_1.fastq.gz -I Raw_FastQs/SRR2984947_2.fastq.gz -o ~/7210/ex6/Cleaned_FastQs/SRR2984947.R1.fq.gz -O ~/7210/ex6/Cleaned_FastQs/SRR2984947.R2.fq.gz --json ~/7210/ex6/Cleaned_FastQs/SRR2984947.json --html ~/7210/ex6/Cleaned_FastQs/SRR2984947.html
fastp -i Raw_FastQs/SRR2985018_1.fastq.gz -I Raw_FastQs/SRR2985018_2.fastq.gz -o ~/7210/ex6/Cleaned_FastQs/SRR2985018.R1.fq.gz -O ~/7210/ex6/Cleaned_FastQs/SRR2985018.R2.fq.gz --json ~/7210/ex6/Cleaned_FastQs/SRR2985018.json --html ~/7210/ex6/Cleaned_FastQs/SRR2985018.html
fastp -i Raw_FastQs/SRR3214715_1.fastq.gz -I Raw_FastQs/SRR3214715_2.fastq.gz -o ~/7210/ex6/Cleaned_FastQs/SRR3214715.R1.fq.gz -O ~/7210/ex6/Cleaned_FastQs/SRR3214715.R2.fq.gz --json ~/7210/ex6/Cleaned_FastQs/SRR3214715.json --html ~/7210/ex6/Cleaned_FastQs/SRR3214715.html
fastp -i Raw_FastQs/SRR3215024_1.fastq.gz -I Raw_FastQs/SRR3215024_2.fastq.gz -o ~/7210/ex6/Cleaned_FastQs/SRR3215024.R1.fq.gz -O ~/7210/ex6/Cleaned_FastQs/SRR3215024.R2.fq.gz --json ~/7210/ex6/Cleaned_FastQs/SRR3215024.json --html ~/7210/ex6/Cleaned_FastQs/SRR3215024.html
fastp -i Raw_FastQs/SRR3215107_1.fastq.gz -I Raw_FastQs/SRR3215107_2.fastq.gz -o ~/7210/ex6/Cleaned_FastQs/SRR3215107.R1.fq.gz -O ~/7210/ex6/Cleaned_FastQs/SRR3215107.R2.fq.gz --json ~/7210/ex6/Cleaned_FastQs/SRR3215107.json --html ~/7210/ex6/Cleaned_FastQs/SRR3215107.html
fastp -i Raw_FastQs/SRR3215123_1.fastq.gz -I Raw_FastQs/SRR3215123_2.fastq.gz -o ~/7210/ex6/Cleaned_FastQs/SRR3215123.R1.fq.gz -O ~/7210/ex6/Cleaned_FastQs/SRR3215123.R2.fq.gz --json ~/7210/ex6/Cleaned_FastQs/SRR3215123.json --html ~/7210/ex6/Cleaned_FastQs/SRR3215123.html
fastp -i Raw_FastQs/SRR3215124_1.fastq.gz -I Raw_FastQs/SRR3215124_2.fastq.gz -o ~/7210/ex6/Cleaned_FastQs/SRR3215124.R1.fq.gz -O ~/7210/ex6/Cleaned_FastQs/SRR3215124.R2.fq.gz --json ~/7210/ex6/Cleaned_FastQs/SRR3215124.json --html ~/7210/ex6/Cleaned_FastQs/SRR3215124.html

# Make dir to store assembly data
mkdir Assemblies

# Assemble trimmed data using skesa
for read in ~/7210/ex6/Cleaned_FastQs/*.R1.fq.gz; do sample="$(basename ${read} .R1.fq.gz)"; skesa --reads "${read}","${read%R1.fq.gz}R2.fq.gz" --cores 4 --min_contig 1000 --contigs_out ~/7210/ex6/Assemblies/"${sample}".fna; done

# BElow are steps to Create phylogeny

# create dir
mkdir parsnp_input_assemblies
cd parsnp_input_assemblies

# link assembly files to this dir
for file in ~/7210/ex6/Assemblies/*.fna; do ln -sv "${file}" "$(basename ${file})"; done

# check if the files are avilable
ls -alhtr *.{fa,fna}

mamba deactivate
mamba create -n harvestsuite -c bioconda parsnp harvesttools figtree -y
mamba activate harvestsuite
cd ..
parsnp -d parsnp_input_assemblies -r ! -o parsnp_outdir -p 4 # running parsnp
figtree -graphic PDF parsnp_outdir/parsnp.tree tree.pdf # run figtree to visualize parsnp output

