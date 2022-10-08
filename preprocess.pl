#!/usr/bin/perl

########################################################################################################################################
### Author: Ryan L. Subaran
### Date: 10.06.2022
### Purpose: Separate total read info for multiallelic sites
### Syntax: perl preprocess.pl [input_vcf] [output_name]
########################################################################################################################################

chomp(@ARGV);
$input = $ARGV[0];
$output = $ARGV[1];

open(IN,"$input") or die "$input: $!";
while(<IN>) {
	chomp;
	$varlin = $_;
	# If not a VCF header row....
	if(substr($varlin,0,1) ne "#") {
		@vcfRow = split(" ",$varlin);
		# Step 1. If ID row is blank (i.e., is "."), assign var.SPID nomenclature
		if ($vcfRow[2] eq ".") { $vcfRow[2] = "var.$vcfRow[0]:$vcfRow[1]:$vcfRow[3]:$vcfRow[4]"; }
		# Step 2 - option A. If alt allele column has multiple variants ...
		if ($vcfRow[4] =~ m/\,/) {
			@altAlleles=split(/\,/,$vcfRow[4]);
			@info=split(/\;/,$vcfRow[7]);
			# ... split additional alleles and along with corresponding total read (TR) values up into different VCF rows
			for($i=0; $i<(scalar(@altAlleles)); $i++) {
				for ($j=0;$j<(scalar(@info));$j++) {
					if(substr($info[$j],0,3) eq "TR=") {
						$reads = $info[$j];
						$reads =~ s/TR=//g;
						@total_reads = split(/\,/,$reads);
						$new_total = "TR=" . $total_reads[$i];
						@split_info = @info;
						$split_info[$j] = $new_total;
						$new_info = join ";", @split_info;
						@new_row = @vcfRow;
						$new_row[7] = $new_info;
						$new_row[4] = $altAlleles[$i];
						$modified = join "\t", @new_row;
						push(@outVcf,"$modified\n");
					}
				}
			}
		}
		# Step 2 - option B. If alt allele column does NOT have multiple variants, do not split any rows or values
		else {
			$unmodified = join "\t", @vcfRow;
			push(@outVcf,"$unmodified\n"); 
		}
	} 
	# If row is a header row, leave as is
	else { push(@outVcf,"$varlin\n"); }
} close(IN);

open(OUT,">$output");
print OUT @outVcf;
close(OUT);
