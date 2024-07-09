# Make dir for exercise
mkdir Gntyp_Tax_QA
cd Gntyp_Tax_QA/

# Make dir to store data from SRA
mkdir raw_data

# Activate environment from previous exercise
mamba activate ex3
cd raw_data/ # go to dir

# Fetch data using fasterq-dump
fasterq-dump SRR3214715 --threads 1 --outdir ./ --split-files --skip-technical
fasterq-dump SRR3215024 --threads 1 --outdir ./ --split-files --skip-technical
fasterq-dump SRR3215107 --threads 1 --outdir ./ --split-files --skip-technical

cd ../.. # leave dir 2x

# Copy nextflow workflow from workflow_management assignment to working dir
# Make necesary changes to the files
# This workflow will do quality control (bbduk) and assembly (skesa) 
cp -r workflow_asgmnt/workflow_ex1/phix_data/ Gntyp_Tax_QA/
cd Gntyp_Tax_QA/ # enter working dir
cd raw_data/ # enter raw_data dir
gzip *.fastq # compress the files
ls -alh # check their sizes
mamba deactivate
cd ..

# Activate environment from the workflow assignment
mamba activate wrkflw
nextflow run main.nf # Run nextflow 
ls -alh trimmed_output/ # This is a dir created by nextflow process. Check size of trimmed files.
mamba deactivate

# Create environment to run fastqc on the trimmed data
mamba create -n fastqc
mamba activate fastqc
mamba install bioconda::fastqc -y
mkdir post_trim_qual # to store the data files from fastqc
fastqc -h # to read fastqc doc
fastqc -o post_trim_qual/ trimmed_output/* # command to run fastqc
# Here I found that the trimmed data had primer adaptors still connected
mamba deactivate

# Process to remove adapter contamination
# Adapters were downloaded using GUI
mamba activate ex3 # cuz this has gzip
gunzip truseq.fa.gz nextera.fa.gz truseq_rna.fa.gz #unzip the gz files
mv nextera.fa truseq_rna.fa phix_data/ # dir from line 21
mamba deactivate

# Rerun the workflow
mamba activate wrkflw
nextflow run main.nf # run the workflow
mamba deactivate

# Check the quality again
mamba activate fastqc
mkdir fixd_postqc # to compare the new qc with the old qc
fastqc -o fixd_postqc/ trimmed_output/* # command to run fastqc
ls -alh trimmed_output/ # check size of trimmed data
ls -alh asm_output/ # check size of assemly files
mamba deactivate

# Filter out low coverage and short contigs
mamba create -n gulvik
mamba activate gulvik
mamba install python=2.7 -y
mamba install bioconda::biopython -y
./filter.contigs.py -h
mkdir asm_output2
./filter.contigs.py -i asm_output/SRR3214715.fna -g -m -c 5 -l 250 -o asm_output2/filt_SRR3214715.fna
./filter.contigs.py -i asm_output/SRR3215024.fna -g -m -c 5 -l 250 -o asm_output2/filt_SRR3215024.fna
./filter.contigs.py -i asm_output/SRR3215107.fna -g -m -c 5 -l 250 -o asm_output2/filt_SRR3215107.fna
# No filteration happened, so continued to use the original files
mamba deactivate

# Calculate Avg. Nucleotide Identity
mkdir fastani # Create dir
cd fastani/ # enter dir
ls -1 asm_output/ > query_list.txt # create a file with the names
mamba activate fastANI # I had this in my system already, if not follow instructions from conda
ln -sv ../asm_output/* . #link assembly to current dir
mamba deactivate
# Used GUI to download the strain type genome https://www.ncbi.nlm.nih.gov/datasets/taxonomy/32022/
mamba activate ex3 # to unzip
unzip ncbi_dataset.zip
mv ncbi_dataset/data/GCF_000009085.1_ASM908v1_genomic/GCF_000009085.1_ASM908v1_genomic.fna ./ # easier to run fastANI when all files are in the same dir
rm -r ncbi_dataset # to save space
mamba deactivate
mamba activate fastANI
fastANI --ql query_list.txt -r GCF_000009085.1_ASM908v1_genomic.fna -o fastani.tsv # Run fastANI
awk '{alignment_percent = $4/$5*100} {alignment_length = $4*3000} {print $0 "\t" alignment_percent "\t" alignment_length}' ../fastani/fastani.tsv > ../fastani/FastANI_Output_With_Alignment.tsv # new columns Query_Aligned and Basepairs_Query_Aligned added
sed "1i Query\tReference\t%ANI\tNum_Fragments_Mapped\tTotal_Query_Fragments\t%Query_Aligned\tBasepairs_Query_Aligned" ../fastani/FastANI_Output_With_Alignment.tsv > ../fastani/FastANI_Output_With_Alignment_With_Header.tsv # headers given to files
column -ts $'\t' ../fastani/FastANI_Output_With_Alignment_With_Header.tsv # check to verify output
mamba deactivate

#MLST
cd .. # go back to working dir
mkdir mlst # create new dir
cd mlst/ # move to mlst dir
ln -sv ../asm_output/SRR321* . # link assembly to current dir
mamba create -n mlst -c conda-forge -c bioconda mlst -y # download mlst from conda
mamba activate mlst
mlst *.fna > MLST_Summary.tsv # run MLST
column -ts $'\t' MLST_Summary.tsv # verify the outputs
mamba deactivate

# Run Quality Assesment
mkdir checkm
cd checkm/
mkdir asm # for assemblies
mkdir db # for database
cd asm/
ln -sv ../../asm_output/SRR321* . # link assembly to current dir
cd .. # go back to checkm dir
mamba create -n checkm -c conda-forge -c bioconda checkm-genome -y
mamba activate checkm
cd db/
wget https://zenodo.org/records/7401545/files/checkm_data_2015_01_16.tar.gz # checkm database
tar zxvf checkm_data_2015_01_16.tar.gz # decompress the db
cd .. # go back to checkm dir
checkm taxon_list | grep Campylo # to find everything with campylo
checkm taxon_set species "Campylobacter jejuni" Cj.markers # markers for jejuni
checkm analyze Cj.markers asm/ analyze_output # analyze the markers against the assembly files
checkm qa -f checkm.tax.qa.out -o 1 Cj.markers analyze_output # quality assesment
sed 's/ \+ /\t/g' checkm.tax.qa.out > checkm.tax.qa.out.tsv # convert space to tab to make it a .tsv
cut -f 2- checkm.tax.qa.out.tsv > tmp.tab && mv tmp.tab checkm.tax.qa.out.tsv # cut 2nd field onwards and save it to tmp.tab, then mv is used to rename that file
sed -i '1d; 3d; $d' checkm.tax.qa.out.tsv # -i (inplace editing) removes 1st, 3rd and last lines
column -ts $'\t' checkm.tax.qa.out.tsv | less -S # verify the content
mv checkm.tax.qa.out.tsv quality.tsv # rename the file
cd ..
mamba deactivate