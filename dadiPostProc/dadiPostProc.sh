#!/bin/sh

##########################################################################################
#  __  o  __   __   __  |__   __                                                         #
# |__) | |  ' (__( |  ) |  ) (__(                                                        # 
# |                                                                                      #
#                                                                                        #
# File: dadiPostProc.sh                                                                  #
  VERSION="v0.1.3"                                                                       #
# Author: Justin C. Bagley                                                               #
# Date: Created by Justin Bagley on Tue, 16 May 2017 08:17:15 -0400.                     #
# Last update: March 7, 2019                                                             #
# Copyright (c) 2017-2019 Justin C. Bagley. All rights reserved.                         #
# Please report bugs to <bagleyj@umsl.edu>.                                              #
#                                                                                        #
# Description:                                                                           #
# SHELL SCRIPT FOR POST-PROCESSING OUTPUT FROM ONE OR MULTIPLE ∂a∂i RUNS (IDEALLY RUN    #
# USING dadiRunner.sh), INCLUDING COLLATION OF BEST-FIT PARAMETER ESTIMATES, COMPOSITE   #
# LIKELIHOODS, AND OPTIMAL THETA VALUES                                                  #
#                                                                                        #
##########################################################################################

############ SCRIPT OPTIONS
## OPTION DEFAULTS ##
MY_NUM_INDEP_RUNS=10
MY_LOWER_MOD_NUM=1
MY_UPPER_MOD_NUM=10

############ CREATE USAGE & HELP TEXTS
USAGE="Usage: $(basename $0) [Help: -h help H Help] [Options: -n l u V --version] [stdin:] <workingDir> 
 ## Help:
  -h   help text (also: --help) echo this help text and exit
  -H   verbose help text (also: -Help) echo verbose help text and exit

 ## Options:
  -n   nRuns (def: $MY_NUM_INDEP_RUNS) number of independent ∂a∂i runs per model (.py file)
  -l   lowerModNum (def: $MY_LOWER_MOD_NUM) lower number in model number range
  -u   upperModNum (def: $MY_UPPER_MOD_NUM) upper number in model number range
  -V   version (also: --version) echo version and exit
  
 OVERVIEW
 Automates post-processing and organizing results from multiple ∂a∂i (Gutenkunst et al. 2009)
 runs, ideally conducted using the dadiRunner script in PIrANHA (see PIrANHA README for  
 additional details), although this is not required. Expects run results organized into 
 separate sub-folders of current working directory, with sub-folder names containing model
 name. Model names should be of form 'M1' to 'Mx', where x is the number of models. Multiple
 runs (e.g. 10) would have been run on the .py file for each model. Results could be on
 remote supercomputer (i.e. following dadiRunner), or your local machine.

 CITATION
 Bagley, J.C. 2019. PIrANHA v0.1.7. GitHub repository, Available at: 
	<https://github.com/justincbagley/PIrANHA>.

 REFERENCES
 Gutenkunst RN, Hernandez RD, Williamson SH, Bustamante CD (2009) Inferring the joint 
 	demographic history of multiple populations from multidimensional SNP frequency data. 
 	PLOS Genetics 5(10): e1000695

Created by Justin Bagley on Tue, 16 May 2017 08:17:15 -0400.
Copyright (c) 2017-2019 Justin C. Bagley. All rights reserved.
"

VERBOSE_USAGE="Usage: $(basename $0) [Help: -h help H Help] [Options: -n l u V --version] [stdin:] <workingDir> 
 ## Help:
  -h   help text (also: --help) echo this help text and exit
  -H   verbose help text (also: -Help) echo verbose help text and exit

 ## Options:
  -n   nRuns (def: $MY_NUM_INDEP_RUNS) number of independent ∂a∂i runs per model (.py file)
  -l   lowerModNum (def: $MY_LOWER_MOD_NUM) lower number in model number range
  -u   upperModNum (def: $MY_UPPER_MOD_NUM) upper number in model number range
  -V   version (also: --version) echo version and exit

 OVERVIEW
 Automates post-processing and organizing results from multiple ∂a∂i (Gutenkunst et al. 2009)
 runs, ideally conducted using the dadiRunner script in PIrANHA (see PIrANHA README for  
 additional details), although this is not required. Expects run results organized into 
 separate sub-folders of current working directory, with sub-folder names containing model
 name. Model names should be of form 'M1' to 'Mx', where x is the number of models. Multiple
 runs (e.g. 10) would have been conducted in ∂a∂i on the .py file for each model. Results could 
 be on remote supercomputer (i.e. following dadiRunner), or your local machine.

 DETAILS
 The -n flag sets the number of independent ∂a∂i runs to be submitted to the supercomputer
 for each model specified in a .py file in the current working directory. The default is 10
 runs.
 
 The -l flage sets the number for the lower value in the range of model numbers, e.g. a
 value of 1 being the default, used for a model set with ten models named M1 to M10.
 
 The -u flag sets the number for the upper value in the range of model numbers, e.g. a value
 of 10 being the default, used for a model set with ten models named M1 to M10.
 
		## Usage examples: 
		$0 .				## Using the defaults.
		$0 -n 10 -l 1 -u 10 .		## A case equal to the defaults.
		$0 -n 5 -l 2 -u 7 .		## Illustrating that dadiPostProc accomodates model number
								## ranges starting from values other than 1.

 CITATION
 Bagley, J.C. 2019. PIrANHA v0.1.7. GitHub repository, Available at: 
	<https://github.com/justincbagley/PIrANHA>.

 REFERENCES
 Gutenkunst RN, Hernandez RD, Williamson SH, Bustamante CD (2009) Inferring the joint 
 	demographic history of multiple populations from multidimensional SNP frequency data. 
 	PLOS Genetics 5(10): e1000695

Created by Justin Bagley on Tue, 16 May 2017 08:17:15 -0400.
Copyright (c) 2017-2019 Justin C. Bagley. All rights reserved.
"

if [[ "$1" == "-h" ]] || [[ "$1" == "-help" ]]; then
	echo "$USAGE"
	exit
fi

if [[ "$1" == "-H" ]] || [[ "$1" == "-Help" ]]; then
	echo "$VERBOSE_USAGE"
	exit
fi

if [[ "$1" == "-V" ]] || [[ "$1" == "--version" ]]; then
	echo "$(basename $0) $VERSION";
	exit
fi

############ PARSE THE OPTIONS
while getopts 'n:l:u:' opt ; do
  case $opt in
## ∂a∂i post-processing options:
    n) MY_NUM_INDEP_RUNS=$OPTARG ;;
    l) MY_LOWER_MOD_NUM=$OPTARG ;;
    u) MY_UPPER_MOD_NUM=$OPTARG ;;
## Missing and illegal options:
    :) printf "Missing argument for -%s\n" "$OPTARG" >&2
       echo "$USAGE" >&2
       exit 1 ;;
   \?) printf "Illegal option: -%s\n" "$OPTARG" >&2
       echo "$USAGE" >&2
       exit 1 ;;
  esac
done

############ SKIP OVER THE PROCESSED OPTIONS
shift $((OPTIND-1)) 
# Check for mandatory positional parameters
if [ $# -lt 1 ]; then
echo "$USAGE"
  exit 1
fi
USER_SPEC_PATH="$1"

echo "
dadiPostProc v0.1.3, March 2019  (part of PIrANHA v0.1.7+)  "
echo "Copyright (c) 2017-2019 Justin C. Bagley. All rights reserved.  "
echo "------------------------------------------------------------------------------------------"
######################################## START ###########################################
echo "INFO      | $(date) | Starting dadiPostProc analysis... "
echo "INFO      | $(date) | Step #1: Set up workspace, detect one or multiple ∂a∂i run subfolders in current directory. "
echo "INFO      | $(date) |          Setting user-specified path to: "
echo "$USER_SPEC_PATH "	
	calc () { 
		bc -l <<< "$@" 
}

if [[ "$(find . -type d | wc -l)" = "1" ]]; then
	MY_MULTIRUN_DIR_SWITCH=FALSE ;
	## Script run inside folder corresponding to 1 single run.
elif [[ "$(find . -type d | wc -l)" -gt "1" ]]; then
	MY_MULTIRUN_DIR_SWITCH=TRUE ;
	## Script run inside working directory containing multiple sub-folders, assumed to correspond to ∂a∂i run folders (1 per run).
fi


echo "INFO      | $(date) | Step #2: Post-processing output file: Extract & save best-fit parameters, composite likelihood, and "
echo "INFO      | $(date) |          optimal theta estimate (if present) to a single file with same basename as the run folder. "


## if MY_MULTIRUN_DIR_SWITCH=FALSE, ...
## DO SINGLE RUN ANALYSIS HERE
if [[ "$MY_MULTIRUN_DIR_SWITCH" = "FALSE" ]]; then

	MY_SINGLE_DADI_RUN_DIR="$(find . -type d | tail -n1 | sed 's/$/\//g')";
	i="$MY_SINGLE_DADI_RUN_DIR";
	cd "$i";

		MY_FOLDER_BASENAME="$(echo ${i} | sed 's/^.\///g; s/\///g')";
		echo $MY_FOLDER_BASENAME;
#			
		### CHECK FOR OUTPUT FILE.
		if [[ -s $(find . -name "*.out" -type f) ]]; then
			MY_OUTPUT_FILENAME="$(find . -name "*.out" -type f)";
			MY_OUTPUT_BASENAME="$(find . -name "*.out" -type f | sed 's/^\.\///g; s/\.out//g')";
		elif [[ -s $(find . -name "*.out.txt" -type f) ]]; then
			MY_OUTPUT_FILENAME="$(find . -name "*.out.txt" -type f)";
			MY_OUTPUT_BASENAME="$(find . -name "*.out.txt" -type f | sed 's/^\.\///g; s/\.out\.txt//g')";
		fi
#			
#
		### EXTRACT BEST-FIT MODEL PARAMETER ESTIMATES: 
		grep -n "Best\-fit\ parameters:" $MY_OUTPUT_FILENAME > "${MY_OUTPUT_BASENAME}"_BFP.tmp;
		##--Get starting line no. for BFPs:
		MY_BFP_START_LN_NUM="$(sed 's/\:.*$//g' ${MY_OUTPUT_BASENAME}_BFP.tmp)";
		MY_BFP_CLOSEBRACK_TEST="$(grep -h "\]" ${MY_OUTPUT_BASENAME}_BFP.tmp | wc -l)";
#
			if [[ "$MY_BFP_CLOSEBRACK_TEST" = "0" ]]; then

				##--Clean up only to tab-separated BFP estimates:
				sed -i '' $'s/^[0-9]*\:.*\ \[//g; s/\]//g; s/\ /\t/g; s/\t\t\t/\t/g; s/\t\t/\t/g; s/^\t//g' ./"${MY_OUTPUT_BASENAME}"_BFP.tmp;
				sed -i '' 's/^$//g' ./"${MY_OUTPUT_BASENAME}"_BFP.tmp;

			elif [[ "$MY_BFP_CLOSEBRACK_TEST" != "0" ]]; then

				##--Get final line no. for multi-line BFPs:
				MY_BFP_FINISH_LN_NUM="$(grep -n '\ .*\]' $MY_OUTPUT_FILENAME | sed 's/\:.*$//g' | tail -n1)";

				##--Use sed to extract multi-line BFPs lines to tmp file using line nos:
				sed -n "$MY_BFP_START_LN_NUM","$MY_BFP_FINISH_LN_NUM"p "$MY_OUTPUT_FILENAME" > ./"${MY_OUTPUT_BASENAME}"_multiline_BFP.tmp;

				##--Convert BFPs to single line with numbers in tab-separated format, and 
				##--remove "_BFP.tmp" and "_multiline_BFP.tmp" files created above:
				rm ./"${MY_OUTPUT_BASENAME}"_BFP.tmp;
				perl -pe 's/\n/\ /g; s/^.*\:\ \[\ //g; s/\ /\t/g; s/\t\t\t/\t/g; s/\t\t/\t/g; s/^\t//g; s/\]//g' ./"${MY_OUTPUT_BASENAME}"_multiline_BFP.tmp | perl -pe 's/\t$//g' > ./"${MY_OUTPUT_BASENAME}"_BFP.tmp;
				rm ./"${MY_OUTPUT_BASENAME}"_multiline_BFP.tmp;
			fi
#
#
		### EXTRACT MAXIMUM COMPOSITE LIKELIHOOD ESTIMATE FOR THE RUN: 
		grep -h "likelihood\:\ " "$MY_OUTPUT_FILENAME" | sed 's/^.*\:\ //g; s/\ //g' > ./"${MY_OUTPUT_BASENAME}"_MLCL.tmp;
###				perl -pi -e 'chomp if eof' ./"${MY_OUTPUT_BASENAME}"_MLCL.tmp;
#
#
		### EXTRACT OPTIMAL VALUE OF THETA AS ESTIMATED BASED ON THE RUN: 
		grep -h "theta\:\ " "$MY_OUTPUT_FILENAME" |  sed 's/^.*\:\ //g; s/\ //g' > ./"${MY_OUTPUT_BASENAME}"_theta.tmp;
###				perl -pi -e 'chomp if eof' ./"${MY_OUTPUT_BASENAME}"_theta.tmp;
#
#
		### PASTE RESULTS IN TMP FILES TOGETHER INTO A SINGLE FILE, THEN COPY RESULTS SUMMARY FOR RUN TO WORKING DIR.
		paste ./"${MY_OUTPUT_BASENAME}"_MLCL.tmp ./"${MY_OUTPUT_BASENAME}"_BFP.tmp ./"${MY_OUTPUT_BASENAME}"_theta.tmp > ./"${MY_OUTPUT_BASENAME}"_results.txt ;
###				perl -pi -e 'chomp if eof' ./"${MY_OUTPUT_BASENAME}"_results.txt;

		##--Check for "runs_output" output dir and make it if needed; then copy final 
		##--results summary file with run folder prefix to "runs_output" dir in working 
		##--dir (one dir up):
		if [ ! -d "../runs_output" ]; then
			mkdir ../runs_output/;
		fi
#				
		cp ./"${MY_OUTPUT_BASENAME}"_results.txt ../runs_output/;

		##--Clean up temporary files:
		rm ./*.tmp;
	cd ..;
fi


######
## if MY_MULTIRUN_DIR_SWITCH=TRUE, ...
## DO BIG LOOP BELOW:
if [[ "$MY_MULTIRUN_DIR_SWITCH" = "TRUE" ]]; then


###### Use a big loop through the run sub-folders in pwd to extract and organize output
##--from multiple ∂a∂i runs. Here, we do several things within each run sub-folder. 1) We 
##--first get details about the folder name & output filename, while accommodating 2 possible 
##--output filename extensions. 2) Second, we grep and sed out details from the output file.
##--In particular, we 3) test whether the best-fit model parameters are are contained on a
##--single line, and if so we sed out anything we don't want and save the best params to a
##--"_BFP.tmp" file; if not, count number/numbers of lines from start of best-fit params 
##--reporting/line til next closing bracket encountered and then organize those lines into
##--a single line and extract results. We also extract information about 4) the maximum 
##--composite likelihood and 5) the optimal value of theta for the run, for the given model 
##--(at that point in the loop). Data points under operations #4 and #5 above are always
##--on a single line, thus easy to extract with regex/sed.
	(
		for i in ./*/; do
			cd "$i"; 
				MY_FOLDER_BASENAME="$(echo ${i} | sed 's/^.\///g; s/\///g')";
				echo $MY_FOLDER_BASENAME;
#			
				### CHECK FOR OUTPUT FILE.
				if [[ -s $(find . -name "*.out" -type f) ]]; then
					MY_OUTPUT_FILENAME="$(find . -name "*.out" -type f)";
					MY_OUTPUT_BASENAME="$(find . -name "*.out" -type f | sed 's/^\.\///g; s/\.out//g')";
				elif [[ -s $(find . -name "*.out.txt" -type f) ]]; then
					MY_OUTPUT_FILENAME="$(find . -name "*.out.txt" -type f)";
					MY_OUTPUT_BASENAME="$(find . -name "*.out.txt" -type f | sed 's/^\.\///g; s/\.out\.txt//g')";
				fi
#			
#
				### EXTRACT BEST-FIT MODEL PARAMETER ESTIMATES: 
				grep -n "Best\-fit\ parameters:" $MY_OUTPUT_FILENAME > "${MY_OUTPUT_BASENAME}"_BFP.tmp;
				##--Get starting line no. for BFPs:
				MY_BFP_START_LN_NUM="$(sed 's/\:.*$//g' ${MY_OUTPUT_BASENAME}_BFP.tmp)";
				MY_BFP_CLOSEBRACK_TEST="$(grep -h "\]" ${MY_OUTPUT_BASENAME}_BFP.tmp | wc -l)";
#
					if [[ "$MY_BFP_CLOSEBRACK_TEST" = "0" ]]; then

						##--Clean up only to tab-separated BFP estimates:
						sed -i '' $'s/^[0-9]*\:.*\ \[//g; s/\]//g; s/\ /\t/g; s/\t\t\t/\t/g; s/\t\t/\t/g; s/^\t//g' ./"${MY_OUTPUT_BASENAME}"_BFP.tmp;
						sed -i '' 's/^$//g' ./"${MY_OUTPUT_BASENAME}"_BFP.tmp;

					elif [[ "$MY_BFP_CLOSEBRACK_TEST" != "0" ]]; then

						##--Get final line no. for multi-line BFPs:
						MY_BFP_FINISH_LN_NUM="$(grep -n '\ .*\]' $MY_OUTPUT_FILENAME | sed 's/\:.*$//g' | tail -n1)";

						##--Use sed to extract multi-line BFPs lines to tmp file using line nos:
						sed -n "$MY_BFP_START_LN_NUM","$MY_BFP_FINISH_LN_NUM"p "$MY_OUTPUT_FILENAME" > ./"${MY_OUTPUT_BASENAME}"_multiline_BFP.tmp;

						##--Convert BFPs to single line with numbers in tab-separated format, and 
						##--remove "_BFP.tmp" and "_multiline_BFP.tmp" files created above:
						rm ./"${MY_OUTPUT_BASENAME}"_BFP.tmp;
						perl -pe 's/\n/\ /g; s/^.*\:\ \[\ //g; s/\ /\t/g; s/\t\t\t/\t/g; s/\t\t/\t/g; s/^\t//g; s/\]//g' ./"${MY_OUTPUT_BASENAME}"_multiline_BFP.tmp | perl -pe 's/\t$//g' > ./"${MY_OUTPUT_BASENAME}"_BFP.tmp;
						rm ./"${MY_OUTPUT_BASENAME}"_multiline_BFP.tmp;
					fi
#
#
				### EXTRACT MAXIMUM COMPOSITE LIKELIHOOD ESTIMATE FOR THE RUN: 
				grep -h "likelihood\:\ " "$MY_OUTPUT_FILENAME" | sed 's/^.*\:\ //g; s/\ //g' > ./"${MY_OUTPUT_BASENAME}"_MLCL.tmp;
###				perl -pi -e 'chomp if eof' ./"${MY_OUTPUT_BASENAME}"_MLCL.tmp;
#
#
				### EXTRACT OPTIMAL VALUE OF THETA AS ESTIMATED BASED ON THE RUN: 
				grep -h "theta\:\ " "$MY_OUTPUT_FILENAME" |  sed 's/^.*\:\ //g; s/\ //g' > ./"${MY_OUTPUT_BASENAME}"_theta.tmp;
###				perl -pi -e 'chomp if eof' ./"${MY_OUTPUT_BASENAME}"_theta.tmp;
#
#
				### PASTE RESULTS IN TMP FILES TOGETHER INTO A SINGLE FILE, THEN COPY RESULTS SUMMARY FOR RUN TO WORKING DIR.
				paste ./"${MY_OUTPUT_BASENAME}"_MLCL.tmp ./"${MY_OUTPUT_BASENAME}"_BFP.tmp ./"${MY_OUTPUT_BASENAME}"_theta.tmp > ./"${MY_OUTPUT_BASENAME}"_results.txt ;
###				perl -pi -e 'chomp if eof' ./"${MY_OUTPUT_BASENAME}"_results.txt;

				##--Check for "runs_output" output dir and make it if needed; then copy final 
				##--results summary file with run folder prefix to "runs_output" dir in working 
				##--dir (one dir up):
				if [ ! -d "../runs_output" ]; then
					mkdir ../runs_output/;
				fi
#				
				cp ./"${MY_OUTPUT_BASENAME}"_results.txt ../runs_output/;

				##--Clean up temporary files:
				rm ./*.tmp;
			cd ..;
		done
	)


echo "INFO      | $(date) | Step #3: For multirun case, collate results from files (in ./output/ dir) from independent runs of the "
echo "INFO      | $(date) |          same model, looking for separate M1 (model 1) run files containing filenames prefixed with 'M1'. "
###### Here, recursively cat results from all files with the same model names in their prefixes 
##--(cycling through M1 to Mx, where x is the total number of models) into separate summaries 
##--for each model (e.g. one file for 10 M1 runs, a second file for 10 M2 runs, and so on).
	mkdir final_output/;
	(
		for (( j="MY_LOWER_MOD_NUM"; j<="MY_UPPER_MOD_NUM"; j++ )); do
			cat ./runs_output/*M"$j"*_results.txt >> ./final_output/M"$j"_resultsSummary.txt ;
		done
	)

	cd ./final_output/;
		cat ./*Summary.txt > All_Models_M"$MY_LOWER_MOD_NUM"_M"$MY_UPPER_MOD_NUM"_resultsSummary.txt ;
	cd ..;

fi
######


#echo "INFO      | $(date) | Done post-processing results from one or multiple ∂a∂i runs using the dadiPostProc utility of PIrANHA. "
#echo "Bye.
#"
echo "------------------------------------------------------------------------------------------
"
#
#
#
######################################### END ############################################

exit 0
