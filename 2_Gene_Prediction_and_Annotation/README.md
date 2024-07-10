# Gene Prediction

## Follow cmds.sh file or the instructions belpw


**(2) different approaches:**
1. 16S rRNA (small subunit ["ssu"]) gene sequence extraction
1. prediction of all protein-encoding gene sequences from an isolate's genome assembly

## 16S Extraction

##### Create conda environment with software for this first part of the exercise
`conda create -n ex4_pt1 -y`

##### Go into the ex4_pt1 environment and install barrnap (bedtools is a dependency) from the bioconda channel as priority over the conda-forge channel
```
conda activate ex4_pt1
conda install -c bioconda -c conda-forge barrnap bedtools -y
```

##### Setup work directory and fetch small bacterial genome assembly file (0.58 Mbp, *Mycoplasma genitalium*)
```
mkdir -pv ~/ex4/{ssu,cds}
cd ~/ex4/ssu
wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/027/325/GCF_000027325.1_ASM2732v1/GCF_000027325.1_ASM2732v1_genomic.fna.gz
gunzip -k *.fna.gz
```

#### Run barrnap
```
barrnap \
 GCF_000027325.1_ASM2732v1_genomic.fna \
 | grep "Name=16S_rRNA;product=16S ribosomal RNA" \
 > 16S.gff
bedtools getfasta \
 -fi GCF_000027325.1_ASM2732v1_genomic.fna \
 -bed 16S.gff -s \
 -fo 16S.fa
```

#### Cleanup and view output
```
rm -v *.{fai,gff}
cat 16S.fa
conda deactivate
```

## Coding Sequence (CDS) Prediction

##### Create new env for part2 
`conda create -n ex4_pt2 -y`

##### Go into the ex4_pt2 environment and install prodigal
```
conda activate ex4_pt2
conda install -c bioconda -c conda-forge prodigal pigz -y
```

##### Get back into working directory, and verify assembly file is still there from part1 (expect 574K filesize)
```
cd ~/ex4/cds
ls -lh ~/ex4/ssu/*.fna
```

#### Run prodigal (for bacterial isolate), storing stderr and stdout as a single logfile, while also being able to view on the interactive terminal and then print information
```
prodigal \
 -i ~/ex4/ssu/GCF_000027325.1_ASM2732v1_genomic.fna \
 -c \
 -m \
 -f gbk \
 -o cds.gbk \
 2>&1 | tee log.txt
```

##### Compress and view file output
```
pigz -9f *.gbk log.txt
zhead *.gbk.gz
zcat log.txt.gz
```

# Functional Annotation

We'll use one online **GUI** and one **CLI** tool to predict genes in a prokaryotic genome.

### Resources
1. InterPro
    - original [manuscript](https://pubmed.ncbi.nlm.nih.gov/11159333/)
    - newest 2023 db paper [here](https://pubmed.ncbi.nlm.nih.gov/36350672/)
    - cli newest search algorithm [manuscript](https://pubmed.ncbi.nlm.nih.gov/24451626/)
    - cli search algorithm [repo](https://github.com/ebi-pf-team/interproscan)
    - webGUI db + search algorithm [link](https://www.ebi.ac.uk/interpro/)
    - video resource [here](https://www.youtube.com/watch?v=EWLGFuTpUnQ)
2. eggNog ("evolutionary genealogy of genes: Non-supervised Orthologous Groups")
    - original [manuscript](https://pubmed.ncbi.nlm.nih.gov/17942413/)
    - newest 2023 db paper [here](https://pubmed.ncbi.nlm.nih.gov/36399505/)
    - cli [manuscript](https://pubmed.ncbi.nlm.nih.gov/34597405/)
    - cli search algorithm [repo](https://github.com/eggnogdb/eggnog-mapper)
    - webGUI db + search algorithm [link](http://eggnog-mapper.embl.de/)
    - video resource [here](https://www.youtube.com/watch?v=OrKViOoPX7U)

### Annotation
For the functional annotation exercise,

1. Download FastA sequences of proteins in the Aux5 clusters in this repo
2. Annotate the sequences using InterPro (Web GUI) and EggNOG (CLI or GUI).

Please keep in mind that this is a more **biologically-oriented** assignment. Look up the domains, motifs, and annotations to understand the role of each of these proteins.

#### Practice Assignment
1. fetch [genome](https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/034/427/945/GCF_034427945.1_ASM3442794v1/GCF_034427945.1_ASM3442794v1_genomic.fna.gz) - [recently described as a fosfomycin resistant bacterium](https://pubmed.ncbi.nlm.nih.gov/38334402/)
1. Choose 1 of 3 packages
    - "No one tool to rule them all" [manuscript](https://pubmed.ncbi.nlm.nih.gov/34875010/)
    1. GeneMark [src](http://topaz.gatech.edu/GeneMark/license_download.cgi) [manuscript](https://pubmed.ncbi.nlm.nih.gov/29773659/)
    1. GLIMMER [src](http://ccb.jhu.edu/software/glimmer/index.shtml) [manuscript](https://pubmed.ncbi.nlm.nih.gov/17237039/)
    1. Prodigal [src](https://github.com/hyattpd/Prodigal) [manuscript](https://pubmed.ncbi.nlm.nih.gov/20211023/)
4. Predict all coding sequences in the bacterial isolate genome, and store stderr and stdout logfile as a single plaintext ".log" file
5. Choose 1 of 2 packages
    1. RNAmmer [src](https://services.healthtech.dtu.dk/services/RNAmmer-1.2/5-Supplementary_Data.php) [manuscript](https://pubmed.ncbi.nlm.nih.gov/17452365/)
    1. barrnap [src](https://github.com/tseemann/barrnap) no-manuscript-exists
6. Extract *all* 16S rRNA gene sequences from the assembly file, stored as gunzip compressed FastA format
7. Use extracted 16S FastA extracted sequence(s) from gene prediction exercise to identify the top 5 hits. Include all pertinent alignment information, which would guide a final decision in identifying the isolate to **species-level**, and sort your best match to the *top*. [Here](https://blast.ncbi.nlm.nih.gov/Blast.cgi?PROGRAM=blastn&PAGE_TYPE=BlastSearch&LINK_LOC=blasthome) is the main webGUI page, but this is a lesson on database importance and alignment results interpretation. The appropriate database must be selected (hint, it's not the default) or results will be unhelpful. 
8. Write informative, single line descriptions of each protein in the cluster.

