#!/bin/bash

mkdir Reference_resources
cd Reference_resources

wget https://github.com/samtools/samtools/releases/download/1.16.1/samtools-1.16.1.tar.bz2
tar xvf samtools-1.16.1.tar.bz2
cd samtools-1.16.1
make
make install
cd ..

wget https://github.com/samtools/bcftools/releases/download/1.16/bcftools-1.16.tar.bz2
tar xvf bcftools-1.16.tar.bz2
cd bcftools-1.16
make
cd ..

wget https://github.com/samtools/htslib/releases/download/1.16/htslib-1.16.tar.bz2
tar xvf htslib-1.16.tar.bz2
cd htslib-1.16
make
make install
cd ..

rm *.tar.bz2

wget https://github.com/broadinstitute/picard/releases/download/2.27.4/picard.jar

wget https://hgdownload.cse.ucsc.edu/goldenpath/hg38/bigZips/hg38.fa.gz
gunzip hg38.fa.gz

java -Xmx8192m -jar picard.jar CreateSequenceDictionary -R hg38.fa
samtools-1.16.1/samtools faidx hg38.fa

wget https://hgdownload.cse.ucsc.edu/goldenpath/hg19/liftOver/hg19ToHg38.over.chain.gz
gunzip hg19ToHg38.over.chain.gz
cd ..
