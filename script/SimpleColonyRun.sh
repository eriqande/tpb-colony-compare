
# Some default values
DROPOUTRATE="0.02";  # I set these here, but it would not be hard to set them elsewhere
MISCALLRATE="0.02"; 
NumLocToUse=0; 
UseTheLocsFile=1;
WeightedAlleFreqs=0;
DryRun=0;
RUN_LENGTH=1;
SEED=1234;
LIKE_PRECIS=1;
NUMRUNS=1;
EWENS_PRIOR=0;
INFERENCE_METHOD=1;
BINARY_BASENAME=colony2s.out;  # by default it uses the new colony

function usage {
    echo Syntax:
    echo "  $(basename $0)  [-y -d DropRate -m MisRate -l NumLoc -e EwensPrior -L -f -r RunLen -p LikPre -n NumRuns -x] DIR  RUN  Inputs  Perm?"
    echo
    echo "DIR is the name of a directory where there resides a file named 
genotypes.txt.  This script creates a new directory named RUN inside
DIR and processes genotypes.txt into a Colony.dat file in RUN.  This file
includes the run options.  The Collection name is DIR.  The output name
is DIR_RUN.  The script counts the number of individuals, etc. 

Inputs is the path to the input directory where the preamble and
the postamble live.

Perm? Is a Boolean to tell us whether we should permute the data with 
sgm_perm (if Perm==1) or not (otherwise).

This script assumes there is a file called the_locs.txt in it
that has at least the locus names in it.

This script is designed to be run 

This script also will wire it to:
  - do 1 run.
  - give it a random seed
  - do a run lenght of 1 (out of 1/2/3)
  - use likelihood precision of 1 (out of 1/2/3)
The latter two because we want to have time to do multiple runs.

The optional flag options have the following effects:

-y             :   Dry-Run -- just compile up the colony input file, but don't run Colony on it.
-d DropRate    :   Rate of dropout errors is set to DropRate
-m MisRate     :   Miscall error rate is set to MisRate
-l NumLoc      :   Use only the first NumLoc loci in the data set.
                   Note that there must be at least NumLoc loci
                   in genotypes.txt.  Typically you will want to 
                   also use -L with this so it doesn't try getting
                   locus names from a file that might not be there.
-e EwensPrior  :   By default, don't use any prior.  But it you want to use it you can add a string 
                   that looks like "1 3.07 3.07" (make sure it is quoted) where the 1 means "use the ewens prior"
                   and the two numbers that follow are the average number of offspring per each sex.
-S seed        :   The random seed for Colony to use.  By default = 1234
-L             :   Don't try to get locus names from the_locs.txt.  Instead
                   just use: Loc_1, Loc_2, ... NumLoc.
-f             :   Sets COLONY to do allele frequency estimation that
                   takes into account the inferred sibship structure. 
                   (By default this script doesn't use that).
-r RunLen      :   Set run length to RunLen (must be 1, 2, or 3). Default is 1.
-p LikPre      :   Set Likelihood precision to LikPre (must be 1, 2, or 3).
-n NumRuns     :   Set it up to do NumRuns different runs with the data set.
-x             :   Set the inference method to Pairwise (0) rather than Full Likelihood (1)
-o             :   Use the old version of Colony (i.e. the 2009/2010 as opposed to 2013/2014 version)



"
}


if [ $# -eq 0 ]; then
    usage;
    exit 1;
fi;

# use getopts so you can pass it -n 50, for example. 
while getopts ":d:m:l:e:S:Lyfr:p:n:xo" opt; do
    case $opt in
	d    )  DROPOUTRATE=$OPTARG;
	    ;;
	m    )  MISCALLRATE=$OPTARG;
	    ;;
	l    )  NumLocToUse=$OPTARG;
	    ;;
  e    )  EWENS_PRIOR="$OPTARG";
      ;;
  S    )  SEED=$OPTARG;
      ;;
	L    )  UseTheLocsFile=0;
	    ;;
  y    )  DryRun=1;
      ;;
	f    )  WeightedAlleFreqs=1;
	    ;;
	r    )  RUN_LENGTH=$OPTARG;
	    ;;
	p    )  LIKE_PRECIS=$OPTARG;
	    ;;
	n    )  NUMRUNS=$OPTARG;
	    ;;
	x    )  INFERENCE_METHOD=0;
	    ;;
	o    )  BINARY_BASENAME=Colony2;
	    ;;
	\?   )
	    usage
	    exit  1
	    ;;
    esac
done

shift $((OPTIND-1));


if [ $# -ne 4 ]; then
    usage;
    exit 1;
fi

DIR=$1
RUN=$2
INP=$3
PERM=$4





# get the directory in which this is being called.  This will be used to find 
# some of the other directories, etc.
CURDIR=$(pwd);

# this is designed to be run from just above the input directory
PREAMBLE=$CURDIR/$INP/ColonyCanonicalPreamble.txt;
POSTAMBLE=$CURDIR/$INP/ColonyCanonicalPostamble.txt;





cd $DIR;

# make the run directory and cd into it
mkdir -p $RUN
cd $RUN


# COUNT HOW MANY FISH
NUMFISH=$( wc ../genotypes.txt | awk '{print $1}');


# count the number of loci assuming that each line in genotypes.txt has 
# an ID and then 2 columns for every locus
NUMLOCI=$(awk 'NF>0  {printf("%d",(NF-1)/2); exit}' ../genotypes.txt;)
if [ $NumLocToUse -eq 0 ]; then
    NumLocToUse=$NUMLOCI;
fi

# now create the temp file for the loci, which will be included in the 
# data set
if [ $UseTheLocsFile -eq 1 ]; then
    awk  -v NumToUse=$NumLocToUse 'NF==0 {next} n==0 {++n; printf("%s",$1); next} n>0 {if(++n<=NumToUse) printf("\t%s",$1);} END {printf("\n");}' $CURDIR/the_locs.txt  > aaatemploc;
else
    echo $NumLocToUse | awk '{printf("Loc_1"); for(i=2;i<=$1;i++)  printf("\tLoc_%d",i); printf("\n");}' > aaatemploc;
fi
echo $NumLocToUse $DROPOUTRATE $MISCALLRATE | awk '
 {printf("0"); for(i=2;i<=$1;i++) printf("\t0"); printf("\n");}  # print 0s to denote they are all codominant
 {printf("%s",$2); for(i=2;i<=$1;i++) printf("\t%s",$2); printf("\n");}  # print the DropOut Rates
 {printf("%s",$3); for(i=2;i<=$1;i++) printf("\t%s",$3); printf("\n");}  # print the Miscall Rates
' >> aaatemploc;

# bung the canonical files together while processing the data file:
( 
    sed "s/COLLECTION/$(basename $DIR)/g;
         s/OUTFIX/$(basename $DIR)_$RUN/g;
         s/NUMOFFS/$NUMFISH/g;
         s/NUMLOCS/$NumLocToUse/g;
         s/SEED/$SEED/g;  # just want to get a reliably different random seed.  This is sort of hacky, but it works.
         s/UPDATE_FREQS/$WeightedAlleFreqs/g;
         s/NUMRUNS/$NUMRUNS/g;
         s/RUNLENGTH/$RUN_LENGTH/g;
         s/LIKE_PRECIS/$LIKE_PRECIS/g;
         s/INFERENCE_METHOD/$INFERENCE_METHOD/g;
         s/EWENS_PRIOR/$EWENS_PRIOR/g;" $PREAMBLE;
    cat aaatemploc;
    if [ $PERM -eq 1 ]; then
	sgm_perm -N  $NUMFISH -L $NUMLOCI < ../genotypes.txt | awk -v N=$NumLocToUse '$1~/Perm_[0-9]/ {printf("%s",$1); for(i=2;i<=N*2+1;i++) printf("\t%s",$i); printf("\n");}'
    else
	awk -v N=$NumLocToUse 'NF>0 {printf("%s",$1); for(i=2;i<=N*2+1;i++) printf("\t%s",$i); printf("\n");}' ../genotypes.txt;
    fi
    cat $POSTAMBLE;
) > Colony2.dat;


# If we are using the old version of Colony (i.e. before the stuff jinliang put in
# to reduce large full sibgroup splits) then we have to delete the inbreeding line from the Colony2.dat
if [ $BINARY_BASENAME = "Colony2" ]; then
	awk '/This option not compatible with the old version of colony/ {next} {print}' Colony2.dat > zzttuutmp
	mv zzttuutmp Colony2.dat
fi




# then start Colony and redirect output to StdoutColony.txt
# and redirect stderr there too!
if [ $DryRun -eq 0 ]; then 
  $CURDIR/bin/$BINARY_BASENAME  >  StdoutColony.txt 2>&1;
fi


# when it is done, change back to the directory you started from
cd $CURDIR

