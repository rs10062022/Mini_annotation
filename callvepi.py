#!/usr/local/bin/python3

########################################################################################################################################
### Author: Ryan L. Subaran
### Date: 10.06.2022
### Purpose: Call VEP REST API and pull read ratios and population frequency from VCF
### Syntax: python3 callvepi.py [input_vcf]
########################################################################################################################################

import json, requests, sys

# Extracts specified VCF row metadata from a VCF "INFO" list object
def parse_metadata(inlist,query):	
	searchTerm = query + "="
	m = [x for x in inlist if x.startswith(searchTerm)]
	r = m[0].split("=")[1]
	return r

vepOutput=[]
if len(sys.argv) > 1:
	try:
		vepInput=[]
		# Read in VCF
		with open(sys.argv[1], 'r') as vcfInput:
			for rows in vcfInput:
				inputRow = rows.replace("\t"," ").rstrip()
				vepInput.append(inputRow)

		# Request "POST vep/:species/region"
		server_ext = "https://rest.ensembl.org/vep/homo_sapiens/region"
		headers={ "Content-Type" : "application/json", "Accept" : "application/json"}
		data = json.dumps({ "variants" : vepInput })
		r = requests.post(server_ext, headers=headers, data=data)

		if not r.ok:
			r.raise_for_status()
			sys.exit()
		else:
			decoded = r.json()
			# For retrieved results...
			for i in decoded:
				if "input" in i:
					fx = ""
					clinsig = "NA"
					gnomad = 0.00
					papers = "NA"
					# Retrieve VCF locus info
					locus = "\t".join(i['input'].split(" ")[0:5])
					refAllele = i['input'].split(" ")[4]
					# Retrieve total counts, read counts, read proportion and allele frequency
					metaData = i['input'].split(" ")[7].split(";")
					total_counts = parse_metadata(metaData,'TC')
					total_reads = parse_metadata(metaData,'TR')
					percent_supporting = round(((int(total_reads) / int(total_counts)) *100), 2)
					readInfo = str(total_counts) + "\t" + str(total_reads) + "\t" + str(percent_supporting)

					# Retrieve variant effect for each Ensembl transcript				
					if "transcript_consequences" in i:
						for j in i['transcript_consequences']:
							if "gene_symbol" in j:
								fx = fx + j['gene_symbol'] + "(" + j['transcript_id'] + "):" + ';'.join(j['consequence_terms']) + "|"
							else:
								fx = fx + "gene_not_found|"
					# Retrieve any gnomAD freqs, ClinVar interpretations and PMIDs
					if "colocated_variants" in i:
						for k in i['colocated_variants']:
							if "clin_sig" in k:
								clinsig = ';'.join(k['clin_sig'])
							if ("frequencies" in k) and (refAllele in k['frequencies']) and ("gnomade" in k['frequencies'][refAllele]):
								gnomad = k['frequencies'][refAllele]['gnomade']
							if "pubmed" in k:
								papers = str(k['pubmed']).replace(", ","|")
					# Collate summary
					outRow = locus + "\t" + readInfo + "\t" + str(gnomad) + "\t" + fx[:-1] + "\t" + clinsig + "\t" + papers
					vepOutput.append(outRow)
		# Write results out to file
		outputFilename = sys.argv[1] + ".annotated.tsv"
		outputTable="\n".join(vepOutput)
		with open(outputFilename, 'w') as g:
			for lin in outputTable:
				g.write(lin)
	except FileNotFoundError:
		print("File " + sys.argv[1] + " not found")
else:
	print("must enter arguments")
	exit()
