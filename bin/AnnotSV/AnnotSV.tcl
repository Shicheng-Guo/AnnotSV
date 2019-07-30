#!/usr/bin/env tclsh

############################################################################################################
# AnnotSV 2.2.3                                                                                              #
#                                                                                                          #
# AnnotSV: An integrated tool for Structural Variations annotation and ranking                             #
#                                                                                                          #
# Copyright (C) 2017-2019 Veronique Geoffroy (veronique.geoffroy@inserm.fr)                                #
#                                                                                                          #
# This is part of AnnotSV source code.                                                                     #
#                                                                                                          #
# This program is free software; you can redistribute it and/or                                            #
# modify it under the terms of the GNU General Public License                                              #
# as published by the Free Software Foundation; either version 3                                           #
# of the License, or (at your option) any later version.                                                   #
#                                                                                                          #
# This program is distributed in the hope that it will be useful,                                          #
# but WITHOUT ANY WARRANTY; without even the implied warranty of                                           #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the                                             #
# GNU General Public License for more details.                                                             #
#                                                                                                          #
# You should have received a copy of the GNU General Public License                                        #
# along with this program; If not, see <http://www.gnu.org/licenses/>.                                     #
############################################################################################################

global g_AnnotSV

# non-zero exit codes --> usually interpreted as error cases
# zero exit code --> Terminate the process without error 
# exit <=> exit 0 (default)


## Checking for environment variables needed (if all are defined).
if {![info exists env(ANNOTSV)]} {
    puts "\"ANNOTSV\" environment variable not specified. Please defined it before running AnnotSV. Exit with error"; exit 2
}

## Checking if the application name is the same that the path of the ANNOTSV environment variable
set actualPWD [exec pwd]
cd $env(ANNOTSV)
set envPWD [exec pwd]
cd $actualPWD
cd [file dirname $argv0]
cd ../..
set argv0PWD [pwd]
if {$envPWD ne $argv0PWD} {
    puts "WARNING:"
    puts "The application path ([file dirname $argv0]) is different from the \"ANNOTSV\" environment variable ($env(ANNOTSV)/bin)."
    puts "Check your \"ANNOTSV\" environment variable. Exit with error"; exit 2
}
cd $actualPWD

# Setting of g_AnnotSV(installDir), g_AnnotSV(tclDir), g_AnnotSV(docDir) and g_AnnotSV(etcDir):
set g_AnnotSV(installDir) "$env(ANNOTSV)"
set g_AnnotSV(etcDir) "$g_AnnotSV(installDir)/etc/AnnotSV"
set g_AnnotSV(docDir) "$g_AnnotSV(installDir)/share/doc/AnnotSV"
set tclVersion [info tclversion]
set g_AnnotSV(tclDir) "$g_AnnotSV(installDir)/share/tcl${tclVersion}/AnnotSV"
if {![file exists $g_AnnotSV(tclDir)]} {
    set g_AnnotSV(tclDir) "$g_AnnotSV(installDir)/share/tcl/AnnotSV"
}

source $g_AnnotSV(tclDir)/AnnotSV-1000g.tcl
source $g_AnnotSV(tclDir)/AnnotSV-clingen.tcl
source $g_AnnotSV(tclDir)/AnnotSV-config.tcl
source $g_AnnotSV(tclDir)/AnnotSV-ddd.tcl
source $g_AnnotSV(tclDir)/AnnotSV-dgv.tcl
source $g_AnnotSV(tclDir)/AnnotSV-extann.tcl
source $g_AnnotSV(tclDir)/AnnotSV-filteredVCF.tcl
source $g_AnnotSV(tclDir)/AnnotSV-exac.tcl
source $g_AnnotSV(tclDir)/AnnotSV-gccontent.tcl
source $g_AnnotSV(tclDir)/AnnotSV-general.tcl
source $g_AnnotSV(tclDir)/AnnotSV-genehancer.tcl
source $g_AnnotSV(tclDir)/AnnotSV-gnomad.tcl
source $g_AnnotSV(tclDir)/AnnotSV-haploinsufficiency.tcl
source $g_AnnotSV(tclDir)/AnnotSV-help.tcl
source $g_AnnotSV(tclDir)/AnnotSV-imh.tcl
source $g_AnnotSV(tclDir)/AnnotSV-omim.tcl
source $g_AnnotSV(tclDir)/AnnotSV-pathogenic-NR-SV.tcl
source $g_AnnotSV(tclDir)/AnnotSV-promoter.tcl
source $g_AnnotSV(tclDir)/AnnotSV-ranking.tcl
source $g_AnnotSV(tclDir)/AnnotSV-refGene.tcl
source $g_AnnotSV(tclDir)/AnnotSV-repeat.tcl
source $g_AnnotSV(tclDir)/AnnotSV-tad.tcl
source $g_AnnotSV(tclDir)/AnnotSV-userBED.tcl
source $g_AnnotSV(tclDir)/AnnotSV-vcf.tcl
source $g_AnnotSV(tclDir)/AnnotSV-write.tcl

# Setting of g_AnnotSV(Version):
if {![info exists g_AnnotSV(Version)]} {
    set configFile "$g_AnnotSV(tclDir)/AnnotSV-config.tcl"
    foreach L [LinesFromFile $configFile] {
	if {[regexp "^# AnnotSV (\[0-9\]+.\[0-9\]+)" $L match version]} {
	    set g_AnnotSV(Version) "$version"
	    break
	}
    }
}
if {![info exists g_AnnotSV(Version)]} {
    set g_AnnotSV(Version) "X.X"
}


puts "AnnotSV $g_AnnotSV(Version)"
puts ""
puts "Copyright (C) 2017-2019 GEOFFROY Veronique"
puts ""
puts "Please feel free to contact me for any suggestions or bug reports"
puts "email: veronique.geoffroy@inserm.fr"
puts ""
puts "Tcl/Tk version: $tclVersion"
puts ""
puts "Application name used (defined with the \"ANNOTSV\" environment variable):"
puts "$env(ANNOTSV)\n\n"

set tclVersion [split $tclVersion "."]
if {[lindex $tclVersion 0] < 8 || ([lindex $tclVersion 0] eq 8 && [lindex $tclVersion 1] < 5)} {
    puts "AnnotSV requires a release of the Tcl distribution starting with version 8.5."
    puts "(AnnotSV has not been tested with lower version)"
}

## No argument given:
if {$argv == ""} {
    puts "Arguments are missing see help below\n"
    showHelp; exit 0
}

## Needing help?
if {[regexp -nocase "help" $argv]} {showHelp; exit 0}

## Downloading configuration:
configureAnnotSV $argv



## Depending of the VCF or BED input format:
set testHeader 0
if {[regexp "\\.vcf(.gz)?$" $g_AnnotSV(SVinputFile)]} {
    ## SVinputfile is a VCF?
    ## -> need to be formated in bed
    set g_AnnotSV(bedFile) [VCFsToBED "$g_AnnotSV(SVinputFile)"]
} else {
    ## SVinputfile is a BED
    set g_AnnotSV(bedFile) $g_AnnotSV(SVinputFile)
    regsub -nocase ".bed$" $g_AnnotSV(bedFile) ".header.tsv" BEDinputHeaderFile
    if {![file exists $BEDinputHeaderFile]} {
	set testHeader 1
	createBEDinputHeaderFile
    }
}

# Annotation with RefGene ?
checkRefGeneFile

# Annotation with Promoters?
checkPromoterFile

# Annotation with OMIM?
checkOMIMfile
checkMorbidGenesfile

# Annotation with DGV?
checkDGVfiles

# Annotation with the dbVar pathogenic NR SV?
checkPathogenicNRSVfile

# Annotation with GeneIntolerance (ExAC)?
checkGeneIntoleranceFile
checkCNVintoleranceFile

# Annotation with DDD?
checkDDDgeneFile
checkDDDfrequencyFile

# Annotation with 1000g?
check1000gFile

# Annotation with gnomAD? 
checkgnomADfile

# Annotation with IMH (Ira M. Hall's lab)? 
checkIMHfile

# Annotation with HI (Haploinsufficiency)?
checkHIfile

# Annotation with ClinGen?
checkClinGenFile

# Annotation with TAD?
checkTADfiles

# Annotation with GC content?
checkFASTAfiles

# Annotation with Repeat?
checkRepeatFile

# Annotation with GeneHancer?
checkGHfiles

# Users BED regions annotations files (from $ANNOTSV/Annotations_$g_AnnotSV(organism)/Users/GRCh*/*ncludedIn*/*.bed)
checkUsersBED

# Users Genes-based annotation files (from $ANNOTSV/Annotations_$g_AnnotSV(organism)/*/)
# g_AnnotSV(extann) has been initialized in AnnotSV-config.tcl
set extannDir "$g_AnnotSV(docDir)/Annotations_$g_AnnotSV(organism)/Genes-based"
foreach annotFile [glob -nocomplain $extannDir/*/*.tsv] {
    if {[regexp "_DGV_samplesInStudies.tsv$" $annotFile]} {continue}
    lappend g_AnnotSV(extann) $annotFile
}
foreach annotFile [glob -nocomplain $extannDir/*/*.tsv.gz] {
    lappend g_AnnotSV(extann) $annotFile
}
set userDir "$g_AnnotSV(docDir)/Annotations_$g_AnnotSV(organism)/Users/" 
foreach annotFile [glob -nocomplain $userDir/*.tsv] {
    lappend g_AnnotSV(extann) $annotFile
}
foreach annotFile [glob -nocomplain $userDir/*.tsv.gz] {
    lappend g_AnnotSV(extann) $annotFile
}
# Depending of the organism, genes based annotation can be absent:
if {$g_AnnotSV(extann) eq ""} {set g_AnnotSV(genesBasedAnn) 0} else {set g_AnnotSV(genesBasedAnn) 1} 


# DISPLAY
puts "\t******************************************"
puts "\tAnnotSV has been run with these arguments:"
puts "\t******************************************"
set lKey [array names g_AnnotSV]
foreach key [lsort $lKey] {
    if {[regexp "outputColHeader|installDir|etcDir|tclDir|docDir|userDir|Version|bedFile|extann|refGene|Ann|NRSVann|GHann|IMHann|gnomADann|ranking$" $key]} {continue}
    if {$g_AnnotSV($key) eq ""} {continue}
    puts "\t-$key $g_AnnotSV($key)"
}
puts "\t******************************************\n"


# Annotation with the gene track 
refGeneAnnotation
OrganizeAnnotation

if {$testHeader} {file delete -force $BEDinputHeaderFile}
puts "\n...AnnotSV is done with the analysis ([clock format [clock seconds] -format "%B %d %Y - %H:%M"])"

