#!/bin/sh

##########################################################################################
#  __  o  __   __   __  |__   __                                                         #
# |__) | |  ' (__( |  ) |  ) (__(                                                        # 
# |                                                                                      #
#                          vcfSubsampler v0.1.0, September 2017                          #
#  SCRIPT THAT USES A LIST FILE TO SUBSAMPLE A VCF FILE SO THAT IT ONLY CONTAINS SNPs    #
#  IN THE LIST                                                                           #
#  Copyright ©2017 Justinc C. Bagley. For further information, see README and license    #
#  available in the PIrANHA repository (https://github.com/justincbagley/PIrANHA/). Last #
#  update: September 28, 2017. For questions, please email bagleyj@umsl.edu.             #
##########################################################################################

############ SCRIPT OPTIONS
## OPTION DEFAULTS ##
MY_INPUT_VCF=input.vcf
MY_SNPS_FILE=snps.txt
MY_OUTPUT_VCF_FILE=subsample
DELETE_ORIG_VCF=0

############ CREATE USAGE & HELP TEXTS
Usage="Usage: $(basename "$0") [Help: -h help] [Options: -s o d] inputVCFFile
 ## Help:
  -h   help text (also: -help)

 ## Options:
  -s snpsFile (def: $MY_SNPS_FILE) file listing, one per line, names of SNPs that the user 
     wishes to keep, corresponding to 'GENE' column of the input .vcf file
  -o output (def: $MY_OUTPUT_FILE) output vcf file basename (root; not including extension)
  -d deleteOrig (def: 0=no, 1=yes) specifies whether or not to delete the original input
     .vcf file

 CITATION
 Bagley, J.C. 2017. PIrANHA. GitHub package, Available at: 
	<http://github.com/justincbagley/PIrANHA>.
 or
 Bagley, J.C. 2017. PIrANHA. [Data set] Zenodo, Available at: 
	<http://doi.org/10.5281/zenodo.596766>.
 or
 Bagley, J.C. 2017. justincbagley/PIrANHA. GitHub package, Available at: 
	<http://doi.org/10.5281/zenodo.596766>.
"

if [[ "$1" == "-h" ]] || [[ "$1" == "-help" ]]; then
	echo "$Usage"
	exit
fi

############ PARSE THE OPTIONS
while getopts 's:o:d:' opt ; do
  case $opt in

## vcfSubsampler options:
    s) MY_SNPS_FILE=$OPTARG ;;
    o) MY_OUTPUT_FILE=$OPTARG ;;
    d) DELETE_ORIG_VCF=$OPTARG ;;

## Missing and illegal options:
    :) printf "Missing argument for -%s\n" "$OPTARG" >&2
       echo "$Usage" >&2
       exit 1 ;;
   \?) printf "Illegal option: -%s\n" "$OPTARG" >&2
       echo "$Usage" >&2
       exit 1 ;;
  esac
done

############ SKIP OVER THE PROCESSED OPTIONS
shift $((OPTIND-1)) 
# Check for mandatory positional parameters
if [ $# -lt 1 ]; then
echo "$Usage"
  exit 1
fi
## Make input file a mandatory parameter:
MY_INPUT_VCF="$1"


######################################## START ###########################################

##--Subsample input .vcf file using snps list:
	while read j; do 
		grep -h "$(echo $j)" ./"$MY_INPUT_VCF" >> "$MY_OUTPUT_VCF_FILE".tmp; 
	done < ./"$MY_SNPS_FILE"


##--Add header from original .vcf to the new, subsampled vcf file:
	grep -h "\#" ./"$MY_INPUT_VCF" > ./header.tmp

	cat ./header.tmp "$MY_OUTPUT_VCF_FILE".tmp > "$MY_OUTPUT_VCF_FILE".vcf; 


##--Cleanup temporary files:
	rm ./*.tmp

##--Final cleanup:
##--Delete the original .vcf file if user has specified to do so:
	if [[ "$DELETE_ORIG_VCF" = 0 ]]; then
		echo ""
	elif [[ "$DELETE_ORIG_VCF" = 1 ]]; then
		rm ./"$MY_INPUT_VCF"
	fi

#
#
#
######################################### END ############################################

exit 0
