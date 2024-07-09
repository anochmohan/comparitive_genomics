# Init mamba
mamba init
mamba activate
# Create mamba env
mamba create -n ex4_pt1 -y
# Activate env
mamba activate ex4_pt1
# Install packages
mamba install -c bioconda -c conda-forge barrnap bedtools -y
# Deactivate mamba env
mamba deactivate
# Create mamba env
mamba create -n ex4_pt2 -y
# Activate env
mamba activate ex4_pt2
# Install packages
mamba install -c bioconda -c conda-forge prodigal pigz -y
# Make dir for this ex
mkdir -pv ~/Gene_prediction
# Make dir for ssu
mkdir -pv ~/Gene_prediction/ex_ssu
# Make dir for cds
mkdir -pv ~/Gene_prediction/cds
# Move to the dir
cd ~/Gene_prediction
# Get  data
wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/034/427/945/GCF_034427945.1_ASM3442794v1/GCF_034427945.1_ASM3442794v1_genomic.fna.gz
# Unzip the file
gunzip GCF_034427945.1_ASM3442794v1_genomic.fna.gz
# Run Prodigal
prodigal -i GCF_034427945.1_ASM3442794v1_genomic.fna -c -m -f gff -o ex_cds/mohan.gff 2>&1 | tee mohan.log
# Deactivate env
mamba deactivate
# Activate env ex4_pt1 to run barrnap
mamba activate ex4_pt1
# Run burrnap
barrnap GCF_034427945.1_ASM3442794v1_genomic.fna | grep "Name=16S_rRNA;product=16S ribosomal RNA" > ex_ssu/16S.gff
# Run bedtools
bedtools getfasta -fi GCF_034427945.1_ASM3442794v1_genomic.fna -bed ex_ssu/16S.gff -fo ex_ssu/mohan.16S.fa
# Clean up files
rm -v *.{fai,gff}
# Zip all the files
gzip ex_cds/mohan.gff ex_ssu/mohan.16S.fa mohan.log
# Deactivate env
mamba deactivate