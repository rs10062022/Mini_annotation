#!/bin/bash

#Example: bash ./main.sh -v short.vcf -o Short_output -t

echo "### Checking options and directories..."
while getopts "v:o:t" opt;
do
	case $opt in
		v) input="$OPTARG";;
		o) outdir="$OPTARG";;
		t) lift=true;;
		\?) help; exit 1
	esac
done
if [ -z $input ] || [ -z $outdir ];
then
	echo "### Must specify vcf and name of output directory"
	exit 1
else
	rm -r $outdir
	mkdir $outdir
fi

if [ -d "Reference_resources" ] 
then
	echo "### Reference_resources detected..." 
else
	echo "### Installing Reference_resources..."
	bash get_dependencies.sh
fi

echo "### Formating multilallic info..."
perl preprocess.pl $input $outdir/$input.vcf

echo "### Indexing VCF..."
Reference_resources/htslib-1.16/bgzip $outdir/$input.vcf
Reference_resources/htslib-1.16/tabix -f -p vcf $outdir/$input.vcf.gz

if grep -i '^c' $input;
then
	Reference_resources/bcftools-1.16/bcftools view $outdir/input.vcf.gz \
		-O v -o $outdir/$input.proc.vcf
else
	echo "### Adding CHR prefix..."
	Reference_resources/bcftools-1.16/bcftools annotate \
		--rename-chrs bareToChr.txt \
		$outdir/$input.vcf.gz \
		-O v -o $outdir/$input.proc.vcf
fi

if [ -z $lift ];
then
	echo "### Assuming hg38 format..."
	cp $outdir/$input.proc.vcf $outdir/$input.proc.hg38.vcf
else
	echo "### Lifting over to hg38..."
	mv $outdir/$input.proc.vcf $outdir/$input.proc.hg19.vcf
	java -Xmx8192m -jar Reference_resources/picard.jar LiftoverVcf \
		-I $outdir/$input.proc.hg19.vcf \
		-O $outdir/$input.proc.hg38.vcf \
		-C Reference_resources/hg19ToHg38.over.chain \
		-R Reference_resources/hg38.fa \
		--REJECT $outdir/$input.unlifted.vcf
fi

echo "### Running variant normalization..."
Reference_resources/bcftools-1.16/bcftools norm --multiallelics - $outdir/$input.proc.hg38.vcf \
    --fasta-ref Reference_resources/hg38.fa \
    -O v -o $outdir/$input.proc.hg38.norm.vcf

echo "### Splitting VCF input files..."
rm -r $outdir/Tmp
mkdir $outdir/Tmp
grep -v '^#' $outdir/$input.proc.hg38.norm.vcf > $outdir/noheader.txt
split -l 200 $outdir/noheader.txt $outdir/Tmp/subvcfs.
process_ids=""
numFiles=$(ls $outdir/Tmp/subvcfs* | wc -l)
COUNT=1
FILES="$outdir/Tmp/subvcfs*"
for i in $FILES
do
        echo "Callinig VEP for subfile $i (   $COUNT   of   ...$numFiles   )"
        python3 callvepi.py $i &
        process_ids="$process_ids $!"
        sleep 0.1
	COUNT=$[$COUNT +1]
done
echo "# Processing requests..."
wait $process_ids
echo Chr$'\t'Pos$'\t'ID$'\t'Ref$'\t'Alt$'\t'Total_counts$'\t'Total_reads$'\t'Percent_support_reads$'\t'gnomADex_freq$'\t'Txn_effects$'\t'ClinVar_sig$'\t'PMIDs > $outdir/results.tsv
sed '/^$/d' $outdir/Tmp/*tsv | sort -k 1,1 -k2,2n >> $outdir/results.tsv

echo "DONE: please find results at $outdir/results.tsv"
