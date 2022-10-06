# Title
- Mini_annotation

# Author
- Ryan L. Subaran, PhD (Columbia Univ., NY  2008)

# Date
- circa 10.06.2022

# Description
- Chicago is an analysis pipeline for varant format call (VCF) file that:
	1. Retrieves multi-transcript Ensembl effects for each variant
	2. Retrieves ClinVar clinical interpretation for variant 
	3. Retrieves a set of PMIDs referencing variant
	4. Extracts variant read depth and total read depth from user-provided VCF INFO fields

# Syntax
bash$: bash ./main.sh -v [input_vcf] -o [output_directory] -t (optional)
- Note:  Use the "-t" (transform) "switch" option to lift over variants if VCF reference genome is hg19, as Ensembl defers to hg38 notation. IMPORTANT:  Variants that fail lift over will be found in [output_directory]/[input_vcf].unlifted.vcf

# Dependencies and requirements
- Chicago is a bash script designed to be run from the command line.  It requires the user to Java installed, as well as Perl and Python in the appropriate paths.  
- Note: The first run of main.sh will install will install Reference_resources directory which contains resources for lift overs to hg38 and indel normalization
- Important: Due to limits of Enseml VEP API requests, the maximum number of variants that can be processed is 11,000,000 per hour.  If more variants need to be processed, please truncate inputs accordingly

# Test on file "short.vcf":
bash$: ./main.sh -v short.vcf -o Short_output -t
- Results table should write to "Short_output/results.tsv"

# Previous results:
The results for annotation of test_vcf_data.txt test_vcf_data.annotated.tsv (included)
