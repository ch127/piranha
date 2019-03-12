#!/bin/sh

##########################################################################################
#  __  o  __   __   __  |__   __                                                         #
# |__) | |  ' (__( |  ) |  ) (__(                                                        # 
# |                                                                                      #
#                                                                                        #
# File: RAxMLRunChecker.sh                                                               #
  VERSION="v1.2"                                                                         #
# Author: Justin C. Bagley                                                               #
# Date: Created by Justin Bagley on/before November 29, 2018.                            #
# Last update: March 6, 2019                                                             #
# Copyright (c) 2018-2019 Justin C. Bagley. All rights reserved.                         #
# Please report bugs to <bagleyj@umsl.edu>.                                              #
#                                                                                        #
# Description:                                                                           #
# SHELL SCRIPT THAT COUNTS NUMBER OF LOCI/PARTITIONS WITH COMPLETED RAxML RUNS DURING    #
# OR AFTER A RUN OF THE MAGNET PIPELINE, AND COLLATES RUN INFORMATION                    #
#                                                                                        #
##########################################################################################

## USAGE
## $ ./RAxMLRunChecker.sh <workingDir>
## $ ./shell/RAxMLRunChecker.sh <workingDir>
##
## Examples
## e.g. run in current working directory (cwd), where MAGNET pipeline has been run, or is
## currently running, by entering the following from the command line from within cwd:
## $ ./RAxMLRunChecker.sh .

if [[ "$1" == "-V" ]] || [[ "$1" == "--version" ]]; then
	echo "$(basename $0) $VERSION";
	exit
fi

############ Check for mandatory positional parameters
if [ $# -lt 1 ]; then
  echo "WARNING!  | $(date) |          Missing argument for working directory path. Quitting... "
  exit 1
fi
USER_SPEC_PATH="$1"


######################################## START ###########################################
############ Set workingDir
if [[ "$USER_SPEC_PATH" = "$(printf '%q\n' "$(pwd)")" ]] || [[ "$USER_SPEC_PATH" = "." ]]; then
	#MY_CWD=`pwd -P`
	MY_CWD="$(printf '%q\n' "$(pwd)" | sed 's/\\//g')"
	echo "INFO      | $(date) |          Setting working directory to:  "
	echo "$MY_CWD "
elif [[ "$USER_SPEC_PATH" != "$(printf '%q\n' "$(pwd)")" ]]; then
	if [[ "$USER_SPEC_PATH" = ".." ]] || [[ "$USER_SPEC_PATH" = "../" ]] || [[ "$USER_SPEC_PATH" = "..;" ]] || [[ "$USER_SPEC_PATH" = "../;" ]]; then
		cd ..;
		MY_CWD="$(printf '%q\n' "$(pwd)" | sed 's/\\//g')"
	else
		MY_CWD=$USER_SPEC_PATH
		echo "INFO      | $(date) |          Setting working directory to user-specified dir:  "	
		echo "$MY_CWD "
		cd "$MY_CWD"
	fi
else
	echo "WARNING!  | $(date) |          Null working directory path. Quitting... "
	exit 1
fi

	TAB=$(printf '\t'); 
	calc () {
	bc -l <<< "$@"
}

	echo "
RAxMLRunChecker"
	echo "-------------------------------------------------"
	echo "$(date)"

	MY_N_LOCI_FOLD="$(ls -d ./locus*/ | wc -l | sed 's/^[\ ]*//g')"
	MY_N_COMPLETED="$(ls ./locus*/RAxML_info.raxml_out | wc -l | sed 's/^[\ ]*//g')"
	MY_N_REMAINING="$(calc $MY_N_LOCI_FOLD - $MY_N_COMPLETED)"

	echo "Total no. RAxML runs: $TAB$TAB$MY_N_LOCI_FOLD "
	echo "No. completed RAxML runs: $TAB$MY_N_COMPLETED "
	echo "No. remaining RAxML runs:    $TAB$MY_N_REMAINING "

	if [[ -s ./completed_run_info.tmp ]]; then
		rm ./completed_run_info.tmp;
	fi
	if [[ -s ./completed_run_info.txt ]]; then
		rm ./completed_run_info.txt;
	fi
	if [[ -s ./remaining_run_info.tmp ]]; then
		rm ./remaining_run_info.tmp;
	fi
	if [[ -s ./remaining_run_info.txt ]]; then
		rm ./remaining_run_info.txt;
	fi

	echo "Saving raxml run info to file... "

	count=1
	echo "...  $count / $MY_N_LOCI_FOLD ..."
(
	for i in ./locus*/; do 
		MY_LOCUS="$(echo $i | sed 's/\.\///g; s/\///g; s/\ //g')"; 
		MY_COUNT_HUND_CHECK="$(calc $count / 100 | sed 's/^[0-9]*\.//g; s/^[0]\{1\}//g')"
		if [[ "$MY_COUNT_HUND_CHECK" -eq "0" ]]; then
			echo "...  $count / $MY_N_LOCI_FOLD ..."
		fi
		if [[ "$count" -eq "$MY_N_LOCI_FOLD" ]]; then
			echo "...  $MY_N_LOCI_FOLD / $MY_N_LOCI_FOLD ..."
		fi
		cd "$i"; 
			if [[ -s RAxML_bipartitions.raxml_out ]]; then 

				MY_ALIGN_PATT="$(grep -h '^Alignment\ Patterns\:\ ' ./RAxML_info.raxml_out | sed 's/^.*\:\ //g')";
				MY_SUBST_MODEL="$(grep -h '^Substitution\ Matrix\:\ ' ./RAxML_info.raxml_out | sed 's/^.*\:\ //g')";
				MY_OPTIM_LIKE="$(grep -h 'Final\ ML\ Optimization\ Likelihood\:\ ' ./RAxML_info.raxml_out | sed 's/^.*\:\ //g')";
				MY_ML_RUN_TIME="$(grep -h 'Overall\ execution\ time\ ' ./RAxML_info.raxml_out | sed 's/^Overall\ execution\ time\ [A-Za-z\ ]*\:\ //g; s/or\ .*//g')";
				
				echo "$count$TAB$MY_LOCUS$TAB$MY_ALIGN_PATT$TAB$MY_SUBST_MODEL$TAB$MY_OPTIM_LIKE$TAB$MY_ML_RUN_TIME$TAB complete" >> ../completed_run_info.tmp; 
			fi
			if [[ ! -s RAxML_bipartitions.raxml_out ]]; then 
				
				echo "$count$TAB$MY_LOCUS$TAB$MY_ALIGN_PATT$TAB$MY_SUBST_MODEL$TAB incomplete" >> ../remaining_run_info.tmp; 
				
			fi
		cd ..; 
		echo "$((count++))" > count.tmp
	done
)


	echo "No$TAB Locus$TAB No. Patterns$TAB Subst. Model$TAB Likelihood$TAB ML Run Time$TAB Status" > ./header.tmp;
	echo "No$TAB Locus$TAB No. Patterns$TAB Subst. Model$TAB Status" > ./rem_header.tmp;
	cat ./header.tmp ./completed_run_info.tmp > ./completed_run_info.txt;
	cat ./rem_header.tmp ./remaining_run_info.tmp > ./remaining_run_info.txt;

		# Check machine type and delete spaces from run info file using slightly different 
		# sed according to machine type:
		unameOut="$(uname -s)"
		case "${unameOut}" in
		    Linux*)     machine=Linux;;
		    Darwin*)    machine=Mac;;
		    CYGWIN*)    machine=Cygwin;;
		    MINGW*)     machine=MinGw;;
		    *)          machine="UNKNOWN:${unameOut}"
		esac
		# echo "INFO      | $(date) |          System: ${machine}"

		if [[ "${machine}" = "Mac" ]]; then
			sed -i '' 's/\ //g' ./completed_run_info.txt;
			sed -i '' 's/\ //g' ./remaining_run_info.txt;
		fi
		if [[ "${machine}" = "Linux" ]]; then
			sed -i 's/\ //g' ./completed_run_info.txt;
			sed -i 's/\ //g' ./remaining_run_info.txt;
		fi


	echo "Run summary info files:$TAB./completed_run_info.txt, ./remaining_run_info.txt  
"
	rm ./*.tmp;

#
#
#
######################################### END ############################################

exit 0
