# Comparative Genomics

### Follow cmds.sh file or the instructions below

### Resources
1. ParSNP within the harvest suite
    - original [manuscript](https://pubmed.ncbi.nlm.nih.gov/25410596/)
    - code repository [here](https://github.com/marbl/parsnp)
    - tutorial [here](https://harvest.readthedocs.io/en/latest/content/parsnp/tutorial.html)
2. Snippy
    - unpublished
    - code repository [here](https://github.com/tseemann/snippy)
    - tutorial using Galaxy (not CLI) [here](http://sepsis-omics.github.io/tutorials/modules/snippy/)
3. BinDash
    - original [manuscript](https://pubmed.ncbi.nlm.nih.gov/30052763/)
    - code repository [here](https://github.com/zhaoxiaofei/bindash)


### Exercise
(10) *Helicobacter pylori* isolates were sequenced as part of an outbreak analysis. SRA accessions are on NCBI for each:
SRR1993270
SRR1993271
SRR1993272
SRR2984947
SRR2985018
SRR3214715
SRR3215024
SRR3215107
SRR3215123
SRR3215124

**SRR3214715** [assembly](https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/001/879/185/GCA_001879185.2_ASM187918v2/GCA_001879185.2_ASM187918v2_genomic.fna.gz) should be used as the **reference**. 

##### Use previously learned skills
`mkdir ~/ex6`
1. Fetch all read sets with sra-tools as performed previously with `fasterq-dump` (e.g., `conda activate ex3`)
```
mkdir ~/ex6/Raw_FastQs
cd ~/ex6/Raw_FastQs
for accession in SRR1993270 SRR1993271 SRR1993272 SRR2984947 SRR2985018 SRR3214715 SRR3215024 SRR3215107 SRR3215123 SRR3215124; do
  fasterq-dump \
   "${accession}" 
   --outdir . \
   --split-files \
   --skip-technical
done
pigz -9 *.fastq
```
2. Quick read clean with `fastp` or what you're most comfortable with
```
mkdir ~/ex6/Cleaned_FastQs
for read in ~/ex6/Raw_FastQs/*_1.fastq.gz; do
  sample="$(basename ${read} _1.fastq.gz)"
  echo fastp \
   -i "${read}" \
   -I "${read%_1.fastq.gz}_2.fastq.gz" \
   -o "~/ex6/Cleaned_FastQs/${sample}.R1.fq.gz" \
   -O "~/ex6/Cleaned_FastQs/${sample}.R2.fq.gz" \
   --json "~/ex6/Cleaned_FastQs/${sample}.json" \
   --html "~/ex6/Cleaned_FastQs/${sample}.html"
done
# run the printed commmands to clean
```
3. Quick assembly with `skesa` as performed previously (e.g., `conda activate ex3`)
```
mkdir ~/ex6/Assemblies
for read in ~/ex6/Cleaned_FastQs/*.R1.fq.gz; do
  sample="$(basename ${read} .R1.fq.gz)"
  skesa \
   --reads "${read}","${read%R1.fq.gz}R2.fq.gz" \
   --cores 4 \
   --min_contig 1000 \
   --contigs_out ~/ex6/Assemblies/"${sample}".fna
done

```
4. Verify filesizes look similar with `ls -alhS *.fna` in your output directory containing all assemblies. If they're not similar in filesizes, refine trim and assembly parameters. All are highly related and in the outbreak.

##### ParSNP
1. Install (note: the `gingr` GUI isn't in bioconda so you'd need to grab the binary for [mac](https://github.com/marbl/gingr/releases/download/v1.3/gingr-OSX64-v1.3.app.zip) or [linux](https://github.com/marbl/gingr/releases/download/v1.3/gingr-Linux64-v1.3.tar.gz) on the repo, or just use `figtree` for the tree-only visualization)
`conda create -n harvestsuite -c bioconda parsnp harvesttools figtree -y`

1. Parsnp grabs all files in a path, so make a new folder manually or copy symlinks to a new path. This assumes all assemblies are "fa" or "fna" file extensions
```
mkdir ~/ex6/parsnp_input_assemblies
cd ~/ex6/parsnp_input_assemblies
for file in /my-path/files/*.{fa,fna}; do
  ln -sv "${file}" "$(basename ${file})"
done
```

3. confirm the files are here and available
`ls -alhtr *.{fa,fna}`

4. Run ParSNP with assemblies to generate a core SNP phylogenetic tree. Uses 4 CPUs (-p arg)
```
cd ~/ex6
conda activate harvestsuite
parsnp \
 -d parsnp_input_assemblies \
 -r ! \
 -o parsnp_outdir \
 -p 4
```

5. View phylogenetic tree (a GUI will pop up from this terminal command; or just launch the GUI and open the file)
figtree parsnp_outdir/parsnp.tree

6. Beautify your tree with [InkScape](https://inkscape.org/) or [Adobe Illustrator](https://en.wikipedia.org/wiki/Adobe_Illustrator), save as a usable image-viewing format for future use (e.g., PNG, PDF, SVG)

##### Snippy
1. Install
`conda create -n snippy -c conda-forge -c bioconda -c defaults snippy iqtree figtree -y`

1. Go into snippy environment where the scripts and binaries for the pipeline are available in your $PATH
`conda activate snippy`

1. Using the same reference assemblie file, identify SNPs for each of the samples. Use [bash string manipulation](https://tldp.org/LDP/abs/html/string-manipulation.html) on the "_1.fastq.gz" to do the loop simpler here with "%" to trim the filename suffix.
```
for read in /my-path/raw-or-trimmed-fastqs/*_1.fastq.gz; do
  snippy \
   --cpus 4 \
   --outdir mysnps-"${file%_1.fastq.gz}" \
   --ref /my-path/SRR3214715.fna \
   --R1 "${file}" \
   --R2 "${file%_1.fastq.gz}"_2.fastq.gz
done
```

4. Confirm outfiles for all 3 are present an not empty
`ls -alhtr mysnps-*/snps.vcf`

5.  Identify core SNPs among all samples
```
snippy-core \
 --prefix core \
 mysnps-*
```

6. Infer phylogeny
```
iqtree \
 -nt AUTO \
 -st DNA \
 -s core.aln
```

7. View tree
`figtree *.treefile`

##### BinDash
1. Install
`conda create -n bindash -c bioconda bindash -y`

1. Go into the environment where the `bindash` binary will be available to use
`conda activate bindash`

1. Form a bash array (list of files to be analyzed). This assumes assemblies are "fa" or "fna" file extensions in the current working directory.
```
cd ~/ex6/Assemblies
shopt -s nullglob
assemblies=( *.{fa,fna} )
shopt -u nullglob
```

4. Perform pairwise comparisons using the store array containing filepaths as input
```
for assembly in ~/ex6/Assemblies/*.fna; do
  bindash sketch --kmerlen=21 --sketchsize64=5000 --bbits=64 --outfname="${assembly}.sketch" ${assembly}
done

mkdir ~/ex6/bindash
for ((i = 0; i < ${#assemblies[@]}; i++)); do 
  for ((j = i + 1; j < ${#assemblies[@]}; j++)); do 
    echo "${assemblies[i]} and ${assemblies[j]} being compared..."
    sampleA="$(basename ${assemblies[i]} .fna)"
    sampleB=$(basename ${assemblies[k]} .fna)
    bindash \
     dist \
     ~/ex6/Assemblies/${assemblies[i]}.sketch \
     ~/ex6/Assemblies/${assemblies[j]}.sketch \
     > ~/ex6/bindash/${sampleA}_${sampleB}.tsv
  done
done 
```

5. View  values
`cat ~/ex6/bindash/*.tsv | awk '{print $1, $2, $5}'`
