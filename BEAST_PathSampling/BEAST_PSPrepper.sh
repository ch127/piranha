#!/bin/sh

##########################################################################################
#  __  o  __   __   __  |__   __                                                         #
# |__) | |  ' (__( |  ) |  ) (__(                                                        # 
# |                                                                                      #
#                          BEAST_PSPrepper v0.1.1, August 2017                           #
#  SHELL SCRIPT FOR AUTOMATING EDITING OF BEAST XML INPUT FILES TO RUN PATH SAMPLING     #
#  USING BEAST v2+ PATHSAMPLER                                                           #
#  Copyright ©2017 Justinc C. Bagley. For further information, see README and license    #
#  available in the PIrANHA repository (https://github.com/justincbagley/PIrANHA/). Last #
#  update: August 10, 2017. For questions, please email bagleyj@umsl.edu.                #
##########################################################################################

############ SCRIPT OPTIONS
## OPTION DEFAULTS ##
CHAIN_LENGTH=100000
ALPHA_VALUE=0.3
ROOT_DIR=/tmp
BURN_IN_PERCENT=50
PRE_BURN_IN=100000
DELETE_OLDLOGS=true
NUM_PS_STEPS=10

############ CREATE USAGE & HELP TEXTS
Usage="Usage: $(basename "$0") [Help: -h help] [Options: -l a r b p d n] inputXMLFile
 ## Help:
  -h   help text (also: -help)

 ## Options:
  -l chainLength (length of MCMC chin for each path sampling step; default=100000)
  -a alpha (shape parameter of the Beta distribution; default=0.3)
  -r rootdir (absolute path to root directory where files for each step will be kept; default=/tmp)
  -b burnInPercentage (percent of samples discarded as burnin; default=50, same as in BEAST)
  -p preBurnin (number of samples discarded from first step of analysis; default=100000)
  -d deleteOldLogs (logical variable specifying whether or not to delete previous logs that 
     may be present in the rootdir)
  -n nrOfSteps (total number of path sampling steps for analysis)

 OVERVIEW
 This script works by (STEP #1) setting up user options/input, and then (STEP #2) using a 
 function to go through the XML file or files (should be the only XMLs in working dir) and 
 edit them for path sampling. For downstream processing and queuing, XML files should end
 in 'run.xml' (e.g. 'ULN_PS100_run.xml').

 The script expects as inputXMLFile one of the following: (i) one XML file, created and
 formatted for BEAST v2++ using BEAUti v2++ (e.g. latest release is v2.4.5), and present in
 the current working directory (pwd); or (ii) the code 'multiXML', which tells the script
 to use a loop to process multiple XML input files present in the current working directory. 
 Regarding other inputs/flags, the rootdir variable requires an absolute path, with opening 
 and closing forward slashes. If no rootdir is passed using the -r flag, then the user will
 be asked (yes/no) if the default '/tmp' path is acceptable. If no, then the user will be 
 prompted to provide a rootdir path on their local machine or supercomputing account, and 
 if nothing is provided then rootdir will be left at '/tmp'.

 Option defaults for path sampling parameters may or may not be ideal for your purposes. 
 For example, many more than 10 steps will likely be required to obtain good path sampling
 results, especially for larger or more complex data files. The author has found that setting 
 chainLength to 1 million and setting the nrOfSteps parameter to 100 has produced good results 
 for a range of XMLs he uses in his research (e.g. Bagley et al. 2016). Also, by default, the 
 alpha parameter used to space out the path sampling steps is set to 0.3, a value that Xie 
 et al. (2011) found to be near optimal for simulated data and a phylogenetic example, and
 thus suggested was 'generally optimal'. However, recent papers have published analyses using
 alpha values as high as 0.4. The new -a flag lets the user change this value in the XMLs.

 CITATION
 Bagley, J.C. 2017. PIrANHA v0.1.4. GitHub repository, Available at: 
	<https://github.com/justincbagley/PIrANHA>.

 REFERENCES
 Bagley JC, Matamoros W, McMahan C, Chakrabarty P, Johnson JB (2016) Phylogeography and 
 	species delimitation in convict cichlids (Cichlidae: Amatitlania): implications for 
 	taxonomy and Plio–Pleistocene evolutionary history in Central America. Biological Journal
  	of the Linnean Society. Early View on BJLS website. doi: 10.1111/bij.12845.

 Xie W, Lewis PO, Fan Y, Kuo L, Chen MH. 2011. Improving marginal likelihood estimation for 
 	Bayesian phylogenetic model selection. Systematic Biology 60: 150–160.
"

if [[ "$1" == "-h" ]] || [[ "$1" == "-help" ]]; then
	echo "$Usage"
	exit
fi

############ PARSE THE OPTIONS
while getopts 'l:a:r:b:p:d:n:' opt ; do
  case $opt in

## Path sampling options:
    l) CHAIN_LENGTH=$OPTARG ;;
    a) ALPHA_VALUE=$OPTARG ;;
    r) ROOT_DIR=$OPTARG ;;
    b) BURN_IN_PERCENT=$OPTARG ;;
    p) PRE_BURN_IN=$OPTARG ;;
    d) DELETE_OLDLOGS=$OPTARG ;;
    n) NUM_PS_STEPS=$OPTARG ;;

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
USER_SPEC_PATH="$1"

echo "INFO      | $(date) |          Setting user-specified path to: "
echo "$USER_SPEC_PATH "	


echo "
##########################################################################################
#                          BEAST_PSPrepper v0.1.1, August 2017                           #
##########################################################################################
"
######################################## START ###########################################
echo "INFO      | $(date) | Starting BEAST_PSPrepper pipeline... "
echo "INFO      | $(date) | STEP #1: SETUP. "
## Make input file a mandatory parameter:
	MY_INPUTXMLFILE_VAR="$1"
## Prep useful stuff:
	CR=$(printf '\r')
	calc () {
	   	bc -l <<< "$@"
	}

##--PRE-EMPTIVELY FIX issues with echoing shell text containing dollar signs and minus signs
## (i.e. within the run element tmp file created in the editXMLFiles function below):
	RUNELEM_DIR_VAR=$(echo "\$(dir)")
	RUNELEM_CP_FLAG=$(echo "-cp")
	RUNELEM_JAVA_CLASS=$(echo "\$(java.class.path)")
	RUNELEM_RESUME=$(echo "\$(resume/overwrite)") 
	RUNELEM_JAVA_FLAG=$(echo "-java")
	RUNELEM_SEED_FLAG=$(echo "-seed")
	RUNELEM_SEED_VAR=$(echo "\$(seed)")

echo "INFO      | $(date) |          Checking rootdir variable..."
if [[ "$ROOT_DIR" = "/tmp" ]]; then
echo "WARNING!  | $(date) |          ** The rootdir variable has NOT been changed from its default value. Respond to the following prompts: ** "
	read -p "                                                     Is /tmp an acceptable root directory where path steps can be saved? (y/n) : " TMP_DIR_TEST
	echo ""
	if [[ "$TMP_DIR_TEST" = "y" ]]; then 
		echo "INFO      | $(date) |          Moving forward with /tmp as rootdir... " 
	fi
	if [[ "$TMP_DIR_TEST" = "n" ]]; then
		read -p "                                                     Enter the absolute path to a more suitable root directory (on local machine or supercomputer) : " ROOT_DIR
		echo ""
	fi
	if [[ "$ROOT_DIR" = "" ]]; then 
		ROOT_DIR=/tmp
	fi	
fi


############ MAKE AND RUN EDIT FUNCTION
echo "INFO      | $(date) | STEP #2: MAKE AND RUN FUNCTION TO EDIT XML FILES SO THEY HAVE PS CODE... "

	## Functions and commands are split up depending on whether a single or multiple XMLs 
	## were specified for manipulation, using if-the-else-fi conditional flow control:
	if [[ $MY_INPUTXMLFILE_VAR = "multiXML" ]]; then
		echo "INFO      | $(date) |          Multiple BEAST input XML files present. Adding path sampling code to XMLs... "

###### SECTION A. MAKE AND RUN FUNCTION WITH CODE FOR MANIPULATING MULTIPLE XML FILES:
	editXMLFiles () {
	count=0

	MY_XML_FILES=./*.xml		## Assign multiple BEAST XML input file(s) in run directory to variable using extension with wildcard.

		(
			for i in $MY_XML_FILES; do
				BASENAME="$(ls ${i} | sed 's/\.xml$//g')"							## Get basename of XML file, for later use.
				sed 's/\<run\ /\<mcmc\ /g; s/\<\/run\>/\<\/mcmc\>\ '$CR'\<\/run\>/g' $i > edit1.xml		## Make temporary edited file containing some, but not all, of the text edits needed for path sampling (i.e. renaming the original run element to mcmc).

				NLINES_TO_MCMCELEM=$(sed -n '/\<mcmc\ /{=; q;}' edit1.xml)			## These three lines get pertinent information about the number of lines in the edited XML, which is used below
				MY_HEADSTOP="$(calc $NLINES_TO_MCMCELEM-1)"							## in sed lines creating new tmp files containing the top and bottom portions of the edited XML. The edit1, xmlTop,
				NLINES_TOTAL=$(wc -l edit1.xml | sed 's/\ edit1\.xml//')			## and xmlBottom tmp files are concatenated together later with the new, custom run element tmp file created below
																					## to create the final XML with path sampling code.
					sed -n 1,"$MY_HEADSTOP"p edit1.xml > xmlTop.tmp
					sed -n "$NLINES_TO_MCMCELEM","$NLINES_TOTAL"p edit1.xml > xmlBottom.tmp
					
echo "<run spec='beast.inference.PathSampler'
chainLength='$CHAIN_LENGTH'
alpha='$ALPHA_VALUE'
rootdir='$ROOT_DIR$BASENAME/'
burnInPercentage='$BURN_IN_PERCENT'
preBurnin='$PRE_BURN_IN'
deleteOldLogs='$DELETE_OLDLOGS'
nrOfSteps='$NUM_PS_STEPS'>
cd $RUNELEM_DIR_VAR
java $RUNELEM_CP_FLAG $RUNELEM_JAVA_CLASS beast.app.beastapp.BeastMain $RUNELEM_RESUME $RUNELEM_JAVA_FLAG $RUNELEM_SEED_FLAG $RUNELEM_SEED_VAR beast.xml
" > new_run_element.tmp

				## Make new xml file, replacing original file:
				rm $i
				cat ./xmlTop.tmp ./new_run_element.tmp ./xmlBottom.tmp > $BASENAME.xml

				## Clean up the working dir:
				rm ./*.tmp ./edit1.xml

				count=$((count+1))
       
			done
		)
}

##--Don't forget to run the function!
editXMLFiles



	else
		if [[ $MY_INPUTXMLFILE_VAR != "multiXML" ]]; then
			echo "INFO      | $(date) |          Detected a single BEAST input XML file. Adding path sampling code to the XML named $MY_INPUTXMLFILE_VAR... "



###### SECTION B. MAKE AND RUN FUNCTION WITH CODE FOR MANIPULATING THE SINGLE INPUT XML FILE SPECIFIED WHEN THE SHELL SCRIPT WAS CALLED:
	editXMLFiles () {

		BASENAME="$(ls $MY_INPUTXMLFILE_VAR | sed 's/\.xml$//g')"			## Get basename of input XML file, for later use.
		sed 's/\<run\ /\<mcmc\ /g; s/\<\/run\>/\<\/mcmc\>\ '$CR'\<\/run\>/g' $MY_INPUTXMLFILE_VAR > edit1.xml		## Make temporary edited file containing some, but not all, of the text edits needed for path sampling (i.e. renaming the original run element to mcmc).

		NLINES_TO_MCMCELEM=$(sed -n '/\<mcmc\ /{=; q;}' edit1.xml)			## These three lines get pertinent information about the number of lines in the edited XML, which is used below
		MY_HEADSTOP="$(calc $NLINES_TO_MCMCELEM-1)"							## in sed lines creating new tmp files containing the top and bottom portions of the edited XML. The edit1, xmlTop,
		NLINES_TOTAL=$(wc -l edit1.xml | sed 's/\ edit1\.xml//')			## and xmlBottom tmp files are concatenated together later with the new, custom run element tmp file created below
																			## to create the final XML with path sampling code.
		sed -n 1,"$MY_HEADSTOP"p edit1.xml > xmlTop.tmp
		sed -n "$NLINES_TO_MCMCELEM","$NLINES_TOTAL"p edit1.xml > xmlBottom.tmp
					
echo "<run spec='beast.inference.PathSampler'
chainLength='$CHAIN_LENGTH'
alpha='$ALPHA_VALUE'
rootdir='$ROOT_DIR$BASENAME/'
burnInPercentage='$BURN_IN_PERCENT'
preBurnin='$PRE_BURN_IN'
deleteOldLogs='$DELETE_OLDLOGS'
nrOfSteps='$NUM_PS_STEPS'>
cd $RUNELEM_DIR_VAR
java $RUNELEM_CP_FLAG $RUNELEM_JAVA_CLASS beast.app.beastapp.BeastMain $RUNELEM_RESUME $RUNELEM_JAVA_FLAG $RUNELEM_SEED_FLAG $RUNELEM_SEED_VAR beast.xml
" > new_run_element.tmp

		## Make new xml file, replacing original file:
		rm $MY_INPUTXMLFILE_VAR
		cat ./xmlTop.tmp ./new_run_element.tmp ./xmlBottom.tmp > $BASENAME.xml

		## Clean up the working dir:
		rm ./*.tmp ./edit1.xml
  
}

##--Don't forget to run the function!
editXMLFiles



	else
		echo "WARNING!  | $(date) |          Something went wrong. Found no BEAST XML files. "
	fi

fi

echo "INFO      | $(date) |          Finished prepping XML files for path sampling analyses in BEAST PathSampler using BEAST_PSPrepper.sh!!"
echo "INFO      | $(date) |          Bye."

#
#
#
######################################### END ############################################

exit 0
