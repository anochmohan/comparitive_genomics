# Genotyping and Taxonomic and Quality Assessments

### Resources
1. FastANI
    - original [manuscript](https://pubmed.ncbi.nlm.nih.gov/30504855/)
    - code repository [here](https://github.com/ParBLiSS/FastANI)
2. MLST
    - code repository [here](https://github.com/tseemann/mlst)
    - data interpretation [here](https://github.com/tseemann/mlst?tab=readme-ov-file#missing-data)
3. CheckM
    - original [manuscript](http://genome.cshlp.org/content/25/7/1043)
    - code repository [here](https://github.com/Ecogenomics/CheckM)
    - tutorial [here](https://github.com/Ecogenomics/CheckM/wiki/Workflows#lineage-specific-workflow)


#### Taxonomic Exercise
NCBI reports [this assembly](https://www.ncbi.nlm.nih.gov/datasets/genome/GCA_001879185.2/) is contaminated and has too many frameshifted proteins. So although it remains in GenBank, it is excluded from RefSeq. Evaluate this assembly further.

1. Setup the working directory, fetch the compressed assembly FastA files, decompress, and verify they look right
```
mkdir -pv ~/ex5/fastani
cd ~/ex5/fastani
wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/001/879/185/GCA_001879185.2_ASM187918v2/GCA_001879185.2_ASM187918v2_genomic.fna.gz https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/254/515/GCF_000254515.1_ASM25451v2/GCF_000254515.1_ASM25451v2_genomic.fna.gz
gunzip -kv *.fna.gz
head -n 2 *.fna
tail -n 1 *.fna
grep '>' *.fna
```

2. Rename to make this simpler
```
mv -v GCF_000254515.1_ASM25451v2_genomic.fna reference.fna
mv -v GCA_001879185.2_ASM187918v2_genomic.fna problem.fna
```

3. Compare "contaminated" problem assembly to the species type strain
```
conda create -n fastani -c bioconda fastani -y
conda activate fastani
fastANI \
  --query problem.fna \
  --ref reference.fna \
  --output FastANI_Output.tsv
awk \
  '{alignment_percent = $4/$5*100} \
   {alignment_length = $4*3000} \
   {print $0 "\t" alignment_percent "\t" alignment_length}' \
  FastANI_Output.tsv \
  > FastANI_Output_With_Alignment.tsv
sed \
  "1i Query\tReference\t%ANI\tNum_Fragments_Mapped\tTotal_Query_Fragments\t%Query_Aligned\tBasepairs_Query_Aligned" \
  FastANI_Output_With_Alignment.tsv \
  > FastANI_Output_With_Alignment_With_Header.tsv
column -ts $'\t' FastANI_Output_With_Alignment_With_Header.tsv | less -S
```

#### Genotyping Exercise
4. Perform MLST
- NOTE: if conda takes too long to install the `mlst` package suite, consider docker as an alternative
```
docker pull staphb/mlst:latest
docker run -it --mount type=bind,src=$HOME/ex5,target=/local staphb/mlst bash
cd /local
mlst *.fna > MLST_Summary.tsv
exit
```

```
mkdir -pv ~/ex5/mlst
cd ~/ex5/mlst
ln -sv ../fastani/problem.fna .
conda create -n mlst -c conda-forge -c bioconda mlst -y
conda activate mlst
mlst *.fna > MLST_Summary.tsv
column -ts $'\t' FastANI_Output_With_Alignment_With_Header.tsv | less -S
```

#### Quality Assessments Exercise
5. Evaluate the assembly itself
```
mkdir -pv ~/ex5/checkm/{asm,db}
cd ~/ex5/checkm/asm
ln -sv ../../fastani/problem.fna .
conda create -n checkm -c conda-forge -c bioconda checkm-genome -y
conda activate checkm
cd ~/ex5/checkm/db
# Download took me 5 min
wget https://zenodo.org/records/7401545/files/checkm_data_2015_01_16.tar.gz
tar zxvf checkm_data_2015_01_16.tar.gz
echo 'export CHECKM_DATA_PATH=$HOME/ex5/checkm/db' >> ~/.bashrc
source ~/.bashrc
echo "${CHECKM_DATA_PATH}"
conda activate checkm
cd ~/ex5/checkm
checkm taxon_list | grep Campylo
checkm taxon_set species "Campylobacter jejuni" Cj.markers
checkm \
  analyze \
  Cj.markers \
  ~/ex5/checkm/asm \
  analyze_output
checkm \
  qa \
  -f checkm.tax.qa.out \
  -o 1 \
  Cj.markers \
  analyze_output
sed 's/ \+ /\t/g' checkm.tax.qa.out > checkm.tax.qa.out.tsv
cut -f 2- checkm.tax.qa.out.tsv > tmp.tab && mv tmp.tab checkm.tax.qa.out.tsv
sed -i '1d; 3d; $d' checkm.tax.qa.out.tsv
column -ts $'\t' checkm.tax.qa.out.tsv | less -S
```

##### Pairwise bash tricks for FastANI

1. Form a bash array (list of files to be analyzed). This assumes assemblies are "fa" or "fna" file extensions in the current working directory.
```
shopt -s nullglob
assemblies=( *.{fa,fna} )
shopt -u nullglob
```

2. Perform pairwise comparisons using the store array containing filepaths as input
```
for ((i = 0; i < ${#assemblies[@]}; i++)); do 
  for ((j = i + 1; j < ${#assemblies[@]}; j++)); do 
    echo "${assemblies[i]} and ${assemblies[j]} being compared..."
    fastANI \
     -q ${assemblies[i]} \
     -r ${assemblies[j]} \
     -o FastANI_Outdir_${assemblies[i]}_${assemblies[i]}.tsv
  done
done 
```

3. View ANI values
`cat FastANI_Outdir_*.txt | awk '{print $1, $2, $3}'`


### Practice Exercise (steps found in cmds.sh)
(3) *Helicobacter pylori* isolates were sequenced as part of an outbreak analysis. SRA accessions are on NCBI for each:
SRR3214715
SRR3215024
SRR3215107

Use all (3) SRA accessions above and fetch the Illumina sequence data from NCBI. Perform fastANI against the species type strain. Will have to find and fetch the type strain genome.

Use previously learned skills:
1. Fetch all read sets with sra-tools as performed previously with `fasterq-dump`
1. Quick read clean with `fastp` 
1. Quick assembly with `skesa` 
1. Filter out low coverage and short contigs
1. Verify filesizes look similar with `ls -alh *.fna` in output directory containing all assemblies. If they're not similar in filesizes, refine trim and assembly parameters. All 3 are highly related and in the outbreak.

Genotype all 3 assemblies with MLST. For just 1 assembly of the 3, estimate its completeness and contamination levels.