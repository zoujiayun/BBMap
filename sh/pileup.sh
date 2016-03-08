#!/bin/bash
#pileup in=<infile> out=<outfile>

usage(){
	echo "Written by Brian Bushnell"
	echo "Last modified May 23, 2014"
	echo ""
	echo "Description:  Calculates per-scaffold coverage information from an unsorted sam file."
	echo ""
	echo "Usage:	pileup.sh in=<input> out=<output>"
	echo ""
	echo "Input may be stdin or a SAM file, compressed or uncompressed."
	echo "Output may be stdout or a file."
	echo ""
	echo "Input Parameters:"
	echo "in=<sam file>		The input sam; this is the only required parameter."
	echo "ref=<fasta file>	Scans a reference fasta for per-scaffold GC counts, not otherwise needed."
	echo "fastaorf=<fasta file>	A fasta file with ORF header information in PRODIGAL's output format.  Must also specify 'outorf'."
	echo "unpigz=<true>		Decompress with pigz for faster decompression."
	echo ""
	echo "Output Parameters:"
	echo "out=<file>		Prints per-scaffold coverage info to this file."
	echo "outorf=<file>		Prints per-orf coverage info to this file (only if 'fastaorf' is specified)."
	echo "twocolumn=<false> 	Change to true to print only ID and Avg_fold instead of all 6 columns to the 'out=' file."
	echo "outsam=<file>		Prints the input sam stream to this file (or stdout).  Useful for piping data."
	echo "hist=<file>		Prints a histogram of # occurrences of each depth level."
	echo "basecov=<file>		Prints coverage per base location."
	echo "bincov=<file>		Prints binned coverage per location (one line per X bases)."
	echo "binsize=<1000>		Set the binsize for binned coverage output."
	echo "keepshortbins=<true>	(ksb) Keep residual bins shorter than binsize."
	echo "delta=<false>		Only print base coverage lines when the coverage differs from the previous base."
	echo "nzo=<false>		Only print scaffolds with nonzero coverage."
	echo ""
	echo "Other parameters:"
	echo "32bit=<false>		Set to true if you need per-base coverage over 64k; does not affect per-scaffold coverage precision."
	echo "				This option will double RAM usage (when calculating per-base coverage)."
	echo ""
	echo "Java Parameters:"
	echo "-Xmx       		This will be passed to Java to set memory usage, overriding the program's automatic memory detection."
	echo "				-Xmx20g will specify 20 gigs of RAM, and -Xmx200m will specify 200 megs.  The max is typically 85% of physical memory."
	echo ""
	echo "Output format:"
	echo "ID	Length	Ref_GC	Avg_fold	Base_Coverage	Read_GC"
	echo ""
	echo "ID:			Scaffold ID"
	echo "Length:			Scaffold length"
	echo "Ref_GC:			GC ratio of reference"
	echo "Avg_fold:		Average fold coverage of this scaffold"
	echo "Base_Coverage:		Percent of scaffold with any coverage"
	echo "Read_GC:		Average GC ratio of reads mapped to this scaffold"
	echo ""
	echo "Notes:"
	echo ""
	echo "Only supports SAM format for reads and FASTA for reference (though either may be gzipped)."
	echo "Sorting is not needed, so output may be streamed directly from a mapping program."
	echo "Requires approximately 1 bit per reference base plus 100 bytes per scaffold (even if no reference is specified)."
	echo "This script will attempt to autodetect and correctly specify the -Xmx parameter to use all memory on the target node."
	echo "If this fails with a message including 'Error: Could not create the Java Virtual Machine.', then..."
	echo "Please decrease the -Xmx parameter.  It should be set to around 85% of the available memory."
	echo "For example, -Xmx20g needs around 23 GB of virtual (and physical) memory when qsubbed."
	echo "If the program fails with a message including 'java.lang.OutOfMemoryError:', then..."
	echo "-Xmx needs to be increased, which probably also means it needs to be qsubbed with a higher memory allocation."
	echo ""
	echo "Please contact Brian Bushnell at bbushnell@lbl.gov if you encounter any problems."
}

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/"
CP="$DIR""current/"

z="-Xmx1g"
z2="-Xms1g"
EA="-ea"
set=0

if [ -z "$1" ] || [[ $1 == -h ]] || [[ $1 == --help ]]; then
	usage
	exit
fi

calcXmx () {
	source "$DIR""/calcmem.sh"
	parseXmx "$@"
	if [[ $set == 1 ]]; then
		return
	fi
	freeRam 3200m 84
	z="-Xmx${RAM}m"
	z2="-Xms${RAM}m"
}
calcXmx "$@"

pileup() {
	#module unload oracle-jdk
	#module unload samtools
	#module load oracle-jdk/1.7_64bit
	#module load pigz
	#module load samtools
	local CMD="java $EA $z -cp $CP jgi.SamPileup $@"
	echo $CMD >&2
	$CMD
}

pileup "$@"
