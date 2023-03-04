#!/usr/bin/perl
# ----------------------------------------------------------------- #
#         The Prosody Labeling and Modeling Toolkit (PLMTK)         #
#         developed by SMSPL, NTPU, Taiwan                          #
#         http://cychiang.tw                                        #
# ----------------------------------------------------------------- #
#                                                                   #
#  Copyright (c) 2019-2020  National Taipei University, Taiwan      #
#                           Department of Communication Engineering #
#                                                                   #
# All rights reserved.                                              #
#                                                                   #
# Redistribution and use in source and binary forms, with or        #
# without modification, are permitted provided that the following   #
# conditions are met:                                               #
#                                                                   #
# - Redistributions of source code must retain the above copyright  #
#   notice, this list of conditions and the following disclaimer.   #
# - Redistributions in binary form must reproduce the above         #
#   copyright notice, this list of conditions and the following     #
#   disclaimer in the documentation and/or other materials provided #
#   with the distribution.                                          #
# - Neither the name of the HTS working group nor the names of its  #
#   contributors may be used to endorse or promote products derived #
#   from this software without specific prior written permission.   #
#                                                                   #
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND            #
# CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,       #
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF          #
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE          #
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS #
# BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,          #
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED   #
# TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,     #
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON #
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,   #
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY    #
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE           #
# POSSIBILITY OF SUCH DAMAGE.                                       #
# ----------------------------------------------------------------- #

use strict;
use warnings;
use File::Basename;
use File::Path 'rmtree';
use File::Find;
use File::Find qw(finddepth);
use File::Copy::Recursive qw(fcopy rcopy dircopy fmove rmove dirmove);
use feature qw/say/;
use Cwd qw(getcwd);
use lib '.';
$| = 1;

if ( @ARGV < 1 ) {
    print "usage: plmtk.pl Config.pm\n";
    exit(0);
}

# load configuration variables
require( $ARGV[0] );

no warnings 'once';

my $cmdline = "";
my $i = 0;

# clean all generated data
if ($PLMTK::CLEAN) {
    &print_time("clean all generated data");
    my $tmp = "$PLMTK::databasedir/intermediate";
    rmtree($tmp);
    mkdir $tmp;
    $tmp = "$PLMTK::databasedir/out";
    rmtree($tmp);
    mkdir $tmp;
}

# insert space between Chinese characters and English words
if ($PLMTK::INSSP) {
    &print_time("insert space between Chinese characters and English words");
    my $dir = "$PLMTK::databasedir/in/text";
    mkdir "$PLMTK::databasedir/intermediate/text_engch", 0755;
    opendir(DIR, $dir) or die $!;
    while (my $file = readdir(DIR)) {

        # We only want files
        next unless (-f "$dir/$file");

        # Use a regular expression to find files ending in .txt
        next unless ($file =~ m/\.txt$/);

        $cmdline        = "$PLMTK::progbasedir/$PLMTK::DIVIDE_ENGCH < $PLMTK::databasedir/in/text/$file > $PLMTK::databasedir/intermediate/text_engch/$file";
        print "$cmdline\n";
        system("$cmdline");
    }
    closedir(DIR);
}

# word tokenization and pos tagging
if ($PLMTK::PARSE) {
    &print_time("word tokenization and pos tagging");
    my $dir = "$PLMTK::databasedir/intermediate/text_engch";
    mkdir "$PLMTK::databasedir/intermediate/parser", 0755;
    opendir(DIR, $dir) or die $!;
    while (my $file = readdir(DIR)) {

        # We only want files
        next unless (-f "$dir/$file");

        # Use a regular expression to find files ending in .txt
        next unless ($file =~ m/\.txt$/);

        #print "$file\n";
        $cmdline        = "./parser_example < $PLMTK::databasedir/intermediate/text_engch/$file > $PLMTK::databasedir/intermediate/parser/$file";
        print "$cmdline\n";
        chdir "$PLMTK::progbasedir/ta/parser_UNICODE";
        system("$cmdline");
    }
    closedir(DIR);
    chdir "$PLMTK::progbasedir";
}

# convert parser output to transx
if ($PLMTK::PA2TX) {
    &print_time("convert parser output to transx");
    my $dir = "$PLMTK::databasedir/intermediate/parser";
    mkdir "$PLMTK::databasedir/intermediate/transx", 0755;
    opendir(DIR, $dir) or die $!;
    while (my $file = readdir(DIR)) {

        # We only want files
        next unless (-f "$dir/$file");

        # Use a regular expression to find files ending in .txt
        next unless ($file =~ m/\.txt$/);
        my($basename)=basename($file, '.txt');
        chdir "$PLMTK::progbasedir/ta/parser2transx"; # ISSUE: parser2transx should let dict and other tables can be specified in command line
        $cmdline        = "$PLMTK::progbasedir/$PLMTK::PARSER2TRANSX $PLMTK::progbasedir/ta/parser2transx/wm_dict_utf8.txt $PLMTK::progbasedir/ta/parser2transx/pos_table.txt $PLMTK::progbasedir/ta/parser2transx/phrase_table.txt $PLMTK::progbasedir/ta/parser2transx/OOV.txt < $PLMTK::databasedir/intermediate/parser/$basename.txt > $PLMTK::databasedir/intermediate/transx/$basename.transxtmp";
        print "$cmdline\n";
        system("$cmdline");
        $cmdline        = "grep -v '^\\s*\$' $PLMTK::databasedir/intermediate/transx/$basename.transxtmp > $PLMTK::databasedir/intermediate/transx/$basename.transx";
        print "$cmdline\n";
        system("$cmdline");
    }
    $cmdline        = "rm -f $PLMTK::databasedir/intermediate/transx/*.transxtmp";
    print "$cmdline\n";
    system("$cmdline");
    closedir(DIR);
}

# convert transx to phg (label phoneme for English)
if ($PLMTK::PHGEN) {
    &print_time("convert transx to phg (label phoneme for English)");
    my $dir = "$PLMTK::databasedir/intermediate/transx";
    mkdir "$PLMTK::databasedir/intermediate/phgen", 0755;
    opendir(DIR, $dir) or die $!;
    while (my $file = readdir(DIR)) {

        #print "$file\n";
        
        #print "$basename\n";
        # We only want files
        next unless (-f "$dir/$file");

        # Use a regular expression to find files ending in .txt
        next unless ($file =~ m/\.transx$/);
        my($basename)=basename($file, '.transx');
        #print "$file\n";
        chdir "$PLMTK::progbasedir/ta/phoneme_gen"; # ISSUE: something wrong with CMUltsrule although we've already compile cs file by mcs and run executable with mono
        $cmdline        = "$PLMTK::progbasedir/$PLMTK::PHONEME_GEN < $PLMTK::databasedir/intermediate/transx/$basename.transx > $PLMTK::databasedir/intermediate/phgen/$basename.phgen";
        #$cmdline        = "./phoneme_gen < $PLMTK::databasedir/intermediate/transx/$basename.transx > $PLMTK::databasedir/intermediate/phgen/$basename.phgen";
        print "$cmdline\n";
        #chdir "$PLMTK::progbasedir/ta/parser_UNICODE";
        #system("cd $PLMTK::progbasedir/ta/parser_UNICODE");
        system("$cmdline");
    }
    closedir(DIR);
}


# convert transx to phg (label phoneme for English)
if ($PLMTK::PH2AL) {
    &print_time("convert transx to phg (label phoneme for English)");
    my $dir = "$PLMTK::databasedir/intermediate/phgen";
    mkdir "$PLMTK::databasedir/intermediate/ala_sp", 0755;
    opendir(DIR, $dir) or die $!;
    while (my $file = readdir(DIR)) {

        # We only want files
        next unless (-f "$dir/$file");

        # Use a regular expression to find files ending in .txt
        next unless ($file =~ m/\.phgen$/);
        my($basename)=basename($file, '.phgen');
        #print "$file\n";
        #chdir "$PLMTK::progbasedir/ta/phoneme2ala";
        $cmdline        = "$PLMTK::progbasedir/$PLMTK::PHONEME2ALA < $PLMTK::databasedir/intermediate/phgen/$basename.phgen > $PLMTK::databasedir/intermediate/ala_sp/$basename.ala";
        print "$cmdline\n";
        #chdir "$PLMTK::progbasedir/ta/parser_UNICODE";
        #system("cd $PLMTK::progbasedir/ta/parser_UNICODE");
        system("$cmdline");
    }
    closedir(DIR);
}

# remove space from ala
if ($PLMTK::RMASP) {
    &print_time("remove space from ala");
    my $dir = "$PLMTK::databasedir/intermediate/ala_sp";
    mkdir "$PLMTK::databasedir/intermediate/ala", 0755;
    opendir(DIR, $dir) or die $!;
    while (my $file = readdir(DIR)) {
        # We only want files
        next unless (-f "$dir/$file");

        # Use a regular expression to find files ending in .txt
        next unless ($file =~ m/\.ala$/);
        my($basename)=basename($file, '.ala');
        #print "$file\n";
        #chdir "$PLMTK::progbasedir/dp/rmspace_ala";
        $cmdline        = "$PLMTK::progbasedir/$PLMTK::RMSPACE_ALA $PLMTK::databasedir/intermediate/ala_sp/$basename.ala $PLMTK::databasedir/intermediate/ala/$basename.ala";
        print "$cmdline\n";
        #chdir "$PLMTK::progbasedir/ta/parser_UNICODE";
        #system("cd $PLMTK::progbasedir/ta/parser_UNICODE");
        system("$cmdline");
    }
    closedir(DIR);
}


# convert ala to text
if ($PLMTK::ALA2T) {
    &print_time("convert ala to text");
    my $dir = "$PLMTK::databasedir/intermediate/ala";
    mkdir "$PLMTK::databasedir/intermediate/ala_txt", 0755;
    opendir(DIR, $dir) or die $!;
    while (my $file = readdir(DIR)) {
        # We only want files
        next unless (-f "$dir/$file");

        # Use a regular expression to find files ending in .txt
        next unless ($file =~ m/\.ala$/);
        my($basename)=basename($file, '.ala');
        #chdir "$PLMTK::progbasedir/dp/ala2txt";
        $cmdline        = "$PLMTK::progbasedir/$PLMTK::ALA2TXT $PLMTK::databasedir/intermediate/ala/$basename.ala $PLMTK::databasedir/intermediate/ala_txt/$basename.txt";
        print "$cmdline\n";
        system("$cmdline");
    }
    closedir(DIR);
}


# convert text to tokens of Chinise characters and English words
if ($PLMTK::TOKEN) {
    &print_time("convert text to tokens of Chinise characters and English words");
    my $dir = "$PLMTK::databasedir/intermediate/ala_txt";
    mkdir "$PLMTK::databasedir/intermediate/tok", 0755;
    opendir(DIR, $dir) or die $!;
    while (my $file = readdir(DIR)) {
        # We only want files
        next unless (-f "$dir/$file");
        # Use a regular expression to find files ending in .txt
        next unless ($file =~ m/\.txt$/);
        my($basename)=basename($file, '.txt');
        $cmdline        = "$PLMTK::progbasedir/$PLMTK::TOKENIZE $PLMTK::databasedir/intermediate/ala_txt/$basename.txt $PLMTK::databasedir/intermediate/tok/$basename.tok";
        print "$cmdline\n";
        system("$cmdline");
    }
    closedir(DIR);
}

# convert tokens to mlf
if ($PLMTK::T2MLF) {
    &print_time("convert tokens to mlf");
    my $dir = "$PLMTK::databasedir/intermediate/tok";
    mkdir "$PLMTK::databasedir/intermediate/mlf", 0755;
    opendir(DIR, $dir) or die $!;
    while (my $file = readdir(DIR)) {
        # We only want files
        next unless (-f "$dir/$file");

        # Use a regular expression to find files ending in .txt
        next unless ($file =~ m/\.tok$/);
        my($basename)=basename($file, '.tok');
        #chdir "$PLMTK::progbasedir/dp/tok2mlf";
        $cmdline        = "$PLMTK::progbasedir/$PLMTK::TOK2MLF $PLMTK::databasedir/intermediate/tok/$basename.tok $PLMTK::databasedir/intermediate/mlf/$basename.mlf";
        print "$cmdline\n";
        system("$cmdline");
    }
    closedir(DIR);
}


# convert mlf to mlf_byte
if ($PLMTK::ML2BT) {
    &print_time("convert mlf to mlf_byte");
    my $dir = "$PLMTK::databasedir/intermediate/mlf";
    mkdir "$PLMTK::databasedir/intermediate/mlf_byte", 0755;
    opendir(DIR, $dir) or die $!;
    while (my $file = readdir(DIR)) {
        # We only want files
        next unless (-f "$dir/$file");

        # Use a regular expression to find files ending in .txt
        next unless ($file =~ m/\.mlf$/);
        my($basename)=basename($file, '.mlf');
        #chdir "$PLMTK::progbasedir/dp/mlf2byte";
        $cmdline        = "$PLMTK::progbasedir/$PLMTK::MLF2BYTE $PLMTK::databasedir/intermediate/mlf/$basename.mlf $PLMTK::databasedir/intermediate/mlf_byte/$basename.mlf";
        print "$cmdline\n";
        system("$cmdline");
    }
    closedir(DIR);
}

# merge all mlf files to one mlf file
if ($PLMTK::ML2TT) {
    &print_time("merge all mlf files to one mlf file");
    my $dir = "$PLMTK::databasedir/intermediate/mlf_byte";
    my $mlf_scp = "$PLMTK::databasedir/intermediate/mlf.scp";
    system("rm -r $mlf_scp");
    open(write_file,">$mlf_scp")or die "Could not open file '$mlf_scp' $!";
    #mkdir "$PLMTK::databasedir/intermediate/mlf_byte", 0755;
    opendir(DIR, $dir) or die $!;
    while (my $file = readdir(DIR)) {
        next unless (-f "$dir/$file");
        next unless ($file =~ m/\.mlf$/);
        my($basename)=basename($file, '.mlf');
        $cmdline        = "$PLMTK::databasedir/intermediate/mlf_byte/$basename.mlf\n";
        print write_file "$cmdline";
    }
    close(write_file);
    closedir(DIR);
    #chdir "$PLMTK::databasedir/intermediate/mlf_byte";
    $cmdline        = "$PLMTK::progbasedir/$PLMTK::MLF2TOTAL $mlf_scp $PLMTK::databasedir/intermediate/all.mlf";
    system("$cmdline");
}

# add new English words to bu_radio_dict_with_syl
if ($PLMTK::CKDIC) {
    &print_time("add new English words to bu_radio_dict_with_syl");
    chdir "$PLMTK::databasedir/intermediate/";
    $cmdline = "rm -rf $PLMTK::databasedir/intermediate/bu_radio_dict_with_syl.miss.log";
    system("$cmdline");
    $cmdline = "cp $PLMTK::progbasedir/ta/phoneme_gen/bu_radio_dict_with_syl $PLMTK::databasedir/intermediate/bu_radio_dict_with_syl";
    print "$cmdline\n";
    system("$cmdline");
    my $dir = "$PLMTK::databasedir/intermediate/tok";
    opendir(DIR, $dir) or die $!;
    while (my $file = readdir(DIR)) {
        # We only want files
        next unless (-f "$dir/$file");
        # Use a regular expression to find files ending in .txt
        next unless ($file =~ m/\.tok$/);
        my($basename)=basename($file, '.tok');
        my $alafn = "$PLMTK::databasedir/intermediate/ala/$basename.ala";
        $cmdline        = "$PLMTK::progbasedir/$PLMTK::CHECK_DICT $PLMTK::databasedir/intermediate/tok/$file $alafn $PLMTK::databasedir/intermediate/bu_radio_dict_with_syl $PLMTK::databasedir/intermediate/bu_radio_dict_with_syl.miss.log";
        print "$cmdline\n";
        system("$cmdline");
    }
    closedir(DIR);
}

# convert CH dict to CH dict byte for HTK forced-alignment
if ($PLMTK::CDBYT) {
    &print_time("convert CH dict to CH dict byte for HTK forced-alignment");
    chdir "$PLMTK::databasedir/intermediate/";
    $cmdline = "cp $PLMTK::progbasedir/dp/chdict2byte/ch_dict.txt $PLMTK::databasedir/intermediate/ch_dict.txt";
    print "$cmdline\n";
    system("$cmdline");
    $cmdline        = "$PLMTK::progbasedir/$PLMTK::CHDICT2BYTE $PLMTK::databasedir/intermediate/ch_dict.txt $PLMTK::databasedir/intermediate/ch_dict_byte.txt";
    print "$cmdline\n";
    system("$cmdline");
}

# convert bu dict to cmu dict fot HTK forced-alignment
if ($PLMTK::B2CMU) {
    &print_time("convert bu dict to cmu dict fot HTK forced-alignment");
    chdir "$PLMTK::databasedir/intermediate/";
    $cmdline        = "$PLMTK::progbasedir/$PLMTK::BU2CMU $PLMTK::databasedir/intermediate/ch_dict_byte.txt $PLMTK::databasedir/intermediate/bu_radio_dict_with_syl $PLMTK::databasedir/intermediate/cmu";
    print "$cmdline\n";
    system("$cmdline");
}

# downsampling speech from 48kHz to 16kHz (save as *.wav and *.pcm)
if ($PLMTK::SOX16) {
    &print_time("downsampling speech from 48kHz to 16kHz (save as *.wav and *.pcm)");
    chdir "$PLMTK::databasedir/intermediate/";
    my $dir = "$PLMTK::databasedir/in/wav";
    mkdir "$PLMTK::databasedir/intermediate/wav16k", 0755;
    mkdir "$PLMTK::databasedir/intermediate/raw16k", 0755;
    opendir(DIR, $dir) or die $!;
    while (my $file = readdir(DIR)) {
        next unless (-f "$dir/$file");
        # Use a regular expression to find files ending in .wav
        next unless ($file =~ m/\.wav$/);
        my($basename)=basename($file, '.wav');
        
        $cmdline = "sox $PLMTK::databasedir/in/wav/$file -r 16000 -b 16 -L $PLMTK::databasedir/intermediate/wav16k/$basename.wav";
        print "$cmdline\n";
        system("$cmdline");

        $cmdline = "sox $PLMTK::databasedir/in/wav/$file -r 16000 -t raw -b 16 -L $PLMTK::databasedir/intermediate/raw16k/$basename.raw";
        print "$cmdline\n";
        system("$cmdline");

    }
    closedir(DIR);
}

# downsampling speech from 48kHz to 20kHz (save as *.wav and *.pcm)
if ($PLMTK::SOX20) {
    &print_time("downsampling speech from 48kHz to 20kHz (save as *.wav and *.pcm)");
    chdir "$PLMTK::databasedir/intermediate/";
    my $dir = "$PLMTK::databasedir/in/wav";
    mkdir "$PLMTK::databasedir/intermediate/wav20k", 0755;
    mkdir "$PLMTK::databasedir/intermediate/raw20k", 0755;
    opendir(DIR, $dir) or die $!;
    while (my $file = readdir(DIR)) {
        next unless (-f "$dir/$file");
        # Use a regular expression to find files ending in .wav
        next unless ($file =~ m/\.wav$/);
        my($basename)=basename($file, '.wav');
        
        $cmdline = "sox $PLMTK::databasedir/in/wav/$file -r 20000 -b 16 -L $PLMTK::databasedir/intermediate/wav20k/$basename.wav";
        print "$cmdline\n";
        system("$cmdline");

        $cmdline = "sox $PLMTK::databasedir/in/wav/$file -r 20000 -t raw -b 16 -L $PLMTK::databasedir/intermediate/raw20k/$basename.raw";
        print "$cmdline\n";
        system("$cmdline");

    }
    closedir(DIR);
}

 # forced-alignment by using HTK
if ($PLMTK::HTKTB) {
    &print_time("forced-alignment by using HTK");
    # make mfcc.scp
    chdir "$PLMTK::databasedir/intermediate/";
    system("rm -rf $PLMTK::databasedir/intermediate/mfcc.scp");
    mkdir "$PLMTK::databasedir/intermediate/mfc", 0755;
    my $dir = "$PLMTK::databasedir/intermediate/raw16k";
    opendir(DIR, $dir) or die $!;
    while (my $file = readdir(DIR)) {
        next unless (-f "$dir/$file");
        # Use a regular expression to find files ending in .wav
        next unless ($file =~ m/\.raw$/);
        my($basename)=basename($file, '.raw');
        $cmdline = "echo $PLMTK::databasedir/intermediate/raw16k/$basename.raw $PLMTK::databasedir/intermediate/mfc/$basename.mfc >> $PLMTK::databasedir/intermediate/mfcc.scp";
        system("$cmdline");
    }
    closedir(DIR);

    # HCopy
    #$cmdline = "$HCOPY  -T 1 -C $PLMTK::databasedir/intermediate/configs/configwav -C $PLMTK::databasedir/intermediate/configs/config -C $PLMTK::databasedir/intermediate/configs/config_wsj -S $PLMTK::databasedir/intermediate/mfcc.scp";
    $cmdline = "$PLMTK::HCOPY  -T 1 -C $PLMTK::progbasedir/dp/htk/config_mfcc -S $PLMTK::databasedir/intermediate/mfcc.scp";
    system("$cmdline");

    # make mlf.scp
    system("rm -rf $PLMTK::databasedir/intermediate/mlf.scp");
    $dir = "$PLMTK::databasedir/intermediate/mfc";
    opendir(DIR, $dir) or die $!;
    while (my $file = readdir(DIR)) {
        next unless (-f "$dir/$file");
        # Use a regular expression to find files ending in .mfc
        next unless ($file =~ m/\.mfc$/);
        my($basename)=basename($file, '.mfc');
        $cmdline = "echo $PLMTK::databasedir/intermediate/mfc/$basename.mfc >> $PLMTK::databasedir/intermediate/mlf.scp";
        system("$cmdline");
    }
    closedir(DIR);

    # HVite
    $cmdline = "$PLMTK::HVITE -T 1 -a -b sil -m -o S -C $PLMTK::progbasedir/dp/htk/config_train -H $PLMTK::progbasedir/dp/htk/model/mix128/hmm5/hmmdefs -m -I $PLMTK::databasedir/intermediate/all.mlf -i $PLMTK::databasedir/intermediate/all.lab -S $PLMTK::databasedir/intermediate/mlf.scp $PLMTK::databasedir/intermediate/cmu $PLMTK::progbasedir/dp/htk/CEhmmlist.txt";
    print "$cmdline\n";
    system("$cmdline");

    # dispatch lab file from aligned all.lab
    mkdir "$PLMTK::databasedir/intermediate/lab_cmu", 0755;
    $cmdline = "$PLMTK::progbasedir/$PLMTK::LABDISP $PLMTK::databasedir/intermediate/all.lab $PLMTK::databasedir/intermediate/lab_cmu";
    print "$cmdline\n";
    system("$cmdline");

    # convert byte-Chinese to symbol
    $dir = "$PLMTK::databasedir/intermediate/lab_cmu";
    mkdir "$PLMTK::databasedir/intermediate/lab", 0755;
    opendir(DIR, $dir) or die $!;
    while (my $file = readdir(DIR)) {
        next unless (-f "$dir/$file");
        # Use a regular expression to find files ending in .lab
        next unless ($file =~ m/\.lab$/);
        my($basename)=basename($file, '.lab');
        $cmdline = "$PLMTK::progbasedir/$PLMTK::LAB2SYM $PLMTK::databasedir/intermediate/lab_cmu/$basename.lab $PLMTK::databasedir/intermediate/lab/$basename.tmplab";
        system("$cmdline");

        # replace sil within an utterance with sp
        # awk -F '\ ' -v OFS='\ ' '/sil/{$3="sp"}7'  George-WSJ-Adp-0001.lab
        $cmdline = "awk -F ' ' -v OFS=' ' '/sil/{\$3=\"sp\"}7'  $PLMTK::databasedir/intermediate/lab/$basename.tmplab | awk -F ' ' -v OFS=' ' '/sp sil/{\$3=\"sil\"}7' > $PLMTK::databasedir/intermediate/lab/$basename.lab";
        print "$cmdline\n";
        system("$cmdline");
    }
    $cmdline        = "rm -f $PLMTK::databasedir/intermediate/lab/*.tmplab";
    print "$cmdline\n";
    system("$cmdline");
    closedir(DIR);
}

# forced-alignment by using HTK for English
if ($PLMTK::WSJFA) {
    &print_time("forced-alignment by using HTK for English");
    # edit dict 
    $cmdline = "$PLMTK::progbasedir/$PLMTK::MKWSJDICT $PLMTK::databasedir/intermediate/bu_radio_dict_with_syl $PLMTK::databasedir/intermediate/wsjdict";
    print "$cmdline\n";
    system("$cmdline");

    # make mfcc.scp
    chdir "$PLMTK::databasedir/intermediate/";
    system("rm -rf $PLMTK::databasedir/intermediate/mfcc_wsj.scp");
    mkdir "$PLMTK::databasedir/intermediate/mfc_wsj", 0755;
    my $dir = "$PLMTK::databasedir/intermediate/wav16k";
    opendir(DIR, $dir) or die $!;
    while (my $file = readdir(DIR)) {
        next unless (-f "$dir/$file");
        # Use a regular expression to find files ending in .wav
        # next unless ($file =~ m/\.wav$/);
        # Rickie-WSJ-
        next unless ($file =~ m/^$PLMTK::PURE_ENG_UTT_STR/);
        my($basename)=basename($file, '.wav');
        $cmdline = "echo $PLMTK::databasedir/intermediate/wav16k/$basename.wav $PLMTK::databasedir/intermediate/mfc_wsj/$basename.mfc >> $PLMTK::databasedir/intermediate/mfcc_wsj.scp";
        system("$cmdline");
    }
    closedir(DIR);

    # HCopy
    #$cmdline = "$HCOPY  -T 1 -C $PLMTK::databasedir/intermediate/configs/configwav -C $PLMTK::databasedir/intermediate/configs/config -C $PLMTK::databasedir/intermediate/configs/config_wsj -S $PLMTK::databasedir/intermediate/mfcc.scp";
    $cmdline = "$PLMTK::HCOPY  -T 1 -C $PLMTK::progbasedir/dp/htk_wsj/configwav -C $PLMTK::progbasedir/dp/htk_wsj/config -C $PLMTK::progbasedir/dp/htk_wsj/config_wsj -S $PLMTK::databasedir/intermediate/mfcc_wsj.scp";
    system("$cmdline");

    # make mlf.scp
    system("rm -rf $PLMTK::databasedir/intermediate/mlf_wsj.scp");
    $dir = "$PLMTK::databasedir/intermediate/mfc_wsj";
    opendir(DIR, $dir) or die $!;
    while (my $file = readdir(DIR)) {
        next unless (-f "$dir/$file");
        # Use a regular expression to find files ending in .mfc
        next unless ($file =~ m/\.mfc$/);
        my($basename)=basename($file, '.mfc');
        $cmdline = "echo $PLMTK::databasedir/intermediate/mfc_wsj/$basename.mfc >> $PLMTK::databasedir/intermediate/mlf_wsj.scp";
        system("$cmdline");
    }
    closedir(DIR);

    # HVite
    $cmdline = "$PLMTK::HVITE -T 1 -a -b sil -m -o S -C $PLMTK::progbasedir/dp/htk_wsj/configcross -H $PLMTK::progbasedir/dp/htk_wsj/macros -H $PLMTK::progbasedir/dp/htk_wsj/hmmdefs -m -t 350 -I $PLMTK::databasedir/intermediate/all.mlf -i $PLMTK::databasedir/intermediate/all_wsj.lab -S $PLMTK::databasedir/intermediate/mlf_wsj.scp $PLMTK::databasedir/intermediate/wsjdict $PLMTK::progbasedir/dp/htk_wsj/monolist";
    print "$cmdline\n";
    system("$cmdline");

    # dispatch lab file from aligned all.lab
    mkdir "$PLMTK::databasedir/intermediate/lab_wsj", 0755;
    $cmdline = "$PLMTK::progbasedir/$PLMTK::LABDISP $PLMTK::databasedir/intermediate/all_wsj.lab $PLMTK::databasedir/intermediate/lab_wsj";
    print "$cmdline\n";
    system("$cmdline");

    # convert lowercases phonemes to uppercase phonemes and convert sil within an utterance to sp 
    mkdir "$PLMTK::databasedir/intermediate/lab_wsj_plmtk", 0755;
    $dir = "$PLMTK::databasedir/intermediate/lab_wsj";
    opendir(DIR, $dir) or die $!;
    while (my $file = readdir(DIR)) {
        next unless (-f "$dir/$file");
        # Use a regular expression to find files ending in .mfc
        next unless ($file =~ m/\.lab$/);
        my($basename)=basename($file, '.lab');
        $cmdline = "$PLMTK::progbasedir/$PLMTK::LABWSJ2PLMTK $PLMTK::databasedir/intermediate/lab_wsj/$basename.lab $PLMTK::databasedir/intermediate/lab_wsj_plmtk/$basename.lab";
        print "$cmdline\n";
        system("$cmdline");
        $cmdline = "cp -f $PLMTK::databasedir/intermediate/lab_wsj_plmtk/$basename.lab $PLMTK::databasedir/intermediate/lab/$basename.lab";
        print "$cmdline\n";
        system("$cmdline");
    }
    closedir(DIR);
}

# refinement of short pause boundaries
if ($PLMTK::SPREF) {
    &print_time("refinement of short pause boundaries");
    chdir "$PLMTK::databasedir/intermediate/";
    system("rm -r $PLMTK::databasedir/intermediate/lab.scp");
    my $dir = "$PLMTK::databasedir/intermediate/lab";
    mkdir "$PLMTK::databasedir/intermediate/lab_sprefined", 0755;
    opendir(DIR, $dir) or die $!;
    while (my $file = readdir(DIR)) {
        next unless (-f "$dir/$file");
        # Use a regular expression to find files ending in .lab
        next unless ($file =~ m/\.lab$/);
        my($basename)=basename($file, '.lab');
        $cmdline = "echo $basename >> $PLMTK::databasedir/intermediate/lab.scp";
        system("$cmdline");
    }
    closedir(DIR);
    $cmdline = "$PLMTK::progbasedir/$PLMTK::SPREFINE $PLMTK::databasedir/intermediate/lab.scp $PLMTK::databasedir/intermediate/raw16k $PLMTK::databasedir/intermediate/lab $PLMTK::databasedir/intermediate/lab_sprefined $PLMTK::progbasedir/dp/sprefine/phoneme_table.txt 1 -100";
    print "$cmdline\n";
    system("$cmdline");
}

# segment-refinement by attribute recognition score
if ($PLMTK::SGREF) {
    mkdir "$PLMTK::databasedir/intermediate/lab_segrefine", 0755;


    system("rm -rf $PLMTK::databasedir/intermediate/dp_segrefine.m");
    system('touch $PLMTK::databasedir/intermediate/dp_segrefine.m');
    $cmdline = "echo addpath\\(\\'$PLMTK::progbasedir/dp/segrefine/\\'\\)\\; >> $PLMTK::databasedir/intermediate/dp_segrefine.m";
    print "$cmdline\n";
    system("$cmdline");

    mkdir "$PLMTK::databasedir/intermediate/att", 0755;
    mkdir "$PLMTK::databasedir/intermediate/att_tmp", 0755;

    # extraction of 5ms-intervel attribute score
    chdir "$PLMTK::progbasedir/dp/segrefine/mkatt";
    $cmdline = "sh $PLMTK::progbasedir/$PLMTK::MKATT $PLMTK::databasedir/intermediate/wav16k $PLMTK::databasedir/intermediate/att $PLMTK::progbasedir/dp/segrefine/mkatt/out_E120_dnn.pkl  $PLMTK::databasedir/intermediate/att_tmp 10 0 0";
    print "$cmdline\n";
    system("$cmdline");
    chdir "$PLMTK::databasedir/intermediate/";


    # refine segmentation with attribute score
    my $dir = "$PLMTK::databasedir/intermediate/lab";
    opendir(DIR, $dir) or die $!;
    while (my $file = readdir(DIR)) {
        next unless (-f "$dir/$file");
        # Use a regular expression to find files ending in .lab
        next unless ($file =~ m/\.lab$/);
        my($basename)=basename($file, '.lab');        
        $cmdline = "echo segrefine\\(\\'$dir/$basename.lab\\',\\'$PLMTK::databasedir/intermediate/att/$basename.att\\', \\'HMM2Att.txt\\', \\'AttState.txt\\', \\'$PLMTK::databasedir/intermediate/lab_segrefine/$basename.lab\\'\\)\\; >> $PLMTK::databasedir/intermediate/dp_segrefine.m";
        print "$cmdline\n";
        system("$cmdline");
    }
    closedir(DIR);
    $cmdline = "$PLMTK::MATLABDIR/$PLMTK::MATLAB < $PLMTK::databasedir/intermediate/dp_segrefine.m";
    print "$cmdline\n";
    system("$cmdline");    
}


# refinement of unvoiced/voiced segment boundaries
if ($PLMTK::UVREF) {
    &print_time("refinement of unvoiced/voiced segment boundaries");
    chdir "$PLMTK::databasedir/intermediate/";
    #system("rm -r $PLMTK::databasedir/intermediate/lab.scp");
    my $dir = "$PLMTK::databasedir/intermediate/lab";
    mkdir "$PLMTK::databasedir/intermediate/lab_uvrefined", 0755;
    opendir(DIR, $dir) or die $!;
    while (my $file = readdir(DIR)) {
        next unless (-f "$dir/$file");
        # Use a regular expression to find files ending in .lab
        next unless ($file =~ m/\.lab$/);
        my($basename)=basename($file, '.lab');
        $cmdline = "echo $basename >> $PLMTK::databasedir/intermediate/lab.scp";
    #    system("$cmdline");
    }
    closedir(DIR);
    if ($PLMTK::SPREF) {
        $cmdline = "$PLMTK::progbasedir/$PLMTK::UVREFINE $PLMTK::databasedir/intermediate/lab.scp $PLMTK::databasedir/intermediate/raw16k $PLMTK::databasedir/intermediate/lab_sprefined $PLMTK::databasedir/intermediate/lab_uvrefined $PLMTK::progbasedir/dp/uvrefine/phoneme_table.txt 1 -100";
    }
    else {
        $cmdline = "$PLMTK::progbasedir/$PLMTK::UVREFINE $PLMTK::databasedir/intermediate/lab.scp $PLMTK::databasedir/intermediate/raw16k $PLMTK::databasedir/intermediate/lab $PLMTK::databasedir/intermediate/lab_uvrefined $PLMTK::progbasedir/dp/uvrefine/phoneme_table.txt 1 -100";
    }
    print "$cmdline\n";
    system("$cmdline");
}

# normalize/check TextGrid files
if ($PLMTK::TXGNM) {
    &print_time("normalize/check TextGrid files");
    chdir "$PLMTK::databasedir/intermediate/";
    my $dir = "$PLMTK::databasedir/in/TextGrid-fused";
    mkdir "$PLMTK::databasedir/out/TextGrid-norm", 0755;
    opendir(DIR, $dir) or die $!;
    while (my $file = readdir(DIR)) {
        next unless (-f "$dir/$file");
        # Use a regular expression to find files ending in .lab
        next unless ($file =~ m/\.TextGrid$/);
        my($basename)=basename($file, '.TextGrid');
        $cmdline = "$PLMTK::progbasedir/$PLMTK::TEXTGRIDNORM $PLMTK::databasedir/in/TextGrid-fused/$basename.TextGrid $PLMTK::databasedir/out/TextGrid-norm/$basename.TextGrid";
        print "$cmdline\n";
        system("$cmdline");
    }
    closedir(DIR);
}

# convert TextGrid to mul
if ($PLMTK::TXG2M) {
    &print_time("convert TextGrid to mul");
    chdir "$PLMTK::databasedir/intermediate/";
    my $dir = "$PLMTK::databasedir/in/TextGrid";
    mkdir "$PLMTK::databasedir/intermediate/mul", 0755;
    opendir(DIR, $dir) or die "Cannot find $dir\nPlease remember to copy TextGrid to the folder $PLMTK::databasedir/in/TextGrid)";
    while (my $file = readdir(DIR)) {
        next unless (-f "$dir/$file");
        # Use a regular expression to find files ending in .TextGrid
        next unless ($file =~ m/\.TextGrid$/);
        my($basename)=basename($file, '.TextGrid');
        $cmdline = "$PLMTK::progbasedir/$PLMTK::TEXTGRID2MUL $PLMTK::databasedir/in/TextGrid/$basename.TextGrid $PLMTK::databasedir/intermediate/mul/$basename.mul";
        print "$cmdline\n";
        system("$cmdline");
    }
    closedir(DIR);
}

# generation of mul files
if ($PLMTK::MULGN) {
    &print_time("generation of mul files");
    chdir "$PLMTK::databasedir/intermediate/";
    my $dir = "$PLMTK::databasedir/intermediate/lab";
    mkdir "$PLMTK::databasedir/intermediate/mul", 0755;
    opendir(DIR, $dir) or die $!;
    while (my $file = readdir(DIR)) {
        next unless (-f "$dir/$file");
        # Use a regular expression to find files ending in .lab
        next unless ($file =~ m/\.lab$/);
        my($basename)=basename($file, '.lab');
        if($PLMTK::SGREF) {
            $cmdline = "$PLMTK::progbasedir/$PLMTK::MULGEN $PLMTK::databasedir/intermediate/lab_segrefine/$basename.lab $PLMTK::databasedir/intermediate/ala/$basename.ala $PLMTK::databasedir/intermediate/mul/$basename.mul $PLMTK::databasedir/intermediate/bu_radio_dict_with_syl";
        }
        else {
            if ($PLMTK::SPREF) {
                if($PLMTK::UVREF) {
                    $cmdline = "$PLMTK::progbasedir/$PLMTK::MULGEN $PLMTK::databasedir/intermediate/lab_uvrefined/$basename.lab $PLMTK::databasedir/intermediate/ala/$basename.ala $PLMTK::databasedir/intermediate/mul/$basename.mul $PLMTK::databasedir/intermediate/bu_radio_dict_with_syl";
                }
                else {
                    $cmdline = "$PLMTK::progbasedir/$PLMTK::MULGEN $PLMTK::databasedir/intermediate/lab_sprefined/$basename.lab $PLMTK::databasedir/intermediate/ala/$basename.ala $PLMTK::databasedir/intermediate/mul/$basename.mul $PLMTK::databasedir/intermediate/bu_radio_dict_with_syl";
                }
            }
            else {
                if($PLMTK::UVREF) {
                    $cmdline = "$PLMTK::progbasedir/$PLMTK::MULGEN $PLMTK::databasedir/intermediate/lab_uvrefined/$basename.lab $PLMTK::databasedir/intermediate/ala/$basename.ala $PLMTK::databasedir/intermediate/mul/$basename.mul $PLMTK::databasedir/intermediate/bu_radio_dict_with_syl";
                }
                else {
                    $cmdline = "$PLMTK::progbasedir/$PLMTK::MULGEN $PLMTK::databasedir/intermediate/lab/$basename.lab $PLMTK::databasedir/intermediate/ala/$basename.ala $PLMTK::databasedir/intermediate/mul/$basename.mul $PLMTK::databasedir/intermediate/bu_radio_dict_with_syl";
                }
            }
        }
        print "$cmdline\n";
        system("$cmdline");
    }
    closedir(DIR);
}

# convert mul files to TextGrid files
if($PLMTK::M2TXG) {
    &print_time("convert mul files to TextGrid files");
    chdir "$PLMTK::databasedir/intermediate/";
    my $dir = "$PLMTK::databasedir/intermediate/mul";
    mkdir "$PLMTK::databasedir/out/TextGrid", 0755;
    opendir(DIR, $dir) or die $!;
    while (my $file = readdir(DIR)) {
        next unless (-f "$dir/$file");
        # Use a regular expression to find files ending in .lab
        next unless ($file =~ m/\.mul$/);
        my($basename)=basename($file, '.mul');
        $cmdline = "$PLMTK::progbasedir/$PLMTK::MUL2TEXTGRID $PLMTK::databasedir/intermediate/mul/$basename.mul $PLMTK::databasedir/out/TextGrid/$basename.TextGrid";
        print "$cmdline\n";
        system("$cmdline");
    }
    closedir(DIR);
}

# extract frame F0 with 10ms frame interval
if ($PLMTK::F0EXT) {
    &print_time("extract frame F0 with 10ms frame interval");
    chdir "$PLMTK::databasedir/intermediate/";
    my $dir = "$PLMTK::databasedir/intermediate/raw16k";
    mkdir "$PLMTK::databasedir/intermediate/f0", 0755;
    opendir(DIR, $dir) or die $!;
    while (my $file = readdir(DIR)) {
        next unless (-f "$dir/$file");
        # Use a regular expression to find files ending in .lab
        next unless ($file =~ m/\.raw$/);
        my($basename)=basename($file, '.raw');
        $cmdline =  "$PLMTK::X2X +sf $dir/$file | $PLMTK::PITCH -p 160 -L $PLMTK::LOWERF0HZ -H $PLMTK::UPPERF0HZ -o 1 | $PLMTK::X2X +fa > $PLMTK::databasedir/intermediate/f0/$basename.f0";
        print "$cmdline\n";
        system("$cmdline");
    }
    closedir(DIR);
}

# extract frame F0 with 5ms frame interval and make pitch marks
if ($PLMTK::F0PMK) {
    &print_time("extract frame F0 with 5ms frame interval and make pitch marks");
	mkdir "$PLMTK::databasedir/out/cos", 0755;
    mkdir "$PLMTK::databasedir/out/pmlab", 0755;
    mkdir "$PLMTK::databasedir/out/f0in", 0755;
    mkdir "$PLMTK::databasedir/out/f0out", 0755;

    # extraction of 5ms-intervel F0
    my $dir = "$PLMTK::databasedir/intermediate/raw16k";
    opendir(DIR, $dir) or die $!;
    while (my $file = readdir(DIR)) {
        next unless (-f "$dir/$file");
        # Use a regular expression to find files ending in .lab
        next unless ($file =~ m/\.raw$/);
        my($basename)=basename($file, '.raw');
        $cmdline =  "$PLMTK::X2X +sf $dir/$file | $PLMTK::PITCH -p 80 -L $PLMTK::LOWERF0HZ -H $PLMTK::UPPERF0HZ -o 1 | $PLMTK::X2X +fa > $PLMTK::databasedir/out/f0in/$basename.f0";
        print "$cmdline\n";
        system("$cmdline");
    }
    closedir(DIR);

    # find statistics of f (central frequnecy) and a (chirp rate)
    system("rm -rf $PLMTK::databasedir/intermediate/f0_pmcosgen.lst");
    system("touch $PLMTK::databasedir/intermediate/f0_pmcosgen.lst");
    my $f0dir = "$PLMTK::databasedir/out/f0in";
    opendir(DIR, $f0dir) or die $!;
    while (my $file = readdir(DIR)) {
         next unless (-f "$f0dir/$file");
         # Use a regular expression to find files ending in .lab
         next unless ($file =~ m/\.f0$/);
         my($basename)=basename($file, '.f0');
         $cmdline =  "echo $f0dir/$file >> $PLMTK::databasedir/intermediate/f0_pmcosgen.lst";
         print "$cmdline\n";
         system("$cmdline");
    }
    closedir(DIR);

    system("rm -rf $PLMTK::databasedir/intermediate/vm_pmcosgen_fa_statistics.m");
    system('touch $PLMTK::databasedir/intermediate/vm_pmcosgen_fa_statistics.m');
    $cmdline = "echo addpath\\(\\'$PLMTK::progbasedir/vm/pmcosgen/\\'\\)\\; >> $PLMTK::databasedir/intermediate/vm_pmcosgen_fa_statistics.m";
    print "$cmdline\n";
    system("$cmdline");
    $cmdline = "echo pmcosgen_fa_statistics\\(\\'$PLMTK::databasedir/intermediate/f0_pmcosgen.lst\\', 50, 550, 0.1, 0.1, \\'$PLMTK::databasedir/intermediate/fa_stats.mat\\'\\)\\; >> $PLMTK::databasedir/intermediate/vm_pmcosgen_fa_statistics.m";
    print "$cmdline\n";
    system("$cmdline");
    $cmdline = "$PLMTK::MATLABDIR/$PLMTK::MATLAB < $PLMTK::databasedir/intermediate/vm_pmcosgen_fa_statistics.m";
    print "$cmdline\n";
    system("$cmdline");


    # generating proxy projection/reconstruction matrices
    system("rm -rf $PLMTK::databasedir/intermediate/vm_pmcosgen_genProMatrix.m");
    system('touch $PLMTK::databasedir/intermediate/vm_pmcosgen_genProMatrix.m');
    $cmdline = "echo addpath\\(\\'$PLMTK::progbasedir/vm/pmcosgen/\\'\\)\\; >> $PLMTK::databasedir/intermediate/vm_pmcosgen_genProMatrix.m";
    print "$cmdline\n";
    system("$cmdline");
    $cmdline = "echo fa_proxy = genProMatrix_batch\\(\\'$PLMTK::databasedir/intermediate/fa_stats.mat\\', 200, 50, \\'$PLMTK::databasedir/intermediate/fa_proxy.mat\\'\\)\\; >> $PLMTK::databasedir/intermediate/vm_pmcosgen_genProMatrix.m";
    print "$cmdline\n";
    system("$cmdline");

    opendir(DIR, $dir) or die $!;
    while (my $file = readdir(DIR)) {
        next unless (-f "$dir/$file");
        # Use a regular expression to find files ending in .wav
        next unless ($file =~ m/\.raw$/);
        my($basename)=basename($file, '.raw');        
        $cmdline = "echo pmcosgen_proxy\\(\\'$dir/$basename.raw\\',\\'$PLMTK::databasedir/out/f0in/$basename.f0\\', \\'$PLMTK::databasedir/out/cos/$basename.res.wav\\', \\'$PLMTK::databasedir/out/cos/$basename.cos.wav\\'\\, \\'$PLMTK::databasedir/out/cos/$basename.fag\\'\\, fa_proxy\\)\\; >> $PLMTK::databasedir/intermediate/vm_pmcosgen_genProMatrix.m";
        print "$cmdline\n";
        system("$cmdline");
    }
    closedir(DIR);
    $cmdline = "$PLMTK::MATLABDIR/$PLMTK::MATLAB < $PLMTK::databasedir/intermediate/vm_pmcosgen_genProMatrix.m";
    print "$cmdline\n";
    system("$cmdline");

    


    # my $nThread=1;
    # for (my $i=0; $i < $nThread; $i++) {
    #     system("rm -rf $PLMTK::databasedir/intermediate/vm_pmcosgen_$i.m");
    #     system('touch $PLMTK::databasedir/intermediate/vm_pmcosgen_$i.m');
    #     $cmdline = "echo addpath\\(\\'$PLMTK::progbasedir/vm/pmcosgen/\\'\\)\\; >> $PLMTK::databasedir/intermediate/vm_pmcosgen_$i.m";
    #     print "$cmdline\n";
    #     system("$cmdline");
    # }

    # my $i=0;
    # opendir(DIR, $dir) or die $!;
    # while (my $file = readdir(DIR)) {
    #     next unless (-f "$dir/$file");
    #     # Use a regular expression to find files ending in .wav
    #     next unless ($file =~ m/\.raw$/);
    #     my($basename)=basename($file, '.raw');
    #     #$cmdline = "$PLMTK::progbasedir/vm/pmcosgen/pmcosgen $dir/$basename.raw $PLMTK::databasedir/out/f0in/$basename.f0 $PLMTK::databasedir/out/pmlab/$basename.lab $PLMTK::databasedir/out/cos/$basename.cos $PLMTK::databasedir/out/f0out/$basename.f0";
    #     #print "$cmdline\n";
    #     #system("$cmdline");
    #     #pmcosgen('Rebecca-WSJ-a166.raw', 'Rebecca-WSJ-a166.f0', 'Rebecca-WSJ-a166.reconstructed.wav', 'Rebecca-WSJ-a166.cos.wav');

    #     $cmdline = "echo pmcosgen_proxy\\(\\'$dir/$basename.raw\\',\\'$PLMTK::databasedir/out/f0in/$basename.f0\\', \\'$PLMTK::databasedir/out/cos/$basename.res.wav\\', \\'$PLMTK::databasedir/out/cos/$basename.cos.wav\\'\\, \\'$PLMTK::databasedir/intermediate/fa_proxy.mat\\'\\)\\; >> $PLMTK::databasedir/intermediate/vm_pmcosgen_$i.m";
    #     print "$cmdline\n";
    #     system("$cmdline");
    #     $i = $i + 1;
    #     if($i >=$nThread ){ $i = $i - $nThread; }
    # }
    # closedir(DIR);
    

    # system("rm -rf $PLMTK::databasedir/intermediate/run_pmcosgen.sh");
    # system("touch $PLMTK::databasedir/intermediate/run_pmcosgen.sh");
    # system("chmod 755 $PLMTK::databasedir/intermediate/run_pmcosgen.sh");
    # system("echo \\#!/bin/sh >> $PLMTK::databasedir/intermediate/run_pmcosgen.sh");
    # for ($i=0; $i < $nThread; $i++) {
    #     $cmdline = "echo $PLMTK::MATLABDIR/$PLMTK::MATLAB \\< $PLMTK::databasedir/intermediate/vm_pmcosgen_$i.m \\& >> $PLMTK::databasedir/intermediate/run_pmcosgen.sh";
    #     print "$cmdline\n";
    #     system("$cmdline");
    # }
    # system("echo wait >> $PLMTK::databasedir/intermediate/run_pmcosgen.sh");
    # #$cmdline = "$PLMTK::MATLABDIR/$PLMTK::MATLAB < $PLMTK::databasedir/intermediate/vm_pmcosgen.m";
    # #print "$cmdline\n";
    # system("sh $PLMTK::databasedir/intermediate/run_pmcosgen.sh");

    
}

 # filter out extracted f0 from non-speech segments
if ($PLMTK::F0FLT) {
    &print_time("filter out extracted f0 from non-speech segments");
    chdir "$PLMTK::databasedir/intermediate/";
    system("rm -rf $PLMTK::databasedir/intermediate/f0.scp");
    my $dir = "$PLMTK::databasedir/intermediate/f0";
    mkdir "$PLMTK::databasedir/intermediate/ff0", 0755;
    opendir(DIR, $dir) or die $!;
    while (my $file = readdir(DIR)) {
        next unless (-f "$dir/$file");
        # Use a regular expression to find files ending in .lab
        next unless ($file =~ m/\.f0$/);
        my($basename)=basename($file, '.f0');
        $cmdline = "echo $PLMTK::databasedir/intermediate/f0/$basename.f0 >> $PLMTK::databasedir/intermediate/f0.scp";
        system("$cmdline");
    }
    closedir(DIR);
    if ($PLMTK::UVREF) { 
        $cmdline = "$PLMTK::progbasedir/$PLMTK::F0FILTER $PLMTK::databasedir/intermediate/f0.scp lab $PLMTK::databasedir/intermediate/lab_uvrefined/ $PLMTK::databasedir/intermediate/ff0/";
    }
    else {
        $cmdline = "$PLMTK::progbasedir/$PLMTK::F0FILTER $PLMTK::databasedir/intermediate/f0.scp mul $PLMTK::databasedir/intermediate/mul/ $PLMTK::databasedir/intermediate/ff0/";
    }
    print "$cmdline\n";
    system("$cmdline");
}

# take log of frame f0
if ($PLMTK::F0TKL) {
    &print_time("take log of frame f0");
    chdir "$PLMTK::databasedir/intermediate/";
    system("rm -rf $PLMTK::databasedir/intermediate/ff0.scp");
    my $dir = "$PLMTK::databasedir/intermediate/ff0";
    mkdir "$PLMTK::databasedir/intermediate/lf0", 0755;
    opendir(DIR, $dir) or die $!;
    while (my $file = readdir(DIR)) {
        next unless (-f "$dir/$file");
        # Use a regular expression to find files ending in .lab
        next unless ($file =~ m/\.f0$/);
        my($basename)=basename($file, '.f0');
        $cmdline = "echo $PLMTK::databasedir/intermediate/ff0/$basename.f0 >> $PLMTK::databasedir/intermediate/ff0.scp";
        system("$cmdline");
    }
    closedir(DIR);
    $cmdline = "$PLMTK::progbasedir/$PLMTK::F0TKLOG $PLMTK::databasedir/intermediate/ff0.scp $PLMTK::databasedir/intermediate/lf0/";
    print "$cmdline\n";
    system("$cmdline");
}

# frame power extraction
if ($PLMTK::FRMPR) {
    &print_time("frame power extraction");
    chdir "$PLMTK::databasedir/intermediate/";
    my $dir = "$PLMTK::databasedir/intermediate/raw16k";
    mkdir "$PLMTK::databasedir/intermediate/pwr", 0755;
    opendir(DIR, $dir) or die $!;
    while (my $file = readdir(DIR)) {
        next unless (-f "$dir/$file");
        # Use a regular expression to find files ending in .raw
        next unless ($file =~ m/\.raw$/);
        my($basename)=basename($file, '.raw');
        $cmdline =  "$PLMTK::progbasedir/$PLMTK::PWR $dir/$file $PLMTK::databasedir/intermediate/pwr/$basename.pwr";
        print "$cmdline\n";
        system("$cmdline");
    }
    closedir(DIR);
}

if ($PLMTK::MKALP) {
    chdir "$PLMTK::databasedir/intermediate/";
    mkdir "$PLMTK::databasedir/intermediate/al", 0755;
    system("rm -rf $PLMTK::databasedir/intermediate/mul.scp");
    my $dir = "$PLMTK::databasedir/intermediate/mul";
    opendir(DIR, $dir) or die $!;
    while (my $file = readdir(DIR)) {
        next unless (-f "$dir/$file");
        # Use a regular expression to find files ending in .wav
        next unless ($file =~ m/\.mul$/);
        my($basename)=basename($file, '.mul');
        $cmdline = "echo $basename >> $PLMTK::databasedir/intermediate/mul.scp";
        system("$cmdline");
    }
    closedir(DIR);
    $cmdline =  "$PLMTK::progbasedir/$PLMTK::MKAL $PLMTK::databasedir/intermediate/mul.scp $PLMTK::databasedir/intermediate/mul $PLMTK::databasedir/intermediate/lf0 $PLMTK::databasedir/intermediate/pwr $PLMTK::databasedir/intermediate/al/all.al";
    print "$cmdline\n";
    system("$cmdline");
}

if ($PLMTK::GENTB) {
    chdir "$PLMTK::databasedir/intermediate/";
    system("rm -r $PLMTK::databasedir/intermediate/plm_gentb.m");
    $cmdline = "echo addpath\\(\\'$PLMTK::progbasedir/plm/gentable/\\'\\)\\; >> $PLMTK::databasedir/intermediate/plm_gentb.m";
    print "$cmdline\n";
    system("$cmdline");

    $cmdline = "echo GeneratePhoneticTables\\(\\'syllable_vowel.xlsx\\'\\)\\; >> $PLMTK::databasedir/intermediate/plm_gentb.m";
    print "$cmdline\n";
    system("$cmdline");

    $cmdline = "$PLMTK::MATLABDIR/$PLMTK::MATLAB < $PLMTK::databasedir/intermediate/plm_gentb.m";
    print "$cmdline\n";
    system("$cmdline");
}

if ($PLMTK::DTSET) {
    chdir "$PLMTK::databasedir/intermediate/";
    printf("split data into subsets of adaptation and test sets\n");
    printf("setting up list files for lf0 normalizations for subsets\n");
    mkdir "$PLMTK::databasedir/intermediate/plm_scp", 0777;
    system("rm -r $PLMTK::databasedir/intermediate/plm_datasubset.m");
    $cmdline = "echo addpath\\(\\'$PLMTK::progbasedir/plm/datasubset/\\'\\)\\; >> $PLMTK::databasedir/intermediate/plm_datasubset.m";
    print "$cmdline\n";
    system("$cmdline");
    $cmdline = "echo datasubset\\(\\'$PLMTK::databasedir/intermediate/al/all.al\\',\\'$PLMTK::databasedir/intermediate\\', \\'$PLMTK::databasedir/intermediate/plm_scp\\', $PLMTK::ADP_PORTION,$PLMTK::TEST_PORTION\\)\\; >> $PLMTK::databasedir/intermediate/plm_datasubset.m";
    print "$cmdline\n";
    system("$cmdline");
    $cmdline = "$PLMTK::MATLABDIR/$PLMTK::MATLAB < $PLMTK::databasedir/intermediate/plm_datasubset.m";
    print "$cmdline\n";
    system("$cmdline");
    printf("lf0 normalization for subsets\n");
}

if ($PLMTK::LF0NM) {
    chdir "$PLMTK::databasedir/intermediate/";
    my $dir = "$PLMTK::databasedir/intermediate/plm_scp";
    mkdir "$PLMTK::databasedir/intermediate/lf0mustd", 0755;
    opendir(DIR, $dir) or die $!;
    while (my $file = readdir(DIR)) {
        next unless (-f "$dir/$file");
        # Use a regular expression to find files ending in .wav
        next unless ($file =~ m/\.lst$/);
        my($basename)=basename($file, '.lst');
        $cmdline = "$PLMTK::progbasedir/$PLMTK::FRMLF0MUSTD $PLMTK::databasedir/intermediate/plm_scp/$basename.lst $PLMTK::databasedir/intermediate/lf0mustd/$basename.mustd";
        print "$cmdline\n";
        system("$cmdline");
        $cmdline = "$PLMTK::progbasedir/$PLMTK::FRMLF0NRM $PLMTK::databasedir/intermediate/plm_scp/$basename.adp.scp $PLMTK::databasedir/intermediate/lf0mustd/$basename.mustd  $PLMTK::progbasedir/dp/frmlf0nrm/lf0.normal.mustd";
        print "$cmdline\n";
        system("$cmdline");
        $cmdline = "$PLMTK::progbasedir/$PLMTK::FRMLF0NRM $PLMTK::databasedir/intermediate/plm_scp/$basename.test.scp $PLMTK::databasedir/intermediate/lf0mustd/$basename.mustd $PLMTK::progbasedir/dp/frmlf0nrm/lf0.normal.mustd";
        print "$cmdline\n";
        system("$cmdline");
    }
    closedir(DIR);
}

if ($PLMTK::MKALS) {
    chdir "$PLMTK::databasedir/intermediate/";
    my $dir = "$PLMTK::databasedir/intermediate/plm_scp";
    opendir(DIR, $dir) or die $!;
    while (my $file = readdir(DIR)) {
        next unless (-f "$dir/$file");
        # Use a regular expression to find files ending in .wav
        next unless ($file =~ m/mul/);
        my($basename)=basename($file, '.scp');
        $cmdline =  "$PLMTK::progbasedir/$PLMTK::MKAL $PLMTK::databasedir/intermediate/plm_scp/$basename.scp $PLMTK::databasedir/intermediate/mul $PLMTK::databasedir/intermediate/nrmlf0/$basename $PLMTK::databasedir/intermediate/pwr $PLMTK::databasedir/intermediate/al/$basename.al";
        print "$cmdline\n";
        system("$cmdline");
    }
    closedir(DIR);
}

if ($PLMTK::ALSTS) {
    chdir "$PLMTK::databasedir/intermediate/";
    printf("produce statistics of each subset\n");
    my $dir = "$PLMTK::databasedir/intermediate/al";
    system("rm -rf $PLMTK::databasedir/intermediate/al.scp");
    opendir(DIR, $dir) or die $!;
    while (my $file = readdir(DIR)) {
        next unless (-f "$dir/$file");
        # Use a regular expression to find files ending in .wav
        next unless ($file =~ m/\.al$/);
        my($basename)=basename($file, '.al');
        $cmdline = "echo $PLMTK::databasedir/intermediate/al/$basename.al >> $PLMTK::databasedir/intermediate/al.scp";
        print "$cmdline\n";
        system("$cmdline");
    }
    closedir(DIR);

    system("rm -r $PLMTK::databasedir/intermediate/plm_datastats.m");
    $cmdline = "echo addpath\\(\\'$PLMTK::progbasedir/plm/datastats/\\'\\)\\; >> $PLMTK::databasedir/intermediate/plm_datastats.m";
    print "$cmdline\n";
    system("$cmdline");
    $cmdline = "echo datastats\\(\\'$PLMTK::databasedir/intermediate/al.scp\\',\\'$PLMTK::databasedir/intermediate/subsets_stats.txt\\'\\)\\; >> $PLMTK::databasedir/intermediate/plm_datastats.m";
    print "$cmdline\n";
    system("$cmdline");
    $cmdline = "$PLMTK::MATLABDIR/$PLMTK::MATLAB < $PLMTK::databasedir/intermediate/plm_datastats.m";
    print "$cmdline\n";
    system("$cmdline");

}

if ($PLMTK::TRECG) {
    chdir "$PLMTK::databasedir/intermediate/";
    system("rm -r $PLMTK::databasedir/intermediate/plm_tonerec.m");
    $cmdline = "echo addpath\\(\\'$PLMTK::progbasedir/plm/tonerec/\\'\\)\\; >> $PLMTK::databasedir/intermediate/plm_tonerec.m";
    print "$cmdline\n";
    system("$cmdline");
    $cmdline = "echo ToneRec\\(\\'$PLMTK::databasedir/intermediate/al/mul.f10.adp.al\\',\\'$PLMTK::databasedir/intermediate/al/plm.al\\'\\)\\; >> $PLMTK::databasedir/intermediate/plm_tonerec.m";
    print "$cmdline\n";
    system("$cmdline");
    $cmdline = "$PLMTK::MATLABDIR/$PLMTK::MATLAB < $PLMTK::databasedir/intermediate/plm_tonerec.m";
    print "$cmdline\n";
    system("$cmdline");
}

if ($PLMTK::NRADP) {
    chdir "$PLMTK::databasedir/intermediate/";
    system("rm -r $PLMTK::databasedir/intermediate/plm_normadp.m");
    $cmdline = "echo addpath\\(\\'$PLMTK::progbasedir/plm/normadp/\\'\\)\\; >> $PLMTK::databasedir/intermediate/plm_normadp.m";
    print "$cmdline\n";
    system("$cmdline");
    $cmdline = "echo NormAdp\\(\\'$PLMTK::databasedir/intermediate/al/plm.al\\',\\'NormPriors.f40.mat\\',\\'$PLMTK::databasedir/intermediate/NormFactors.f40.mat\\'\\)\\; >> $PLMTK::databasedir/intermediate/plm_normadp.m";
    print "$cmdline\n";
    system("$cmdline");
    $cmdline = "$PLMTK::MATLABDIR/$PLMTK::MATLAB < $PLMTK::databasedir/intermediate/plm_normadp.m";
    print "$cmdline\n";
    system("$cmdline");
}

if ($PLMTK::FEANR)  {
    chdir "$PLMTK::databasedir/intermediate/";
    system("rm -r $PLMTK::databasedir/intermediate/plm_feanorm.m");
    $cmdline = "echo addpath\\(\\'$PLMTK::progbasedir/plm/feanorm/\\'\\)\\; >> $PLMTK::databasedir/intermediate/plm_feanorm.m";
    print "$cmdline\n";
    system("$cmdline");

    $cmdline = "echo FeaNorm\\(\\'$PLMTK::databasedir/intermediate/NormFactors.f40.mat\\',\\'$PLMTK::databasedir/intermediate/al/plm.al\\',\\'$PLMTK::databasedir/intermediate/NormFea.f40.mat\\'\\)\\; >> $PLMTK::databasedir/intermediate/plm_feanorm.m";
    print "$cmdline\n";
    system("$cmdline");

    $cmdline = "$PLMTK::MATLABDIR/$PLMTK::MATLAB < $PLMTK::databasedir/intermediate/plm_feanorm.m";
    print "$cmdline\n";
    system("$cmdline");
}

if ($PLMTK::PLMAD) {
    chdir "$PLMTK::databasedir/intermediate/";
    system("rm -r $PLMTK::databasedir/intermediate/plm_plmadp.m");
    $cmdline = "echo addpath\\(\\'$PLMTK::progbasedir/plm/plmadp/\\'\\)\\; >> $PLMTK::databasedir/intermediate/plm_plmadp.m";
    print "$cmdline\n";
    system("$cmdline");

    $cmdline = "echo PLMAdp_LGR\\(\\'$PLMTK::databasedir/intermediate/NormFea.f40.mat\\', \\'SRHPMPriorLGR.f40.mat\\', \\'$PLMTK::databasedir/intermediate\\', \\'HPM_MAPLR_SMAP_LGR\\'\\)\\; >> $PLMTK::databasedir/intermediate/plm_plmadp.m";
    print "$cmdline\n";
    system("$cmdline");

    $cmdline = "$PLMTK::MATLABDIR/$PLMTK::MATLAB < $PLMTK::databasedir/intermediate/plm_plmadp.m";
    print "$cmdline\n";
    system("$cmdline");
}

if ($PLMTK::NRADP_B) {
    chdir "$PLMTK::databasedir/intermediate/";
    system("rm -r $PLMTK::databasedir/intermediate/plm_normadp_B.m");
    $cmdline = "echo addpath\\(\\'$PLMTK::progbasedir/plm/normadp_B/\\'\\)\\; >> $PLMTK::databasedir/intermediate/plm_normadp_B.m";
    print "$cmdline\n";
    system("$cmdline");
    $cmdline = "echo NormAdp_B\\(\\'$PLMTK::databasedir/intermediate/al/plm.al\\',\\'NormPriors.f40.mat\\',\\'$PLMTK::databasedir/intermediate/HPM_MAPLR_SMAP_LGR_03.mat\\', \\'$PLMTK::databasedir/intermediate/NormFactorsB.f40.mat\\'\\)\\; >> $PLMTK::databasedir/intermediate/plm_normadp_B.m";
    print "$cmdline\n";
    system("$cmdline");
    $cmdline = "$PLMTK::MATLABDIR/$PLMTK::MATLAB < $PLMTK::databasedir/intermediate/plm_normadp_B.m";
    print "$cmdline\n";
    system("$cmdline");
}

if ($PLMTK::FEANR_B) {
    chdir "$PLMTK::databasedir/intermediate/";
    system("rm -r $PLMTK::databasedir/intermediate/plm_feanorm_B.m");
    $cmdline = "echo addpath\\(\\'$PLMTK::progbasedir/plm/feanorm_B/\\'\\)\\; >> $PLMTK::databasedir/intermediate/plm_feanorm_B.m";
    print "$cmdline\n";
    system("$cmdline");

    $cmdline = "echo FeaNorm_B\\(\\'$PLMTK::databasedir/intermediate/NormFactorsB.f40.mat\\',\\'$PLMTK::databasedir/intermediate/al/plm.al\\',\\'$PLMTK::databasedir/intermediate/NormFeaB.f40.mat\\'\\)\\; >> $PLMTK::databasedir/intermediate/plm_feanorm_B.m";
    print "$cmdline\n";
    system("$cmdline");

    $cmdline = "$PLMTK::MATLABDIR/$PLMTK::MATLAB < $PLMTK::databasedir/intermediate/plm_feanorm_B.m";
    print "$cmdline\n";
    system("$cmdline");
}

if ($PLMTK::PLMAD_B) {
    chdir "$PLMTK::databasedir/intermediate/";
    system("rm -r $PLMTK::databasedir/intermediate/plm_plmadp_B.m");
    $cmdline = "echo addpath\\(\\'$PLMTK::progbasedir/plm/plmadp/\\'\\)\\; >> $PLMTK::databasedir/intermediate/plm_plmadp_B.m";
    print "$cmdline\n";
    system("$cmdline");

    $cmdline = "echo PLMAdp_LGR\\(\\'$PLMTK::databasedir/intermediate/NormFeaB.f40.mat\\', \\'SRHPMPriorLGR.f40.mat\\', \\'$PLMTK::databasedir/intermediate\\', \\'HPM_MAPLR_SMAP_LGR_B\\'\\)\\; >> $PLMTK::databasedir/intermediate/plm_plmadp_B.m";
    print "$cmdline\n";
    system("$cmdline");

    $cmdline = "$PLMTK::MATLABDIR/$PLMTK::MATLAB < $PLMTK::databasedir/intermediate/plm_plmadp_B.m";
    print "$cmdline\n";
    system("$cmdline");
}

if ($PLMTK::TRXPB) {
    chdir "$PLMTK::databasedir/intermediate/";
    system("rm -r $PLMTK::databasedir/intermediate/plm_transxpb.m");
    $cmdline = "echo addpath\\(\\'$PLMTK::progbasedir/plm/transxpb/\\'\\)\\; >> $PLMTK::databasedir/intermediate/plm_transxpb.m";
    print "$cmdline\n";
    system("$cmdline");

    $cmdline = "echo transxpb\\(\\'$PLMTK::databasedir/intermediate/HPM_MAPLR_SMAP_LGR_B_03.mat\\', \\'$PLMTK::databasedir/intermediate/transxpb\\'\\)\\; >> $PLMTK::databasedir/intermediate/plm_transxpb.m";
    print "$cmdline\n";
    system("$cmdline");

    $cmdline = "$PLMTK::MATLABDIR/$PLMTK::MATLAB < $PLMTK::databasedir/intermediate/plm_transxpb.m";
    print "$cmdline\n";
    system("$cmdline");
}

if( $PLMTK::BTADP) {
    chdir "$PLMTK::databasedir/intermediate/";
    system("rm -r $PLMTK::databasedir/intermediate/plm_btreeadp.m");
    $cmdline = "echo addpath\\(\\'$PLMTK::progbasedir/plm/btreeadp/\\'\\)\\; >> $PLMTK::databasedir/intermediate/plm_btreeadp.m";
    print "$cmdline\n";
    system("$cmdline");

    $cmdline = "echo BTree_MAPLR_SMAP\\(\\'BS_Tree_C300L0001.mat\\', \\'$PLMTK::databasedir/intermediate/HPM_MAPLR_SMAP_LGR_B_03.mat\\', \\'$PLMTK::databasedir/intermediate/BS_Tree_MAPLR_SMAP_LGR.f40.mat\\'\\)\\; >> $PLMTK::databasedir/intermediate/plm_btreeadp.m";
    print "$cmdline\n";
    system("$cmdline");

    $cmdline = "$PLMTK::MATLABDIR/$PLMTK::MATLAB < $PLMTK::databasedir/intermediate/plm_btreeadp.m";
    print "$cmdline\n";
    system("$cmdline");
}

if( $PLMTK::PSADP) {
    chdir "$PLMTK::databasedir/intermediate/";
    system("rm -r $PLMTK::databasedir/intermediate/plm_pstreeadp.m");
    $cmdline = "echo addpath\\(\\'$PLMTK::progbasedir/plm/pstreeadp/\\'\\)\\; >> $PLMTK::databasedir/intermediate/plm_pstreeadp.m";
    print "$cmdline\n";
    system("$cmdline");

    $cmdline = "echo PSTree_MAPLR_SMAP\\(\\'PS_Trees_C500G0001.mat\\', \\'$PLMTK::databasedir/intermediate/HPM_MAPLR_SMAP_LGR_B_03.mat\\', \\'$PLMTK::databasedir/intermediate/PS_Trees_MAPLR_SMAP_LGR.f40.mat\\'\\)\\; >> $PLMTK::databasedir/intermediate/plm_pstreeadp.m";
    print "$cmdline\n";
    system("$cmdline");

    $cmdline = "$PLMTK::MATLABDIR/$PLMTK::MATLAB < $PLMTK::databasedir/intermediate/plm_pstreeadp.m";
    print "$cmdline\n";
    system("$cmdline");
}

if( $PLMTK::MDPRE) {
    chdir "$PLMTK::databasedir/intermediate/";
    system("rm -r $PLMTK::databasedir/intermediate/plm_modelprepare.m");
    $cmdline = "echo addpath\\(\\'$PLMTK::progbasedir/plm/modelprepare/\\'\\)\\; >> $PLMTK::databasedir/intermediate/plm_modelprepare.m";
    print "$cmdline\n";
    system("$cmdline");

    $cmdline = "echo str1 = sprintf\\(\\'$PLMTK::databasedir/intermediate/HPM_MAPLR_SMAP_LGR_B_03.mat\\'\\)\\; >> $PLMTK::databasedir/intermediate/plm_modelprepare.m";
    print "$cmdline\n";
    system("$cmdline");

    $cmdline = "echo str2 = sprintf\\(\\'$PLMTK::progbasedir/plm/modelprepare/71_final.mat\\'\\)\\; >> $PLMTK::databasedir/intermediate/plm_modelprepare.m";
    print "$cmdline\n";
    system("$cmdline");


    $cmdline = "echo str3 = sprintf\\(\\'$PLMTK::databasedir/intermediate/NormFactorsB.f40.mat\\'\\)\\; >> $PLMTK::databasedir/intermediate/plm_modelprepare.m";
    print "$cmdline\n";
    system("$cmdline");


    $cmdline = "echo str4 = sprintf\\(\\'$PLMTK::databasedir/intermediate/BS_Tree_MAPLR_SMAP_LGR.f40.mat\\'\\)\\; >> $PLMTK::databasedir/intermediate/plm_modelprepare.m";
    print "$cmdline\n";
    system("$cmdline");

    $cmdline = "echo str5 = sprintf\\(\\'$PLMTK::databasedir/intermediate/PS_Trees_MAPLR_SMAP_LGR.f40.mat\\'\\)\\; >> $PLMTK::databasedir/intermediate/plm_modelprepare.m";
    print "$cmdline\n";
    system("$cmdline");

    $cmdline = "echo str6 = sprintf\\(\\'$PLMTK::databasedir/out/source\\'\\)\\; >> $PLMTK::databasedir/intermediate/plm_modelprepare.m";
    print "$cmdline\n";
    system("$cmdline");

    $cmdline = "echo mkdir\\(str6\\)\\; >> $PLMTK::databasedir/intermediate/plm_modelprepare.m";
    print "$cmdline\n";
    system("$cmdline");

    $cmdline = "echo str7 = sprintf\\(\\'$PLMTK::databasedir/out/source/pg\\'\\)\\; >> $PLMTK::databasedir/intermediate/plm_modelprepare.m";
    print "$cmdline\n";
    system("$cmdline");

    $cmdline = "echo mkdir\\(str7\\)\\; >> $PLMTK::databasedir/intermediate/plm_modelprepare.m";
    print "$cmdline\n";
    system("$cmdline");


    $cmdline = "echo system\\(\\'cp $PLMTK::progbasedir/plm/gentable/syllable_vowel.xlsx syllable_vowel.xlsx\\'\\)\\; >> $PLMTK::databasedir/intermediate/plm_modelprepare.m";
    print "$cmdline\n";
    system("$cmdline");

    $cmdline = "echo Mat2H_CE_Mixed_Word_LGR\\(str1, str2, str3, str4, str5, str7\\)\\; >> $PLMTK::databasedir/intermediate/plm_modelprepare.m";
    print "$cmdline\n";
    system("$cmdline");

    $cmdline = "$PLMTK::MATLABDIR/$PLMTK::MATLAB < $PLMTK::databasedir/intermediate/plm_modelprepare.m";
    print "$cmdline\n";
    system("$cmdline");
}


if( $PLMTK::MDPRE_RV) {
    chdir "$PLMTK::databasedir/intermediate/";
    system("rm -r $PLMTK::databasedir/intermediate/plm_modelprepare_rv.m");
    $cmdline = "echo addpath\\(\\'$PLMTK::progbasedir/plm/modelprepare_rv/\\'\\)\\; >> $PLMTK::databasedir/intermediate/plm_modelprepare_rv.m";
    print "$cmdline\n";
    system("$cmdline");

    $cmdline = "echo str1 = sprintf\\(\\'$PLMTK::databasedir/intermediate/HPM_MAPLR_SMAP_LGR_B_03.mat\\'\\)\\; >> $PLMTK::databasedir/intermediate/plm_modelprepare_rv.m";
    print "$cmdline\n";
    system("$cmdline");

    $cmdline = "echo str2 = sprintf\\(\\'$PLMTK::progbasedir/plm/modelprepare_rv/71_final.mat\\'\\)\\; >> $PLMTK::databasedir/intermediate/plm_modelprepare_rv.m";
    print "$cmdline\n";
    system("$cmdline");


    $cmdline = "echo str3 = sprintf\\(\\'$PLMTK::databasedir/intermediate/NormFactorsB.f40.mat\\'\\)\\; >> $PLMTK::databasedir/intermediate/plm_modelprepare_rv.m";
    print "$cmdline\n";
    system("$cmdline");


    $cmdline = "echo str4 = sprintf\\(\\'$PLMTK::databasedir/intermediate/BS_Tree_MAPLR_SMAP_LGR.f40.mat\\'\\)\\; >> $PLMTK::databasedir/intermediate/plm_modelprepare_rv.m";
    print "$cmdline\n";
    system("$cmdline");

    $cmdline = "echo str5 = sprintf\\(\\'$PLMTK::databasedir/intermediate/PS_Trees_MAPLR_SMAP_LGR.f40.mat\\'\\)\\; >> $PLMTK::databasedir/intermediate/plm_modelprepare_rv.m";
    print "$cmdline\n";
    system("$cmdline");

    $cmdline = "echo str6 = sprintf\\(\\'$PLMTK::databasedir/out/source\\'\\)\\; >> $PLMTK::databasedir/intermediate/plm_modelprepare_rv.m";
    print "$cmdline\n";
    system("$cmdline");

    $cmdline = "echo mkdir\\(str6\\)\\; >> $PLMTK::databasedir/intermediate/plm_modelprepare_rv.m";
    print "$cmdline\n";
    system("$cmdline");

    $cmdline = "echo str7 = sprintf\\(\\'$PLMTK::databasedir/out/source/pg_rv\\'\\)\\; >> $PLMTK::databasedir/intermediate/plm_modelprepare_rv.m";
    print "$cmdline\n";
    system("$cmdline");

    $cmdline = "echo mkdir\\(str7\\)\\; >> $PLMTK::databasedir/intermediate/plm_modelprepare_rv.m";
    print "$cmdline\n";
    system("$cmdline");


    $cmdline = "echo system\\(\\'cp $PLMTK::progbasedir/plm/gentable/syllable_vowel.xlsx syllable_vowel.xlsx\\'\\)\\; >> $PLMTK::databasedir/intermediate/plm_modelprepare_rv.m";
    print "$cmdline\n";
    system("$cmdline");

    $cmdline = "echo Mat2H_CE_Mixed_Word_LGR\\(str1, str2, str3, str4, str5, str7\\)\\; >> $PLMTK::databasedir/intermediate/plm_modelprepare_rv.m";
    print "$cmdline\n";
    system("$cmdline");

    $cmdline = "$PLMTK::MATLABDIR/$PLMTK::MATLAB < $PLMTK::databasedir/intermediate/plm_modelprepare_rv.m";
    print "$cmdline\n";
    system("$cmdline");

    # system("mkdir $PLMTK::databasedir/out/source/pg_rv/bp");
    # system("cp $PLMTK::databasedir/out/source/pg_rv/* $PLMTK::databasedir/out/source/pg_rv/bp/");
    # system("mkdir $PLMTK::databasedir/out/source/pg_rv/psp");
    # system("cp $PLMTK::databasedir/out/source/pg_rv/* $PLMTK::databasedir/out/source/pg_rv/psp/");
    # system("mkdir $PLMTK::databasedir/out/source/pg_rv/paf");
    # system("cp $PLMTK::databasedir/out/source/pg_rv/* $PLMTK::databasedir/out/source/pg_rv/paf/");
    # system("rm $PLMTK::databasedir/out/source/pg_rv/*.h");
    # system("cp $PLMTK::progbasedir/pg_rv/bp/src/* $PLMTK::databasedir/out/source/pg_rv/bp/");
    # system("cp $PLMTK::progbasedir/pg_rv/psp/src/* $PLMTK::databasedir/out/source/pg_rv/psp/");
    # system("cp $PLMTK::progbasedir/pg_rv/paf/src/* $PLMTK::databasedir/out/source/pg_rv/paf/");
}

if ($PLMTK::MKBPRV) {
    system("mkdir $PLMTK::databasedir/out/source/pg_rv/bp");
    system("cp $PLMTK::databasedir/out/source/pg_rv/* $PLMTK::databasedir/out/source/pg_rv/bp/");
    system("cp $PLMTK::progbasedir/pg_rv/bp/src/* $PLMTK::databasedir/out/source/pg_rv/bp/");
    chdir "$PLMTK::databasedir/out/source/pg_rv/bp/";
    system("make");
    system("make test");
}

if ($PLMTK::MKPSPRV) {
    system("mkdir $PLMTK::databasedir/out/source/pg_rv/psp");
    system("cp $PLMTK::databasedir/out/source/pg_rv/* $PLMTK::databasedir/out/source/pg_rv/psp/");
    system("cp $PLMTK::progbasedir/pg_rv/psp/src/* $PLMTK::databasedir/out/source/pg_rv/psp/");
    chdir "$PLMTK::databasedir/out/source/pg_rv/psp/";
    system("make");
    system("make test");
}

if ($PLMTK::MKPAFRV) {
    system("mkdir $PLMTK::databasedir/out/source/pg_rv/paf");
    system("cp $PLMTK::databasedir/out/source/pg_rv/* $PLMTK::databasedir/out/source/pg_rv/paf/");
    system("cp $PLMTK::progbasedir/pg_rv/paf/src/* $PLMTK::databasedir/out/source/pg_rv/paf/");
    chdir "$PLMTK::databasedir/out/source/pg_rv/paf/";
    system("make");
    system("make test");
}


if( $PLMTK::MKPG_RVTW) {
    chdir "$PLMTK::databasedir/intermediate/";
    system("rm -rf $PLMTK::databasedir/out/source/pg_rvtw");
    system("mkdir $PLMTK::databasedir/out/source");
    system("cp -rf $PLMTK::progbasedir/pg_rvtw $PLMTK::databasedir/out/source/");
    system("rm -r $PLMTK::databasedir/intermediate/plm_modelprepare.m");
    $cmdline = "echo addpath\\(\\'$PLMTK::progbasedir/plm/modelprepare/\\'\\)\\; >> $PLMTK::databasedir/intermediate/plm_modelprepare.m";
    print "$cmdline\n";
    system("$cmdline");

    $cmdline = "echo str1 = sprintf\\(\\'$PLMTK::databasedir/intermediate/HPM_MAPLR_SMAP_LGR_B_03.mat\\'\\)\\; >> $PLMTK::databasedir/intermediate/plm_modelprepare.m";
    print "$cmdline\n";
    system("$cmdline");

    $cmdline = "echo str2 = sprintf\\(\\'$PLMTK::progbasedir/plm/modelprepare/71_final.mat\\'\\)\\; >> $PLMTK::databasedir/intermediate/plm_modelprepare.m";
    print "$cmdline\n";
    system("$cmdline");


    $cmdline = "echo str3 = sprintf\\(\\'$PLMTK::databasedir/intermediate/NormFactorsB.f40.mat\\'\\)\\; >> $PLMTK::databasedir/intermediate/plm_modelprepare.m";
    print "$cmdline\n";
    system("$cmdline");


    $cmdline = "echo str4 = sprintf\\(\\'$PLMTK::databasedir/intermediate/BS_Tree_MAPLR_SMAP_LGR.f40.mat\\'\\)\\; >> $PLMTK::databasedir/intermediate/plm_modelprepare.m";
    print "$cmdline\n";
    system("$cmdline");

    $cmdline = "echo str5 = sprintf\\(\\'$PLMTK::databasedir/intermediate/PS_Trees_MAPLR_SMAP_LGR.f40.mat\\'\\)\\; >> $PLMTK::databasedir/intermediate/plm_modelprepare.m";
    print "$cmdline\n";
    system("$cmdline");

    $cmdline = "echo str7 = sprintf\\(\\'$PLMTK::databasedir/out/source/pg_rvtw/lib\\'\\)\\; >> $PLMTK::databasedir/intermediate/plm_modelprepare.m";
    print "$cmdline\n";
    system("$cmdline");

    $cmdline = "echo mkdir\\(str7\\)\\; >> $PLMTK::databasedir/intermediate/plm_modelprepare.m";
    print "$cmdline\n";
    system("$cmdline");


    $cmdline = "echo system\\(\\'cp $PLMTK::progbasedir/plm/gentable/syllable_vowel.xlsx syllable_vowel.xlsx\\'\\)\\; >> $PLMTK::databasedir/intermediate/plm_modelprepare.m";
    print "$cmdline\n";
    system("$cmdline");

    $cmdline = "echo Mat2H_CE_Mixed_Word_LGR\\(str1, str2, str3, str4, str5, str7\\)\\; >> $PLMTK::databasedir/intermediate/plm_modelprepare.m";
    print "$cmdline\n";
    system("$cmdline");

    $cmdline = "$PLMTK::MATLABDIR/$PLMTK::MATLAB < $PLMTK::databasedir/intermediate/plm_modelprepare.m";
    print "$cmdline\n";
    system("$cmdline");

    chdir "$PLMTK::databasedir/out/source/pg_rvtw/";
    $cmdline = "sh make-clean.sh";
    print "$cmdline\n";
    system("$cmdline");
    chdir "$PLMTK::databasedir/out/source/pg_rvtw/";
    $cmdline = "sh make-build.sh";
    print "$cmdline\n";
    system("$cmdline");
    chdir "$PLMTK::databasedir/intermediate/";
}


if ($PLMTK::MKLAB) {
    chdir "$PLMTK::databasedir/intermediate/";
    mkdir "$PLMTK::databasedir/intermediate/labels", 0755;
    mkdir "$PLMTK::databasedir/intermediate/labels/mono", 0755;
    mkdir "$PLMTK::databasedir/intermediate/labels/full", 0755;
    mkdir "$PLMTK::databasedir/intermediate/labels/gen", 0755;
    
    my $dir = "$PLMTK::databasedir/intermediate/mul";
    opendir(DIR, $dir) or die $!;
    while (my $file = readdir(DIR)) {
        next unless (-f "$dir/$file");
        # Use a regular expression to find files ending in .wav
        next unless ($file =~ m/\.mul$/);
        my($basename)=basename($file, '.mul');

        $cmdline = "$PLMTK::progbasedir/$PLMTK::MKHTSLAB $PLMTK::databasedir/intermediate/mul/$basename.mul $PLMTK::databasedir/intermediate/transxpb/$basename.transxpb 0.025 mono seg $PLMTK::databasedir/intermediate/labels/mono/$basename.lab";
        print "$cmdline\n";
        system("$cmdline");

        $cmdline = "$PLMTK::progbasedir/$PLMTK::MKHTSLAB $PLMTK::databasedir/intermediate/mul/$basename.mul $PLMTK::databasedir/intermediate/transxpb/$basename.transxpb 0.025 full seg $PLMTK::databasedir/intermediate/labels/full/$basename.lab";
        print "$cmdline\n";
        system("$cmdline");

        $cmdline = "$PLMTK::progbasedir/$PLMTK::MKHTSLAB $PLMTK::databasedir/intermediate/mul/$basename.mul $PLMTK::databasedir/intermediate/transxpb/$basename.transxpb 0.025 full nonseg $PLMTK::databasedir/intermediate/labels/gen/$basename.lab";
        print "$cmdline\n";
        system("$cmdline");
    }

}






# force zero amplitudes for sp and sil segments
if ($PLMTK::ZRAMP) {
    chdir "$PLMTK::databasedir/intermediate/";
    my $dir = "$PLMTK::databasedir/intermediate/raw20k";
    mkdir "$PLMTK::databasedir/intermediate/raw20k_zeroampspsil", 0755;
    opendir(DIR, $dir) or die $!;
    while (my $file = readdir(DIR)) {
        next unless (-f "$dir/$file");
        # Use a regular expression to find files ending in .wav
        next unless ($file =~ m/\.raw$/);
        my($basename)=basename($file, '.raw');
        $cmdline = "$PLMTK::progbasedir/$PLMTK::ZEROAMPSILSP 20000 $PLMTK::databasedir/intermediate/labels/mono/$basename.lab $PLMTK::databasedir/intermediate/raw20k/$basename.raw $PLMTK::databasedir/intermediate/raw20k_zeroampspsil/$basename.raw";
        print "$cmdline\n";
        system("$cmdline");
    }
    closedir(DIR);
}

if ($PLMTK::RMSIL) {
    chdir "$PLMTK::databasedir/intermediate/";
   my $dir = "$PLMTK::databasedir/intermediate/raw20k_zeroampspsil";
   mkdir "$PLMTK::databasedir/intermediate/raw20k_cutted", 0755;
   mkdir "$PLMTK::databasedir/intermediate/raw20k_cut_infor", 0755;
   mkdir "$PLMTK::databasedir/intermediate/labels_cutted", 0755;
   mkdir "$PLMTK::databasedir/intermediate/labels_cutted/mono", 0755;
   mkdir "$PLMTK::databasedir/intermediate/labels_cutted/full", 0755;
   opendir(DIR, $dir) or die $!;
    while (my $file = readdir(DIR)) {
        next unless (-f "$dir/$file");
        # Use a regular expression to find files ending in .wav
        next unless ($file =~ m/\.raw$/);
        my($basename)=basename($file, '.raw');

        $cmdline = "$PLMTK::progbasedir/$PLMTK::RMLONGSIL 20000 $PLMTK::databasedir/intermediate/labels/mono/$basename.lab $PLMTK::databasedir/intermediate/labels/full/$basename.lab $PLMTK::databasedir/intermediate/raw20k_zeroampspsil/$basename.raw $PLMTK::databasedir/intermediate/labels_cutted/mono/$basename.lab $PLMTK::databasedir/intermediate/labels_cutted/full/$basename.lab $PLMTK::databasedir/intermediate/raw20k_cutted/$basename.raw $PLMTK::databasedir/intermediate/raw20k_cut_infor/$basename.cut";
        print "$cmdline\n";
        system("$cmdline");
    }
    closedir(DIR);
}

# audio normalization and add dither to avoid failure in extraction mgc parameters (for construction speech synthesizer)
if ($PLMTK::AUNRM) {
    chdir "$PLMTK::databasedir/intermediate/";
    mkdir "$PLMTK::databasedir/intermediate/raw20k_cutted_nrm", 0755;
    mkdir "$PLMTK::databasedir/intermediate/wav20k_cutted_nrm", 0755;
    mkdir "$PLMTK::databasedir/out/wav48k_nrm", 0755;

    system("rm -r $PLMTK::databasedir/intermediate/plm_audio_normalization.m");
    $cmdline = "echo addpath\\(\\'$PLMTK::progbasedir/plm/audio_normalization/\\'\\)\\; >> $PLMTK::databasedir/intermediate/plm_audio_normalization.m";
    print "$cmdline\n";
    system("$cmdline");

    $cmdline = "echo audio_normalization\\(\\'$PLMTK::databasedir/intermediate/raw20k_cutted\\', \\'$PLMTK::databasedir/intermediate/raw20k_cutted_nrm\\', \\'$PLMTK::databasedir/intermediate/wav20k_cutted_nrm\\', \\'Ref_SR_HPM_Rickie_all.mat\\', \\'$PLMTK::databasedir/intermediate/HPM_MAPLR_SMAP_LGR_B_03.mat\\', 1, $PLMTK::AUDIO_NORMALIZATION_GAIN\\)\\; >> $PLMTK::databasedir/intermediate/plm_audio_normalization.m";
    print "$cmdline\n";
    system("$cmdline");

    $cmdline = "echo audio_normalization_48kHz\\(\\'$PLMTK::databasedir/in/wav\\', \\'$PLMTK::databasedir/out/wav48k_nrm\\', \\'Ref_SR_HPM_Rickie_all.mat\\', \\'$PLMTK::databasedir/intermediate/HPM_MAPLR_SMAP_LGR_B_03.mat\\', 1, $PLMTK::AUDIO_NORMALIZATION_GAIN\\)\\; >> $PLMTK::databasedir/intermediate/plm_audio_normalization.m";
    print "$cmdline\n";
    system("$cmdline");

    $cmdline = "$PLMTK::MATLABDIR/$PLMTK::MATLAB < $PLMTK::databasedir/intermediate/plm_audio_normalization.m";
    print "$cmdline\n";
    system("$cmdline");
}

# make HTS training package
if ($PLMTK::MKHTS) {
    &print_time("make HTS training package");
    if ($PLMTK::SDT_Training) {
        &print_time("speaker dependent training (SDT) is turned on");
    }
    else {
        &print_time("speaker dependent training (SDT) is turned off");
    }
    if ($PLMTK::SAT_Training) {
        &print_time("speaker adaptive training (SAT) is turned on");
        if($PLMTK::SAT_with_prior) {
            &print_time("SAT with trained prior HTS model");
        }
        else {
            &print_time("SAT without trained prior HTS model");
        }
    }
    else {
        &print_time("speaker adaptive training (SAT) is turned off");
    }

    &print_time("start to make HTS package for SDT or SAT");
    chdir "$PLMTK::databasedir/intermediate/";
    # copy base HTS package from ntpu-tts project
    system("rm -rf $PLMTK::databasedir/out/HTS-demo_PLMTK");
    mkdir "$PLMTK::databasedir/out/HTS-demo_PLMTK", 0755;
    $cmdline = "cp -r $PLMTK::progbasedir/hts/HTS-demo_PLMTK/* $PLMTK::databasedir/out/HTS-demo_PLMTK/";
    print "$cmdline\n";
    system("$cmdline");

    # rename the files for HTS training
    mkdir "$PLMTK::databasedir/out/HTS-demo_PLMTK/data/labels", 0755;
    mkdir "$PLMTK::databasedir/out/HTS-demo_PLMTK/data/labels/mono", 0755;
    mkdir "$PLMTK::databasedir/out/HTS-demo_PLMTK/data/labels/full", 0755;
    mkdir "$PLMTK::databasedir/out/HTS-demo_PLMTK/data/labels/gen", 0755;
    mkdir "$PLMTK::databasedir/out/HTS-demo_PLMTK/data/raw", 0755;
    mkdir "$PLMTK::databasedir/out/HTS-demo_PLMTK/data/lf0", 0755;
    mkdir "$PLMTK::databasedir/out/HTS-demo_PLMTK/data/mgc", 0755;

    system("rm -r $PLMTK::databasedir/intermediate/plm_htsrename.m");
    $cmdline = "echo addpath\\(\\'$PLMTK::progbasedir/plm/htsrename/\\'\\)\\; >> $PLMTK::databasedir/intermediate/plm_htsrename.m";
    print "$cmdline\n";
    system("$cmdline");

    $cmdline = "echo htsrename\\(\\'$PLMTK::speaker_name\\',\\'$PLMTK::databasedir/intermediate/raw20k_cutted_nrm\\', \\'$PLMTK::databasedir/intermediate/labels_cutted/mono\\', \\'$PLMTK::databasedir/intermediate/labels_cutted/full\\', \\'$PLMTK::databasedir/intermediate/labels/gen\\', \\'$PLMTK::databasedir/intermediate/HPM_MAPLR_SMAP_LGR_B_03.mat\\', \\'$PLMTK::databasedir/out/HTS-demo_PLMTK\\'\\)\\; >> $PLMTK::databasedir/intermediate/plm_htsrename.m";
    print "$cmdline\n";
    system("$cmdline");

    $cmdline = "$PLMTK::MATLABDIR/$PLMTK::MATLAB < $PLMTK::databasedir/intermediate/plm_htsrename.m";
    print "$cmdline\n";
    system("$cmdline");

    # WORLD vocoding
    system("rm -rf $PLMTK::databasedir/out/WOLRD_VOCODING_TUTORIAL");
    mkdir "$PLMTK::databasedir/out/WOLRD_VOCODING_TUTORIAL", 0755;
    $cmdline = "cp -r $PLMTK::progbasedir/vocoding/WOLRD_VOCODING_TUTORIAL/* $PLMTK::databasedir/out/WOLRD_VOCODING_TUTORIAL/";
    print "$cmdline\n";
    system("$cmdline");

    system("rm -rf $PLMTK::databasedir/out/WOLRD_VOCODING_TUTORIAL/vocoding_scripts/feat_extraction/raw");
    mkdir "$PLMTK::databasedir/out/WOLRD_VOCODING_TUTORIAL/vocoding_scripts/feat_extraction/raw", 0755;
    mkdir "$PLMTK::databasedir/out/WOLRD_VOCODING_TUTORIAL/vocoding_scripts/feat_extraction/raw/test", 0755;
    $cmdline = "cp -r $PLMTK::databasedir/out/HTS-demo_PLMTK/data/raw/* $PLMTK::databasedir/out/WOLRD_VOCODING_TUTORIAL/vocoding_scripts/feat_extraction/raw/test";
    print "$cmdline\n";
    system("$cmdline");

    chdir "$PLMTK::databasedir/out/WOLRD_VOCODING_TUTORIAL/vocoding_scripts";
    system("chmod 755 configure");

    $cmdline = "./configure ALLSPKR=\'test\' F0_RANGES=\'test $PLMTK::LOWERF0HZ $PLMTK::UPPERF0HZ\' FREQWARP=0.44 --with-matlab-search-path=$PLMTK::MATLABDIR --with-world-path=$PLMTK::databasedir/out/WOLRD_VOCODING_TUTORIAL/vocoding_scripts/feat_extraction/WORLDcode/";
    print "$cmdline\n";
    system("$cmdline");

    chdir "$PLMTK::databasedir/out/WOLRD_VOCODING_TUTORIAL/vocoding_scripts";
    system("make all");

    # copy mgc and lf0 from WORLD vocoding to HTS training package
    $cmdline = "cp -r $PLMTK::databasedir/out/WOLRD_VOCODING_TUTORIAL/vocoding_scripts/feat_extraction/mgc/world/test/*.mgc $PLMTK::databasedir/out/HTS-demo_PLMTK/data/mgc";
    print "$cmdline\n";
    system("$cmdline");
    $cmdline = "cp -r $PLMTK::databasedir/out/WOLRD_VOCODING_TUTORIAL/vocoding_scripts/feat_extraction/lf0/world/test/*.lf0 $PLMTK::databasedir/out/HTS-demo_PLMTK/data/lf0";
    print "$cmdline\n";
    system("$cmdline");
    chdir "$PLMTK::databasedir/intermediate/";
    chdir "$PLMTK::databasedir/out/HTS-demo_PLMTK/";
    system("chmod 755 configure");
    $cmdline = "./configure    DATASET=W    SPEAKER=S    SAMPFREQ=20000    FRAMELEN=500    FRAMESHIFT=100    WINDOWTYPE=1    NORMALIZE=1    FFTLEN=512    LNGAIN=1    FREQWARP=0.44    GAMMA=0    MGCORDER=24    LOWERF0=50    UPPERF0=550       --with-sptk-search-path=$PLMTK::with_sptk_search_path    --with-hts-search-path=$PLMTK::with_hts_search_path    --with-hts-engine-search-path=$PLMTK::with_hts_engine_search_path    --with-tcl-search-path=$PLMTK::with_tcl_search_path    --with-fest-search-path=$PLMTK::with_fest_search_path";
    print "$cmdline\n";
    system("$cmdline");
    system("make data");
    &print_time("end of making HTS package for SDT or SAT");

    if ($PLMTK::SAT_Training) {
        &print_time("making HTS package for SAT");
        if($PLMTK::SAT_with_prior) {
            &print_time("clone HTS data for SAT training with prior HTS model (each speaker's HTS model is adapted independently)");
            chdir "$PLMTK::databasedir/intermediate/";
            # copy base HTS package from ntpu-tts project
            system("rm -rf $PLMTK::databasedir/out/HTS-demo_SLMTK_SAT");
            #mkdir "$PLMTK::databasedir/out/HTS-demo_SLMTK_SAT", 0755;
            #$cmdline = "cp -r $PLMTK::progbasedir/hts/HTS-demo_SLMTK-Danei-Adapt/* $PLMTK::databasedir/out/HTS-demo_SLMTK_SAT/";
            $cmdline = "rsync -av --exclude data/lf0/000/ --exclude data/mgc/000/ --exclude data/state_align/000/ $PLMTK::progbasedir/hts/HTS-demo_SLMTK-Danei-Adapt/ $PLMTK::databasedir/out/HTS-demo_SLMTK_SAT/";
            print "$cmdline\n";
            system("$cmdline");

            # unzip HTS-demo_SLMTK-Danei-Adapt
            chdir "$PLMTK::databasedir/out/HTS-demo_SLMTK_SAT";
            system("sh unzip.sh");
            chdir "$PLMTK::databasedir/intermediate/";

            # make directories and copy data
            # copy mgc
            mkdir "$PLMTK::databasedir/out/HTS-demo_SLMTK_SAT/data/mgc", 0755;
            mkdir "$PLMTK::databasedir/out/HTS-demo_SLMTK_SATdata/mgc/$PLMTK::speaker_name", 0755;
            dircopy("$PLMTK::databasedir/out/HTS-demo_PLMTK/data/mgc", "$PLMTK::databasedir/out/HTS-demo_SLMTK_SAT/data/mgc/$PLMTK::speaker_name") or die $!;
            # copy raw
            mkdir "$PLMTK::databasedir/out/HTS-demo_SLMTK_SAT/data/raw", 0755;
            mkdir "$PLMTK::databasedir/out/HTS-demo_SLMTK_SAT/data/raw/$PLMTK::speaker_name", 0755;
            dircopy("$PLMTK::databasedir/out/HTS-demo_PLMTK/data/raw", "$PLMTK::databasedir/out/HTS-demo_SLMTK_SAT/data/raw/$PLMTK::speaker_name") or die $!;
            # copy lf0
            mkdir "$PLMTK::databasedir/out/HTS-demo_SLMTK_SAT/data/lf0", 0755;
            mkdir "$PLMTK::databasedir/out/HTS-demo_SLMTK_SAT/data/lf0/$PLMTK::speaker_name", 0755;
            dircopy("$PLMTK::databasedir/out/HTS-demo_PLMTK/data/lf0", "$PLMTK::databasedir/out/HTS-demo_SLMTK_SAT/data/lf0/$PLMTK::speaker_name") or die $!;
            # copy labels
            mkdir "$PLMTK::databasedir/out/HTS-demo_SLMTK_SAT/data/labels", 0755;
            # copy labels/gen
            mkdir "$PLMTK::databasedir/out/HTS-demo_SLMTK_SAT/data/labels/gen", 0755;
            mkdir "$PLMTK::databasedir/out/HTS-demo_SLMTK_SAT/data/labels/gen/$PLMTK::speaker_name", 0755;
            dircopy("$PLMTK::databasedir/out/HTS-demo_PLMTK/data/labels/gen", "$PLMTK::databasedir/out/HTS-demo_SLMTK_SAT/data/labels/gen/$PLMTK::speaker_name") or die $!;
            # copy labels/mono
            mkdir "$PLMTK::databasedir/out/HTS-demo_SLMTK_SAT/data/labels/mono", 0755;
            mkdir "$PLMTK::databasedir/out/HTS-demo_SLMTK_SAT/data/labels/mono/$PLMTK::speaker_name", 0755;
            dircopy("$PLMTK::databasedir/out/HTS-demo_PLMTK/data/labels/mono", "$PLMTK::databasedir/out/HTS-demo_SLMTK_SAT/data/labels/mono/$PLMTK::speaker_name") or die $!;
            # copy labels/full
            mkdir "$PLMTK::databasedir/out/HTS-demo_SLMTK_SAT/data/labels/full", 0755;
            mkdir "$PLMTK::databasedir/out/HTS-demo_SLMTK_SAT/data/labels/full/$PLMTK::speaker_name", 0755;
            dircopy("$PLMTK::databasedir/out/HTS-demo_PLMTK/data/labels/full", "$PLMTK::databasedir/out/HTS-demo_SLMTK_SAT/data/labels/full/$PLMTK::speaker_name") or die $!;
            $cmdline = "cp -r $PLMTK::databasedir/out/HTS-demo_PLMTK/data/file_mapping.txt $PLMTK::databasedir/out/HTS-demo_SLMTK_SAT/data/file_mapping.txt";
            print "$cmdline\n";
            system("$cmdline");
            
            mkdir "$PLMTK::databasedir/out/HTS-demo_SLMTK_SAT/data/cmp", 0755;
            mkdir "$PLMTK::databasedir/out/HTS-demo_SLMTK_SATdata/cmp/$PLMTK::speaker_name", 0755;
            dircopy("$PLMTK::databasedir/out/HTS-demo_PLMTK/data/cmp", "$PLMTK::databasedir/out/HTS-demo_SLMTK_SAT/data/cmp/$PLMTK::speaker_name") or die $!;
            chdir "$PLMTK::databasedir/out/HTS-demo_SLMTK_SAT/";
            system("chmod 755 configure");
            $cmdline = "./configure    DATASET=PLMTK TRAINSPKR=000 ADAPTSPKR=$PLMTK::speaker_name ADAPTHEAD= SAMPFREQ=20000 FRAMELEN=500 FRAMESHIFT=100 WINDOWTYPE=1 NORMALIZE=1 FFTLEN=512 LNGAIN=1 FREQWARP=0.44 GAMMA=0 MGCORDER=24 LOWERF0=50 UPPERF0=550      --with-sptk-search-path=$PLMTK::with_sptk_search_path    --with-hts-search-path=$PLMTK::with_hts_search_path    --with-hts-engine-search-path=$PLMTK::with_hts_engine_search_path    --with-tcl-search-path=$PLMTK::with_tcl_search_path    --with-fest-search-path=$PLMTK::with_fest_search_path";
            print "$cmdline\n";
            system("$cmdline");

            # disable SAT training and adaptation
            chdir "$PLMTK::databasedir/out/HTS-demo_SLMTK_SAT/scripts";
            $cmdline = "sed -e \'s/\$SPKAT = 1;/\$SPKAT = 0;/1\' -e \'s/\$MKUN2 = 1;/\$MKUN2 = 0;/1\' -e \'s/\$PGEN3 = 1;/\$PGEN3 = 0;/1\' -e \'s/\$WGEN3 = 1;/\$WGEN3 = 0;/1\' -e \'s/\$ADPT2 = 1;/\$ADPT2 = 0;/1\' -e \'s/\$MAPE2 = 1;/\$MAPE2 = 0;/1\' -e \'s/\$PGEN4 = 1;/\$PGEN4 = 0;/1\' -e \'s/\$WGEN4 = 1;/\$WGEN4 = 0;/1\' Config.pm > tmp";
            print "$cmdline\n";
            system("$cmdline");
            system("cp tmp Config.pm");
            system("rm -f tmp");
        }
        else {
            &print_time("clone HTS data for SAT training without prior HTS model (all speakers' HTS models are adapted jointly)");
            ##### clone HTS data to the HTS-demo_PLMTK-MULTI-SPK folder #####
            # make directories and copy data
            # copy mgc
            mkdir "$PLMTK::HTS_SAT_without_prior_basedir/HTS-demo_PLMTK-MULTI-SPK/data/mgc", 0755;
            mkdir "$PLMTK::HTS_SAT_without_prior_basedir/HTS-demo_PLMTK-MULTI-SPK/data/mgc/$PLMTK::speaker_name", 0755;
            dircopy("$PLMTK::databasedir/out/HTS-demo_PLMTK/data/mgc", "$PLMTK::HTS_SAT_without_prior_basedir/HTS-demo_PLMTK-MULTI-SPK/data/mgc/$PLMTK::speaker_name") or die $!;
            # copy raw
            mkdir "$PLMTK::HTS_SAT_without_prior_basedir/HTS-demo_PLMTK-MULTI-SPK/data/raw", 0755;
            mkdir "$PLMTK::HTS_SAT_without_prior_basedir/HTS-demo_PLMTK-MULTI-SPK/data/raw/$PLMTK::speaker_name", 0755;
            dircopy("$PLMTK::databasedir/out/HTS-demo_PLMTK/data/raw", "$PLMTK::HTS_SAT_without_prior_basedir/HTS-demo_PLMTK-MULTI-SPK/data/raw/$PLMTK::speaker_name") or die $!;
            # copy lf0
            mkdir "$PLMTK::HTS_SAT_without_prior_basedir/HTS-demo_PLMTK-MULTI-SPK/data/lf0", 0755;
            mkdir "$PLMTK::HTS_SAT_without_prior_basedir/HTS-demo_PLMTK-MULTI-SPK/data/lf0/$PLMTK::speaker_name", 0755;
            dircopy("$PLMTK::databasedir/out/HTS-demo_PLMTK/data/lf0", "$PLMTK::HTS_SAT_without_prior_basedir/HTS-demo_PLMTK-MULTI-SPK/data/lf0/$PLMTK::speaker_name") or die $!;
            # copy labels
            mkdir "$PLMTK::HTS_SAT_without_prior_basedir/HTS-demo_PLMTK-MULTI-SPK/data/labels", 0755;
            # copy labels/gen
            mkdir "$PLMTK::HTS_SAT_without_prior_basedir/HTS-demo_PLMTK-MULTI-SPK/data/labels/gen", 0755;
            mkdir "$PLMTK::HTS_SAT_without_prior_basedir/HTS-demo_PLMTK-MULTI-SPK/data/labels/gen/$PLMTK::speaker_name", 0755;
            dircopy("$PLMTK::databasedir/out/HTS-demo_PLMTK/data/labels/gen", "$PLMTK::HTS_SAT_without_prior_basedir/HTS-demo_PLMTK-MULTI-SPK/data/labels/gen/$PLMTK::speaker_name") or die $!;
            # copy labels/mono
            mkdir "$PLMTK::HTS_SAT_without_prior_basedir/HTS-demo_PLMTK-MULTI-SPK/data/labels/mono", 0755;
            mkdir "$PLMTK::HTS_SAT_without_prior_basedir/HTS-demo_PLMTK-MULTI-SPK/data/labels/mono/$PLMTK::speaker_name", 0755;
            dircopy("$PLMTK::databasedir/out/HTS-demo_PLMTK/data/labels/mono", "$PLMTK::HTS_SAT_without_prior_basedir/HTS-demo_PLMTK-MULTI-SPK/data/labels/mono/$PLMTK::speaker_name") or die $!;
            # copy labels/full
            mkdir "$PLMTK::HTS_SAT_without_prior_basedir/HTS-demo_PLMTK-MULTI-SPK/data/labels/full", 0755;
            mkdir "$PLMTK::HTS_SAT_without_prior_basedir/HTS-demo_PLMTK-MULTI-SPK/data/labels/full/$PLMTK::speaker_name", 0755;
            dircopy("$PLMTK::databasedir/out/HTS-demo_PLMTK/data/labels/full", "$PLMTK::HTS_SAT_without_prior_basedir/HTS-demo_PLMTK-MULTI-SPK/data/labels/full/$PLMTK::speaker_name") or die $!;
        }
    }
    else {
        &print_time("speaker adaptive training (SAT) is turned off");
        # do nothing here
    }


    if ($PLMTK::SDT_Training) {
        &print_time("keep HTS package for SDT");
        # do nothing here
    }
    else {
        &print_time("remove HTS package for SDT");
        # remove HTS package for SDT
        # system("rm -rf $PLMTK::databasedir/out/HTS-demo_PLMTK");
    }

}

# run HTS and forced-alignment to HMM-state level
if ($PLMTK::RNHTS) {
    &print_time("run HTS and forced-alignment to HMM-state level");
    if ($PLMTK::SDT_Training) {
        &print_time("run SDT HTS script: make voice");
        chdir "$PLMTK::databasedir/out/HTS-demo_PLMTK/";
        system("make voice");
    }
    else {
        # do nothing here
    }

    if ($PLMTK::SAT_Training) {
        if($PLMTK::SAT_with_prior) {
            &print_time("run SAT HTS script (each speaker's HTS model is adapted independently)");
            chdir "$PLMTK::databasedir/out/HTS-demo_SLMTK_SAT/";
            system("make all");
        }
        else {
            &print_time("all speakers' HTS models will be adapted jointly after all the speakers' HTS datum are ready");
            # do nothing here
        }
    }
    else {
        # do nothing here
    }
}

# make the executable hts_engine_pc_rv
if ($PLMTK::MKHTSEGPC_RV) {
    system("mkdir $PLMTK::databasedir/out/source/ss_rv");
    system("mkdir $PLMTK::databasedir/out/source/ss_rv/hts_engine_pc_rv");
    system("cp -r $PLMTK::progbasedir/ss/hts_engine_pc_rv/src/* $PLMTK::databasedir/out/source/ss_rv/hts_engine_pc_rv/");
    
    # save logF0 normalization NormFactors
    chdir "$PLMTK::databasedir/out/source/ss_rv/hts_engine_pc_rv/";
    system("echo \"#define GMEAN 5.312651419810687\" > LF0NormFct.h");
    system("echo \"#define GSTD 0.260204090335592\" >> LF0NormFct.h");
    system("echo \"#define TMEAN \\c\" >> LF0NormFct.h");
    system("awk \'\{print \$2\}\' $PLMTK::databasedir/intermediate/lf0mustd/lf0.f10.mustd >> LF0NormFct.h");
    system("echo \"#define TSTD \\c\" >> LF0NormFct.h");
    system("awk \'\{print \$4\}\' $PLMTK::databasedir/intermediate/lf0mustd/lf0.f10.mustd >> LF0NormFct.h");
    
    chdir "$PLMTK::databasedir/out/source/ss_rv/hts_engine_pc_rv/";
    system("make");
    system("make test");
}

# make the executable hts_engine_pc (SD)
if ($PLMTK::MKHTSEGPC_RVTW_SD) {
    system("mkdir $PLMTK::databasedir/out/source/ss");
    system("mkdir $PLMTK::databasedir/out/source/ss/hts_engine_pc-sd");
    system("cp -r $PLMTK::progbasedir/ss/hts_engine_pc/* $PLMTK::databasedir/out/source/ss/hts_engine_pc-sd/");
    
    # save logF0 normalization NormFactors
    chdir "$PLMTK::databasedir/out/source/ss/hts_engine_pc-sd/";
    system("echo \"#define GMEAN 5.312651419810687\" > LF0NormFct.h");
    system("echo \"#define GSTD 0.260204090335592\" >> LF0NormFct.h");
    system("echo \"#define TMEAN \\c\" >> LF0NormFct.h");
    system("awk \'\{print \$2\}\' $PLMTK::databasedir/intermediate/lf0mustd/lf0.f10.mustd >> LF0NormFct.h");
    system("echo \"#define TSTD \\c\" >> LF0NormFct.h");
    system("awk \'\{print \$4\}\' $PLMTK::databasedir/intermediate/lf0mustd/lf0.f10.mustd >> LF0NormFct.h");

    # copy SD HTS model
    system("mkdir $PLMTK::databasedir/out/source/ss/hts_engine_pc-sd/voice_SD");
    system("cp $PLMTK::databasedir/out/HTS-demo_PLMTK/voices/qst001/ver1/* $PLMTK::databasedir/out/source/ss/hts_engine_pc-sd/voice_SD/");
    
    chdir "$PLMTK::databasedir/out/source/ss/hts_engine_pc-sd/";
    system("make");
    system("make test");

}

# make the executable hts_engine_pc (SAT)
if ($PLMTK::MKHTSEGPC_RVTW_SAT) {
    system("mkdir $PLMTK::databasedir/out/source/ss");
    system("mkdir $PLMTK::databasedir/out/source/ss/hts_engine_pc-sat");
    system("cp -r $PLMTK::progbasedir/ss/hts_engine_pc/* $PLMTK::databasedir/out/source/ss/hts_engine_pc-sat/");
    
    # save logF0 normalization NormFactors
    chdir "$PLMTK::databasedir/out/source/ss/hts_engine_pc-sat/";
    system("echo \"#define GMEAN 5.312651419810687\" > LF0NormFct.h");
    system("echo \"#define GSTD 0.260204090335592\" >> LF0NormFct.h");
    system("echo \"#define TMEAN \\c\" >> LF0NormFct.h");
    system("awk \'\{print \$2\}\' $PLMTK::databasedir/intermediate/lf0mustd/lf0.f10.mustd >> LF0NormFct.h");
    system("echo \"#define TSTD \\c\" >> LF0NormFct.h");
    system("awk \'\{print \$4\}\' $PLMTK::databasedir/intermediate/lf0mustd/lf0.f10.mustd >> LF0NormFct.h");

    # copy SD HTS model
    system("mkdir $PLMTK::databasedir/out/source/ss/hts_engine_pc-sat/voice_SAT");
    system("cp $PLMTK::databasedir/out/HTS-demo_SLMTK_SAT/voices/qst001/ver1/$PLMTK::speaker_name/* $PLMTK::databasedir/out/source/ss/hts_engine_pc-sat/voice_SAT/");
    
    chdir "$PLMTK::databasedir/out/source/ss/hts_engine_pc-sat/";
    system("make");
    system("make test");

}

# run data augmentation for LiftingNet (vocoding model, VM)
if ($PLMTK::AUGVM) {
    # input: *.wav
    # output: *.wav (augmented)
    chdir "$PLMTK::databasedir/out/";
    $cmdline = "$PLMTK::DATAAUGLN Config.augvm.pm";
    system($cmdline);
}

# making vocoder model's pitch mark
if ($PLMTK::MVMPM) {
    # input: *.wav
    # output (for training of VM, i.e., LiftingNet): *.cos (cosine wavforms for F0 and UV), *.mgc, and *.wav (augmented)
    # extract pitch mark by REAPER, e.g., ./reaper -t -w 1.0 -m 60 -x 550 -i Rebecca-CEmix-0001.wav -f Rebecca-CEmix-0001.f0 -p Rebecca-CEmix-0001.pm -a
    # pm2cos: convert pitch mark to cosine waves
    # chdir "$PLMTK::databasedir/intermediate/";
    # my $dir = "$PLMTK::databasedir/intermediate/wav20k_cutted_nrm";
    # mkdir "$PLMTK::databasedir/intermediate/wav20k_cutted_nrm_pm", 0755;
    # opendir(DIR, $dir) or die $!;
    # while (my $file = readdir(DIR)) {
    #     next unless (-f "$dir/$file");
    #     # Use a regular expression to find files ending in .wav
    #     next unless ($file =~ m/\.wav$/);
    #     my($basename)=basename($file, '.wav');
    #     $cmdline = "$REAPER -t -m 50 -x 550 -i $PLMTK::databasedir/intermediate/wav20k_cutted_nrm/$basename.wav -p $PLMTK::databasedir/intermediate/wav20k_cutted_nrm_pm/$basename.pm -a";
    #     print "$cmdline\n";
    #     system("$cmdline");
    #     $cmdline = "$PLMTK::progbasedir/$PM2LAB < $PLMTK::databasedir/intermediate/wav20k_cutted_nrm_pm/$basename.pm > $PLMTK::databasedir/intermediate/wav20k_cutted_nrm_pm/$basename.lab";
    #     print "$cmdline\n";
    #     system("$cmdline");
    # }
    # closedir(DIR);

    chdir "$PLMTK::databasedir/out/";
    my $dir = "$PLMTK::databasedir/out/vm/WOLRD_VOCODING_TUTORIAL/vocoding_scripts/feat_extraction/raw/test";
    mkdir "$PLMTK::databasedir/out/vm/cos", 0755;
    mkdir "$PLMTK::databasedir/out/vm/pmlab", 0755;
    mkdir "$PLMTK::databasedir/out/vm/f0", 0755;
    opendir(DIR, $dir) or die $!;
    while (my $file = readdir(DIR)) {
        next unless (-f "$dir/$file");
        # Use a regular expression to find files ending in .wav
        next unless ($file =~ m/\.raw$/);
        my($basename)=basename($file, '.raw');
        $cmdline = "x2x +fa $PLMTK::databasedir/out/vm/WOLRD_VOCODING_TUTORIAL/vocoding_scripts/feat_extraction/f0/world/test/$basename.f0 > $PLMTK::databasedir/out/vm/tmp.f0";
        print "$cmdline\n";
        system($cmdline);

        $cmdline = "$PLMTK::progbasedir/vm/pmcosgen/pmcosgen $dir/$basename.raw $PLMTK::databasedir/out/vm/tmp.f0 $PLMTK::databasedir/out/vm/pmlab/$basename.lab $PLMTK::databasedir/out/vm/cos/$basename.cos $PLMTK::databasedir/out/vm/f0/$basename.f0";
        print "$cmdline\n";
        system("$cmdline");

        $cmdline = "rm -f $PLMTK::databasedir/out/vm/tmp.f0";
        system($cmdline);
    }
    closedir(DIR);
}

# check lengthes of datum (lab, raw, mgc and lf0) and generate datum with identical lengthes
if ($PLMTK::DCHCK) {
    mkdir "$PLMTK::databasedir/out/dnndata";
    my $dirname = "$PLMTK::databasedir/out/HTS-demo_PLMTK/data/state_align";
    opendir my($dh), $dirname or die"Could not open directory [$dirname]: $!";
    foreach my $file ( sort { $a cmp $b } readdir $dh ) {
        next unless (-f "$dirname/$file");
        # Use a regular expression to find files ending in .lab
        next unless ($file =~ m/\.lab$/);
        my($basename)=basename($file, '.lab');
        $cmdline = "$PLMTK::progbasedir/$PLMTK::DADATACHECK 20000 100 24 $PLMTK::databasedir/out/HTS-demo_PLMTK/data/state_align/$basename.lab $PLMTK::databasedir/out/HTS-demo_PLMTK/data/raw/$basename.raw $PLMTK::databasedir/out/HTS-demo_PLMTK/data/mgc/$basename.mgc $PLMTK::databasedir/out/HTS-demo_PLMTK/data/lf0/$basename.lf0 $PLMTK::databasedir/out/dnndata/$basename.lab $PLMTK::databasedir/out/dnndata/$basename.raw $PLMTK::databasedir/out/dnndata/$basename.mgc $PLMTK::databasedir/out/dnndata/$basename.lf0";
        print "$cmdline\n";
        system("$cmdline");
    }

    # mkdir "$PLMTK::databasedir/out/dnndata";
    # my $dir = "$PLMTK::databasedir/out/HTS-demo_PLMTK/data/state_align";
    # opendir(DIR, $dir) or die $!;
    # while (my $file = readdir(DIR)) {
    #     next unless (-f "$dir/$file");
    #     # Use a regular expression to find files ending in .lab
    #     next unless ($file =~ m/\.lab$/);
    #     my($basename)=basename($file, '.lab');
    #     $cmdline = "$PLMTK::progbasedir/$PLMTK::DADATACHECK 20000 100 24 $PLMTK::databasedir/out/HTS-demo_PLMTK/data/state_align/$basename.lab $PLMTK::databasedir/out/HTS-demo_PLMTK/data/raw/$basename.raw $PLMTK::databasedir/out/HTS-demo_PLMTK/data/mgc/$basename.mgc $PLMTK::databasedir/out/HTS-demo_PLMTK/data/lf0/$basename.lf0 $PLMTK::databasedir/out/dnndata/$basename.lab $PLMTK::databasedir/out/dnndata/$basename.raw $PLMTK::databasedir/out/dnndata/$basename.mgc $PLMTK::databasedir/out/dnndata/$basename.lf0";
    #     print "$cmdline\n";
    #     system("$cmdline");
    # }
    closedir(DIR);
}

chdir "$PLMTK::databasedir";
 exit 0;





















################################
# $| = 1;

# if ( @ARGV < 1 ) {
#    print "usage: Training.pl Config.pm\n";
#    exit(0);
# }

# # load configuration variables
# require( $ARGV[0] );

# # model structure
# foreach $set (@SET) {
#    $vSize{$set}{'total'}   = 0;
#    $nstream{$set}{'total'} = 0;
#    $nPdfStreams{$set}      = 0;
#    foreach $type ( @{ $ref{$set} } ) {
#       $vSize{$set}{$type} = $nwin{$type} * $ordr{$type};
#       $vSize{$set}{'total'} += $vSize{$set}{$type};
#       $nstream{$set}{$type} = $stre{$type} - $strb{$type} + 1;
#       $nstream{$set}{'total'} += $nstream{$set}{$type};
#       $nPdfStreams{$set}++;
#    }
# }

# # File locations =========================
# # data directory
# $datdir = "$prjdir/data";

# # data location file
# $scp{'trn'} = "$datdir/scp/train.cmp.scp";
# $scp{'gen'} = "$datdir/scp/gen.lab.scp";

# # model list files
# $lst{'mon'} = "$datdir/lists/mono.list";
# $lst{'ful'} = "$datdir/lists/full.list";
# $lst{'all'} = "$datdir/lists/full_all.list";

# # master label files
# $mlf{'mon'} = "$datdir/labels/mono.mlf";
# $mlf{'ful'} = "$datdir/labels/full.mlf";

# # configuration variable files
# $cfg{'trn'} = "$prjdir/configs/ver${ver}/trn.cnf";
# $cfg{'nvf'} = "$prjdir/configs/ver${ver}/nvf.cnf";
# $cfg{'syn'} = "$prjdir/configs/ver${ver}/syn.cnf";
# $cfg{'apg'} = "$prjdir/configs/ver${ver}/apg.cnf";
# $cfg{'stc'} = "$prjdir/configs/ver${ver}/stc.cnf";
# foreach $type (@cmp) {
#    $cfg{$type} = "$prjdir/configs/ver${ver}/${type}.cnf";
# }
# foreach $type (@dur) {
#    $cfg{$type} = "$prjdir/configs/ver${ver}/${type}.cnf";
# }

# # name of proto type definition file
# $prtfile{'cmp'} = "$prjdir/proto/ver${ver}/state-${nState}_stream-$nstream{'cmp'}{'total'}";
# foreach $type (@cmp) {
#    $prtfile{'cmp'} .= "_${type}-$vSize{'cmp'}{$type}";
# }
# $prtfile{'cmp'} .= ".prt";

# # model files
# foreach $set (@SET) {
#    $model{$set}   = "$prjdir/models/ver${ver}/${set}";
#    $hinit{$set}   = "$model{$set}/HInit";
#    $hrest{$set}   = "$model{$set}/HRest";
#    $vfloors{$set} = "$model{$set}/vFloors";
#    $avermmf{$set} = "$model{$set}/average.mmf";
#    $initmmf{$set} = "$model{$set}/init.mmf";
#    $monommf{$set} = "$model{$set}/monophone.mmf";
#    $fullmmf{$set} = "$model{$set}/fullcontext.mmf";
#    $clusmmf{$set} = "$model{$set}/clustered.mmf";
#    $untymmf{$set} = "$model{$set}/untied.mmf";
#    $reclmmf{$set} = "$model{$set}/re_clustered.mmf";
#    $rclammf{$set} = "$model{$set}/re_clustered_all.mmf";
#    $tiedlst{$set} = "$model{$set}/tiedlist";
#    $stcmmf{$set}  = "$model{$set}/stc.mmf";
#    $stcammf{$set} = "$model{$set}/stc_all.mmf";
#    $stcbase{$set} = "$model{$set}/stc.base";
# }

# # statistics files
# foreach $set (@SET) {
#    $stats{$set} = "$prjdir/stats/ver${ver}/${set}.stats";
# }

# # model edit files
# foreach $set (@SET) {
#    $hed{$set} = "$prjdir/edfiles/ver${ver}/${set}";
#    $lvf{$set} = "$hed{$set}/lvf.hed";
#    $m2f{$set} = "$hed{$set}/m2f.hed";
#    $mku{$set} = "$hed{$set}/mku.hed";
#    $unt{$set} = "$hed{$set}/unt.hed";
#    $upm{$set} = "$hed{$set}/upm.hed";
#    foreach $type ( @{ $ref{$set} } ) {
#       $cnv{$type} = "$hed{$set}/cnv_$type.hed";
#       $cxc{$type} = "$hed{$set}/cxc_$type.hed";
#    }
# }

# # questions about contexts
# foreach $set (@SET) {
#    foreach $type ( @{ $ref{$set} } ) {
#       $qs{$type}     = "$datdir/questions/questions_${qname}.hed";
#       $qs_utt{$type} = "$datdir/questions/questions_utt_${qname}.hed";
#    }
# }

# # decision tree files
# foreach $set (@SET) {
#    $trd{$set} = "${prjdir}/trees/ver${ver}/${set}";
#    foreach $type ( @{ $ref{$set} } ) {
#       $mdl{$type} = "-m -a $mdlf{$type}" if ( $thr{$type} eq '000' );
#       $tre{$type} = "$trd{$set}/${type}.inf";
#    }
# }

# # converted model & tree files for hts_engine
# $voice = "$prjdir/voices/ver${ver}";
# foreach $set (@SET) {
#    foreach $type ( @{ $ref{$set} } ) {
#       $trv{$type} = "$voice/tree-${type}.inf";
#       $pdf{$type} = "$voice/${type}.pdf";
#    }
# }
# $type       = 'lpf';
# $trv{$type} = "$voice/tree-${type}.inf";
# $pdf{$type} = "$voice/${type}.pdf";

# # window files for parameter generation
# $windir = "${datdir}/win";
# foreach $type (@cmp) {
#    for ( $d = 1 ; $d <= $nwin{$type} ; $d++ ) {
#       $win{$type}[ $d - 1 ] = "${type}.win${d}";
#    }
# }
# $type                 = 'lpf';
# $d                    = 1;
# $win{$type}[ $d - 1 ] = "${type}.win${d}";

# # global variance files and directories for parameter generation
# $gvdir           = "$prjdir/gv/ver${ver}";
# $gvfaldir{'phn'} = "$gvdir/fal/phone";
# $gvfaldir{'stt'} = "$gvdir/fal/state";
# $gvdatdir        = "$gvdir/dat";
# $gvlabdir        = "$gvdir/lab";
# $gvmodels        = "$gvdir/models";
# $scp{'gv'}       = "$gvdir/gv.scp";
# $mlf{'gv'}       = "$gvdir/gv.mlf";
# $lst{'gv'}       = "$gvdir/gv.list";
# $stats{'gv'}     = "$gvdir/stats/gv.stats";
# $prtfile{'gv'}   = "$gvdir/proto/state-1_stream-${nPdfStreams{'cmp'}}";
# foreach $type (@cmp) {
#    $prtfile{'gv'} .= "_${type}-$ordr{$type}";
# }
# $prtfile{'gv'} .= ".prt";
# $vfloors{'gv'} = "$gvmodels/vFloors";
# $avermmf{'gv'} = "$gvmodels/average.mmf";
# $fullmmf{'gv'} = "$gvmodels/fullcontext.mmf";
# $clusmmf{'gv'} = "$gvmodels/clustered.mmf";
# $clsammf{'gv'} = "$gvmodels/clustered_all.mmf";
# $tiedlst{'gv'} = "$gvmodels/tiedlist";
# $mku{'gv'}     = "$gvdir/edfiles/mku.hed";

# foreach $type (@cmp) {
#    $gvcnv{$type} = "$gvdir/edfiles/cnv_$type.hed";
#    $gvcxc{$type} = "$gvdir/edfiles/cxc_$type.hed";
#    $gvmdl{$type} = "-m -a $gvmdlf{$type}" if ( $gvthr{$type} eq '000' );
#    $gvtre{$type} = "$gvdir/trees/${type}.inf";
#    $gvpdf{$type} = "$voice/gv-${type}.pdf";
#    $gvtrv{$type} = "$voice/tree-gv-${type}.inf";
# }

# # files and directories for modulation spectrum-based postfilter
# $mspfdir     = "$prjdir/mspf/ver${ver}";
# $mspffaldir  = "$mspfdir/fal";
# $scp{'mspf'} = "$mspfdir/fal.scp";
# foreach $type ('mgc') {
#    foreach $mspftype ( "nat", "gen/1mix/$pgtype", "gen/dnn/$pgtype", "gen/trj/$pgtype" ) {
#       $mspfdatdir{$mspftype}   = "$mspfdir/dat/$mspftype";
#       $mspfstatsdir{$mspftype} = "$mspfdir/stats/$mspftype";
#       for ( $d = 0 ; $d < $ordr{$type} ; $d++ ) {
#          $mspfmean{$type}{$mspftype}[$d] = "$mspfstatsdir{$mspftype}/${type}_dim$d.mean";
#          $mspfstdd{$type}{$mspftype}[$d] = "$mspfstatsdir{$mspftype}/${type}_dim$d.stdd";
#       }
#    }
# }

# # files and directories for neural networks
# $dnndir              = "$prjdir/dnn/ver${ver}";
# $dnnffidir{'ful'}    = "$dnndir/ffi/full";
# $dnnffidir{'gen'}    = "$dnndir/ffi/gen";
# $dnnmodels           = "$dnndir/models";
# $dnnmodelsdir{'trj'} = "$dnnmodels/trj";
# $scp{'tdn'}          = "$dnndir/train.ffi-ffo.scp";
# $scp{'sdn'}          = "$dnndir/gen.ffi.scp";
# $cfg{'tdn'}          = "$prjdir/configs/ver${ver}/trn_dnn.cnf";
# $cfg{'trj'}          = "$prjdir/configs/ver${ver}/trj_dnn.cnf";
# $cfg{'sdn'}          = "$prjdir/configs/ver${ver}/syn_dnn.cnf";
# $qconf               = "$datdir/configs/$qname.conf";

# # HTS Commands & Options ========================
# $HCompV{'cmp'} = "$HCOMPV    -A    -C $cfg{'trn'} -D -T 1 -S $scp{'trn'} -m ";
# $HCompV{'gv'}  = "$HCOMPV    -A    -C $cfg{'trn'} -D -T 1 -S $scp{'gv'}  -m ";
# $HList         = "$HLIST     -A    -C $cfg{'trn'} -D -T 1 -S $scp{'trn'} -h -z ";
# $HInit         = "$HINIT     -A    -C $cfg{'trn'} -D -T 1 -S $scp{'trn'}                -m 1 -u tmvw    -w $wf ";
# $HRest         = "$HREST     -A    -C $cfg{'trn'} -D -T 1 -S $scp{'trn'}                -m 1 -u tmvw    -w $wf ";
# $HERest{'mon'} = "$HEREST    -A    -C $cfg{'trn'} -D -T 1 -S $scp{'trn'} -I $mlf{'mon'} -m 1 -u tmvwdmv -w $wf -t $beam ";
# $HERest{'ful'} = "$HEREST    -A -B -C $cfg{'trn'} -D -T 1 -S $scp{'trn'} -I $mlf{'ful'} -m 1 -u tmvwdmv -w $wf -t $beam ";
# $HERest{'gv'}  = "$HEREST    -A    -C $cfg{'trn'} -D -T 1 -S $scp{'gv'}  -I $mlf{'gv'}  -m 1 ";
# $HHEd{'trn'}   = "$HHED      -A -B -C $cfg{'trn'} -D -T 1 -p -i ";
# $HSMMAlign     = "$HSMMALIGN -A    -C $cfg{'trn'} -D -T 1 -S $scp{'trn'} -I $mlf{'ful'}                 -w 1.0 -t $beam ";
# $HMGenS        = "$HMGENS    -A -B -C $cfg{'syn'} -D -T 1                                                      -t $beam ";

# # =============================================================
# # ===================== Main Program ==========================
# # =============================================================

# # preparing environments
# if ($MKENV) {
#    print_time("preparing environments");

#    # make directories
#    foreach $dir ( 'models', 'stats', 'edfiles', 'trees', 'gv', 'mspf', 'dnn', 'voices', 'gen', 'proto', 'configs' ) {
#       mkdir "$prjdir/$dir",           0755;
#       mkdir "$prjdir/$dir/ver${ver}", 0755;
#    }
#    foreach $set (@SET) {
#       mkdir "$model{$set}", 0755;
#       mkdir "$hinit{$set}", 0755;
#       mkdir "$hrest{$set}", 0755;
#       mkdir "$hed{$set}",   0755;
#       mkdir "$trd{$set}",   0755;
#    }

#    # make config files
#    make_config();
#    make_config_dnn();

#    # make model prototype definition file
#    make_proto();
# }

# # HCompV (computing variance floors)
# if ($HCMPV) {
#    print_time("computing variance floors");

#    # make average model and compute variance floors
#    shell("$HCompV{'cmp'} -M $model{'cmp'} -o $avermmf{'cmp'} $prtfile{'cmp'}");
#    shell("head -n 1 $prtfile{'cmp'} > $initmmf{'cmp'}");
#    shell("cat $vfloors{'cmp'} >> $initmmf{'cmp'}");

#    make_duration_vfloor( $initdurmean, $initdurvari );
# }

# # HInit & HRest (initialization & reestimation)
# if ($IN_RE) {
#    print_time("initialization & reestimation");

#    if ($daem) {
#       open( LIST, $lst{'mon'} ) || die "Cannot open $!";
#       while ( $phone = <LIST> ) {

#          # trimming leading and following whitespace characters
#          $phone =~ s/^\s+//;
#          $phone =~ s/\s+$//;

#          # skip a blank line
#          if ( $phone eq '' ) {
#             next;
#          }

#          print "=============== $phone ================\n";
#          print "use average model instead of $phone\n";
#          foreach $set (@SET) {
#             open( SRC, "$avermmf{$set}" )       || die "Cannot open $!";
#             open( TGT, ">$hrest{$set}/$phone" ) || die "Cannot open $!";
#             while ( $str = <SRC> ) {
#                if ( index( $str, "~h" ) == 0 ) {
#                   print TGT "~h \"$phone\"\n";
#                }
#                else {
#                   print TGT "$str";
#                }
#             }
#             close(TGT);
#             close(SRC);
#          }
#       }
#       close(LIST);
#    }
#    else {
#       open( LIST, $lst{'mon'} ) || die "Cannot open $!";
#       while ( $phone = <LIST> ) {

#          # trimming leading and following whitespace characters
#          $phone =~ s/^\s+//;
#          $phone =~ s/\s+$//;

#          # skip a blank line
#          if ( $phone eq '' ) {
#             next;
#          }
#          $lab = $mlf{'mon'};

#          if ( grep( $_ eq $phone, keys %mdcp ) <= 0 ) {
#             print "=============== $phone ================\n";
#             shell("$HInit -H $initmmf{'cmp'} -M $hinit{'cmp'} -I $lab -l $phone -o $phone $prtfile{'cmp'}");
#             shell("$HRest -H $initmmf{'cmp'} -M $hrest{'cmp'} -I $lab -l $phone -g $hrest{'dur'}/$phone $hinit{'cmp'}/$phone");
#          }
#       }
#       close(LIST);

#       open( LIST, $lst{'mon'} ) || die "Cannot open $!";
#       while ( $phone = <LIST> ) {

#          # trimming leading and following whitespace characters
#          $phone =~ s/^\s+//;
#          $phone =~ s/\s+$//;

#          # skip a blank line
#          if ( $phone eq '' ) {
#             next;
#          }

#          if ( grep( $_ eq $phone, keys %mdcp ) > 0 ) {
#             print "=============== $phone ================\n";
#             print "use $mdcp{$phone} instead of $phone\n";
#             foreach $set (@SET) {
#                open( SRC, "$hrest{$set}/$mdcp{$phone}" ) || die "Cannot open $!";
#                open( TGT, ">$hrest{$set}/$phone" )       || die "Cannot open $!";
#                while (<SRC>) {
#                   s/~h \"$mdcp{$phone}\"/~h \"$phone\"/;
#                   print TGT;
#                }
#                close(TGT);
#                close(SRC);
#             }
#          }
#       }
#       close(LIST);
#    }
# }

# # HHEd (making a monophone mmf)
# if ($MMMMF) {
#    print_time("making a monophone mmf");

#    foreach $set (@SET) {
#       open( EDFILE, ">$lvf{$set}" ) || die "Cannot open $!";

#       # load variance floor macro
#       print EDFILE "// load variance flooring macro\n";
#       print EDFILE "FV \"$vfloors{$set}\"\n";

#       # tie stream weight macro
#       foreach $type ( @{ $ref{$set} } ) {
#          if ( $strw{$type} != 1.0 ) {
#             print EDFILE "// tie stream weights\n";
#             printf EDFILE "TI SW_all {*.state[%d-%d].weights}\n", 2, $nState + 1;
#             last;
#          }
#       }

#       close(EDFILE);

#       shell("$HHEd{'trn'} -d $hrest{$set} -w $monommf{$set} $lvf{$set} $lst{'mon'}");
#       shell("gzip -c $monommf{$set} > $monommf{$set}.nonembedded.gz");
#    }
# }

# # HERest (embedded reestimation (monophone))
# if ($ERST0) {
#    print_time("embedded reestimation (monophone)");

#    if ($daem) {
#       for ( $i = 1 ; $i <= $daem_nIte ; $i++ ) {
#          for ( $j = 1 ; $j <= $nIte ; $j++ ) {

#             # embedded reestimation
#             $k = $j + ( $i - 1 ) * $nIte;
#             print("\n\nIteration $k of Embedded Re-estimation\n");
#             $k = ( $i / $daem_nIte )**$daem_alpha;
#             shell("$HERest{'mon'} -k $k -H $monommf{'cmp'} -N $monommf{'dur'} -M $model{'cmp'} -R $model{'dur'} $lst{'mon'} $lst{'mon'}");
#          }
#       }
#    }
#    else {
#       for ( $i = 1 ; $i <= $nIte ; $i++ ) {

#          # embedded reestimation
#          print("\n\nIteration $i of Embedded Re-estimation\n");
#          shell("$HERest{'mon'} -H $monommf{'cmp'} -N $monommf{'dur'} -M $model{'cmp'} -R $model{'dur'} $lst{'mon'} $lst{'mon'}");
#       }
#    }

#    # compress reestimated model
#    foreach $set (@SET) {
#       shell("gzip -c $monommf{$set} > ${monommf{$set}}.embedded.gz");
#    }
# }

# # HHEd (copying monophone mmf to fullcontext one)
# if ($MN2FL) {
#    print_time("copying monophone mmf to fullcontext one");

#    foreach $set (@SET) {
#       open( EDFILE, ">$m2f{$set}" ) || die "Cannot open $!";
#       open( LIST,   "$lst{'mon'}" ) || die "Cannot open $!";

#       print EDFILE "// copy monophone models to fullcontext ones\n";
#       print EDFILE "CL \"$lst{'ful'}\"\n\n";    # CLone monophone to fullcontext

#       print EDFILE "// tie state transition probability\n";
#       while ( $phone = <LIST> ) {

#          # trimming leading and following whitespace characters
#          $phone =~ s/^\s+//;
#          $phone =~ s/\s+$//;

#          # skip a blank line
#          if ( $phone eq '' ) {
#             next;
#          }
#          print EDFILE "TI T_${phone} {*-${phone}+*.transP}\n";    # TIe transition prob
#       }
#       close(LIST);
#       close(EDFILE);

#       shell("$HHEd{'trn'} -H $monommf{$set} -w $fullmmf{$set} $m2f{$set} $lst{'mon'}");
#       shell("gzip -c $fullmmf{$set} > $fullmmf{$set}.nonembedded.gz");
#    }
# }

# # HERest (embedded reestimation (fullcontext))
# if ($ERST1) {
#    print_time("embedded reestimation (fullcontext)");

#    $opt = "-C $cfg{'nvf'} -s $stats{'cmp'} -w 0.0";

#    # embedded reestimation
#    print("\n\nEmbedded Re-estimation\n");
#    shell("$HERest{'ful'} -H $fullmmf{'cmp'} -N $fullmmf{'dur'} -M $model{'cmp'} -R $model{'dur'} $opt $lst{'ful'} $lst{'ful'}");

#    # compress reestimated model
#    foreach $set (@SET) {
#       shell("gzip -c $fullmmf{$set} > ${fullmmf{$set}}.embedded.gz");
#    }
# }

# # HHEd (tree-based context clustering)
# if ($CXCL1) {
#    print_time("tree-based context clustering");

#    # convert cmp stats to duration ones
#    convstats();

#    # tree-based clustering
#    foreach $set (@SET) {
#       shell("cp $fullmmf{$set} $clusmmf{$set}");

#       $footer = "";
#       foreach $type ( @{ $ref{$set} } ) {
#          if ( $strw{$type} > 0.0 ) {
#             make_edfile_state($type);
#             shell("$HHEd{'trn'} -C $cfg{$type} -H $clusmmf{$set} $mdl{$type} -w $clusmmf{$set} $cxc{$type} $lst{'ful'}");
#             $footer .= "_$type";
#             shell("gzip -c $clusmmf{$set} > $clusmmf{$set}$footer.gz");
#          }
#       }
#    }
# }

# # HERest (embedded reestimation (clustered))
# if ($ERST2) {
#    print_time("embedded reestimation (clustered)");

#    for ( $i = 1 ; $i <= $nIte ; $i++ ) {
#       print("\n\nIteration $i of Embedded Re-estimation\n");
#       shell("$HERest{'ful'} -H $clusmmf{'cmp'} -N $clusmmf{'dur'} -M $model{'cmp'} -R $model{'dur'} $lst{'ful'} $lst{'ful'}");
#    }

#    # compress reestimated mmfs
#    foreach $set (@SET) {
#       shell("gzip -c $clusmmf{$set} > $clusmmf{$set}.embedded.gz");
#    }
# }

# # HHEd (untying the parameter sharing structure)
# if ($UNTIE) {
#    print_time("untying the parameter sharing structure");

#    foreach $set (@SET) {
#       make_edfile_untie($set);
#       shell("$HHEd{'trn'} -H $clusmmf{$set} -w $untymmf{$set} $unt{$set} $lst{'ful'}");
#    }
# }

# # fix variables
# foreach $set (@SET) {
#    $stats{$set} .= ".untied";
#    foreach $type ( @{ $ref{$set} } ) {
#       $tre{$type} .= ".untied";
#       $cxc{$type} .= ".untied";
#    }
# }

# # HERest (embedded reestimation (untied))
# if ($ERST3) {
#    print_time("embedded reestimation (untied)");

#    $opt = "-C $cfg{'nvf'} -s $stats{'cmp'} -w 0.0";

#    print("\n\nEmbedded Re-estimation for untied mmfs\n");
#    shell("$HERest{'ful'} -H $untymmf{'cmp'} -N $untymmf{'dur'} -M $model{'cmp'} -R $model{'dur'} $opt $lst{'ful'} $lst{'ful'}");
# }

# # HHEd (tree-based context clustering)
# if ($CXCL2) {
#    print_time("tree-based context clustering");

#    # convert cmp stats to duration ones
#    convstats();

#    # tree-based clustering
#    foreach $set (@SET) {
#       shell("cp $untymmf{$set} $reclmmf{$set}");

#       $footer = "";
#       foreach $type ( @{ $ref{$set} } ) {
#          make_edfile_state($type);
#          shell("$HHEd{'trn'} -C $cfg{$type} -H $reclmmf{$set} $mdl{$type} -w $reclmmf{$set} $cxc{$type} $lst{'ful'}");

#          $footer .= "_$type";
#          shell("gzip -c $reclmmf{$set} > $reclmmf{$set}$footer.gz");
#       }
#       shell("gzip -c $reclmmf{$set} > $reclmmf{$set}.nonembedded.gz");
#    }
# }

# # HERest (embedded reestimation (re-clustered))
# if ($ERST4) {
#    print_time("embedded reestimation (re-clustered)");

#    for ( $i = 1 ; $i <= $nIte ; $i++ ) {
#       print("\n\nIteration $i of Embedded Re-estimation\n");
#       shell("$HERest{'ful'} -H $reclmmf{'cmp'} -N $reclmmf{'dur'} -M $model{'cmp'} -R $model{'dur'} $lst{'ful'} $lst{'ful'}");
#    }

#    # compress reestimated mmfs
#    foreach $set (@SET) {
#       shell("gzip -c $reclmmf{$set} > $reclmmf{$set}.embedded.gz");
#    }
# }

# # HSMMAlign (forced alignment for no-silent GV)
# if ($FALGN) {
#    print_time("forced alignment for no-silent GV");

#    if ( ( $useHmmGV && $nosilgv && @slnt > 0 ) || $useMSPF || $useDNN ) {

#       # make directory
#       mkdir "$gvdir/fal",       0755;
#       mkdir "$gvfaldir{'phn'}", 0755;
#       mkdir "$gvfaldir{'stt'}", 0755;

#       # forced alignment
#       shell("$HSMMAlign -f -H $reclmmf{'cmp'} -N $reclmmf{'dur'} -m $gvfaldir{'stt'} $lst{'ful'} $lst{'ful'}");

#       # convert state alignment to phoneme alignment
#       convert_state2phone();
#    }
# }

# # making global variance
# if ($MCDGV) {
#    print_time("making global variance");

#    if ($useHmmGV) {

#       # make directories
#       mkdir "$gvdatdir",      0755;
#       mkdir "$gvlabdir",      0755;
#       mkdir "$gvmodels",      0755;
#       mkdir "$gvdir/proto",   0755;
#       mkdir "$gvdir/stats",   0755;
#       mkdir "$gvdir/trees",   0755;
#       mkdir "$gvdir/edfiles", 0755;

#       # make proto
#       make_proto_gv();

#       # make training data, labels, scp, list, and mlf
#       make_data_gv();

#       # make average model
#       shell("$HCompV{'gv'} -o $avermmf{'gv'} -M $gvmodels $prtfile{'gv'}");

#       if ($cdgv) {

#          # make full context depdent model
#          copy_aver2full_gv();
#          shell("$HERest{'gv'} -C $cfg{'nvf'} -s $stats{'gv'} -w 0.0 -H $fullmmf{'gv'} -M $gvmodels $lst{'gv'}");

#          # context-clustering
#          my $s = 1;
#          shell("cp $fullmmf{'gv'} $clusmmf{'gv'}");
#          foreach $type (@cmp) {
#             make_edfile_state_gv( $type, $s );
#             shell("$HHEd{'trn'} -H $clusmmf{'gv'} $gvmdl{$type} -w $clusmmf{'gv'} $gvcxc{$type} $lst{'gv'}");
#             $s++;
#          }

#          # re-estimation
#          shell("$HERest{'gv'} -H $clusmmf{'gv'} -M $gvmodels $lst{'gv'}");
#       }
#       else {
#          copy_aver2clus_gv();
#       }
#    }
# }

# # HHEd (making unseen models (GV))
# if ($MKUNG) {
#    print_time("making unseen models (GV)");

#    if ($useHmmGV) {
#       if ($cdgv) {
#          make_edfile_mkunseen_gv();
#          shell("$HHEd{'trn'} -H $clusmmf{'gv'} -w $clsammf{'gv'} $mku{'gv'} $lst{'gv'}");
#       }
#       else {
#          copy_clus2clsa_gv();
#       }
#    }
# }

# # HMGenS & SPTK (training modulation spectrum-based postfilter (1mix))
# if ($MSPF1) {
#    print_time("training modulation spectrum-based postfilter (1mix)");

#    if ($useMSPF) {

#       $mix     = '1mix';
#       $gentype = "gen/$mix/$pgtype";

#       # make directories
#       mkdir "$mspffaldir",               0755;
#       mkdir "$mspfdir/gen",              0755;
#       mkdir "$mspfdir/gen/$mix",         0755;
#       mkdir "$mspfdir/gen/$mix/$pgtype", 0755;
#       foreach $dir ( 'dat', 'stats' ) {
#          mkdir "$mspfdir/$dir",                  0755;
#          mkdir "$mspfdir/$dir/nat",              0755;
#          mkdir "$mspfdir/$dir/gen",              0755;
#          mkdir "$mspfdir/$dir/gen/$mix",         0755;
#          mkdir "$mspfdir/$dir/gen/$mix/$pgtype", 0755;
#       }

#       # make scp and fullcontext forced-aligned label files
#       make_full_fal();

#       # synthesize speech parameters using model alignment
#       shell("$HMGenS -C $cfg{'apg'} -S $scp{'mspf'} -c $pgtype -H $reclmmf{'cmp'} -N $reclmmf{'dur'} -M $mspfdir/$gentype $lst{'ful'} $lst{'ful'}");

#       # estimate statistics for modulation spectrum
#       make_mspf($gentype);
#    }
# }

# # HHEd (making unseen models (1mix))
# if ($MKUN1) {
#    print_time("making unseen models (1mix)");

#    foreach $set (@SET) {
#       make_edfile_mkunseen($set);
#       shell("$HHEd{'trn'} -H $reclmmf{$set} -w $rclammf{$set}.1mix $mku{$set} $lst{'ful'}");
#    }
# }

# # HMGenS (generating speech parameter sequences (1mix))
# if ($PGEN1) {
#    print_time("generating speech parameter sequences (1mix)");

#    $mix = '1mix';
#    $dir = "${prjdir}/gen/ver${ver}/$mix/$pgtype";
#    mkdir "${prjdir}/gen/ver${ver}/$mix", 0755;
#    mkdir $dir, 0755;

#    # generate parameter
#    shell("$HMGenS -S $scp{'gen'} -c $pgtype -H $rclammf{'cmp'}.$mix -N $rclammf{'dur'}.$mix -M $dir $tiedlst{'cmp'} $tiedlst{'dur'}");
# }

# # SPTK (synthesizing waveforms (1mix))
# if ($WGEN1) {
#    print_time("synthesizing waveforms (1mix)");

#    $mix = '1mix';
#    $dir = "${prjdir}/gen/ver${ver}/$mix/$pgtype";
#    if ($useMSPF) {
#       $pf = 2;
#    }
#    elsif ( !$useHmmGV ) {
#       $pf = 1;
#    }
#    else {
#       $pf = 0;
#    }
#    gen_wave( "$dir", $pf );
# }

# # HHEd (converting mmfs to the HTS voice format)
# if ( $CONVM && !$usestraight ) {
#    print_time("converting mmfs to the HTS voice format");

#    # models and trees
#    foreach $set (@SET) {
#       foreach $type ( @{ $ref{$set} } ) {
#          make_edfile_convert($type);
#          shell("$HHEd{'trn'} -H $reclmmf{$set} $cnv{$type} $lst{'ful'}");
#          shell("mv $trd{$set}/trees.$strb{$type} $trv{$type}");
#          shell("mv $model{$set}/pdf.$strb{$type} $pdf{$type}");
#       }
#    }

#    # window coefficients
#    foreach $type (@cmp) {
#       shell("cp $windir/${type}.win* $voice");
#    }

#    # gv pdfs
#    if ($useHmmGV) {
#       my $s = 1;
#       foreach $type (@cmp) {    # convert hts_engine format
#          make_edfile_convert_gv($type);
#          shell("$HHEd{'trn'} -H $clusmmf{'gv'} $gvcnv{$type} $lst{'gv'}");
#          shell("mv $gvdir/trees.$s $gvtrv{$type}");
#          shell("mv $gvdir/pdf.$s $gvpdf{$type}");
#          $s++;
#       }
#    }

#    # low-pass filter
#    make_lpf();

#    # make HTS voice
#    make_htsvoice( "$voice", "${dset}_${spkr}" );
# }

# # hts_engine (synthesizing waveforms using hts_engine)
# if ( $ENGIN && !$usestraight ) {
#    print_time("synthesizing waveforms using hts_engine");

#    $dir = "${prjdir}/gen/ver${ver}/hts_engine";
#    mkdir ${dir}, 0755;

#    # hts_engine command line & options
#    $hts_engine = "$ENGINE -m ${voice}/${dset}_${spkr}.htsvoice ";
#    if ( !$useHmmGV ) {
#       if ( $gm == 0 ) {
#          $hts_engine .= "-b " . ( $pf_mcp - 1.0 ) . " ";
#       }
#       else {
#          $hts_engine .= "-b " . $pf_lsp . " ";
#       }
#    }

#    # generate waveform using hts_engine
#    open( SCP, "$scp{'gen'}" ) || die "Cannot open $!";
#    while (<SCP>) {
#       $lab = $_;
#       chomp($lab);
#       $base = `basename $lab .lab`;
#       chomp($base);

#       print " Synthesizing a speech waveform from $lab using hts_engine...";
#       shell("$hts_engine -or ${dir}/${base}.raw -ow ${dir}/${base}.wav -ot ${dir}/${base}.trace $lab");
#       print "done\n";
#    }
#    close(SCP);
# }

# # making training data for deep neural network
# if ($MKDAT) {
#    print_time("making training data for deep neural network");

#    if ($useDNN) {
#       mkdir "$dnndir/ffi",       0755;
#       mkdir "$dnnffidir{'ful'}", 0755;

#       make_train_data_dnn();
#    }
# }

# # TensorFlow (training a deep neural network)
# if ($TRDNN) {
#    print_time("training a deep neural network");

#    if ($useDNN) {
#       mkdir "$dnnmodels", 0755;

#       shell("$PYTHON $datdir/scripts/DNNTraining.py -C $cfg{'tdn'} -S $scp{'tdn'} -H $dnnmodels -z $datdir/stats");
#    }
# }

# # HMGenS & SPTK (training modulation spectrum-based postfilter (dnn))
# if ($MSPFD) {
#    print_time("training modulation spectrum-based postfilter (dnn)");

#    if ( $useDNN && $useMSPF ) {

#       $mix     = 'dnn';
#       $gentype = "gen/$mix/$pgtype";

#       # make directories
#       mkdir "$mspfdir/gen",              0755;
#       mkdir "$mspfdir/gen/$mix",         0755;
#       mkdir "$mspfdir/gen/$mix/$pgtype", 0755;
#       foreach $dir ( 'dat', 'stats' ) {
#          mkdir "$mspfdir/$dir",                  0755;
#          mkdir "$mspfdir/$dir/nat",              0755;
#          mkdir "$mspfdir/$dir/gen",              0755;
#          mkdir "$mspfdir/$dir/gen/$mix",         0755;
#          mkdir "$mspfdir/$dir/gen/$mix/$pgtype", 0755;
#       }

#       # synthesize speech parameters using model alignment
#       shell("$PYTHON $datdir/scripts/DNNSynthesis.py -C $cfg{'sdn'} -S $scp{'tdn'} -H $dnnmodels -M $mspfdir/$gentype");
#       gen_param("$mspfdir/$gentype");

#       # estimate statistics for modulation spectrum
#       make_mspf($gentype);
#    }
# }

# # TensorFlow & SPTK (generating speech parameter sequences (dnn))
# if ($PGEND) {
#    print_time("generating speech parameter sequences (dnn)");

#    if ($useDNN) {
#       $mix = 'dnn';
#       $dir = "${prjdir}/gen/ver${ver}/$mix/$pgtype";
#       mkdir "${prjdir}/gen/ver${ver}/$mix", 0755;
#       mkdir $dir, 0755;

#       # predict duration from HMMs
#       shell("$HMGenS -S $scp{'gen'} -c $pgtype -H $rclammf{'cmp'}.1mix -N $rclammf{'dur'}.1mix -M $dir $tiedlst{'cmp'} $tiedlst{'dur'}");
#       foreach $type (@cmp) {
#          shell("rm -f $dir/*.$type");
#       }

#       mkdir "$dnnffidir{'gen'}", 0755;
#       convert_dur2lab($dir);
#       make_gen_data_dnn($dir);

#       # generate parameter
#       shell("$PYTHON $datdir/scripts/DNNSynthesis.py -C $cfg{'sdn'} -S $scp{'sdn'} -H $dnnmodels -M $dir");

#       # generate smooth parameter sequence
#       gen_param("$dir");
#    }
# }

# # SPTK (synthesizing waveforms (dnn))
# if ($WGEND) {
#    print_time("synthesizing waveforms (dnn)");

#    if ($useDNN) {
#       $mix = 'dnn';
#       $dir = "${prjdir}/gen/ver${ver}/$mix/$pgtype";
#       if ($useMSPF) {
#          $pf = 2;
#       }
#       else {
#          $pf = 1;
#       }
#       gen_wave( "$dir", $pf );
#    }
# }

# # TensorFlow (trajectory training considering global variance)
# if ($TRJGV) {
#    print_time("trajectory training considering global variance");

#    if ($useDNN) {
#       mkdir "$dnnmodelsdir{'trj'}", 0755;

#       shell("cp $dnnmodels/model.ckpt.* $dnnmodelsdir{'trj'}");
#       shell("$PYTHON $datdir/scripts/DNNTraining.py -C $cfg{'trj'} -S $scp{'tdn'} -H $dnnmodelsdir{'trj'} -z $datdir/stats -w $windir");
#    }
# }

# # HMGenS & SPTK (training modulation spectrum-based postfilter (trj))
# if ($MSPFT) {
#    print_time("training modulation spectrum-based postfilter (trj)");

#    if ( $useDNN && $useMSPF ) {

#       $mix     = 'trj';
#       $gentype = "gen/$mix/$pgtype";

#       # make directories
#       mkdir "$mspfdir/gen",              0755;
#       mkdir "$mspfdir/gen/$mix",         0755;
#       mkdir "$mspfdir/gen/$mix/$pgtype", 0755;
#       foreach $dir ( 'dat', 'stats' ) {
#          mkdir "$mspfdir/$dir",                  0755;
#          mkdir "$mspfdir/$dir/nat",              0755;
#          mkdir "$mspfdir/$dir/gen",              0755;
#          mkdir "$mspfdir/$dir/gen/$mix",         0755;
#          mkdir "$mspfdir/$dir/gen/$mix/$pgtype", 0755;
#       }

#       # synthesize speech parameters using model alignment
#       shell("$PYTHON $datdir/scripts/DNNSynthesis.py -C $cfg{'sdn'} -S $scp{'tdn'} -H $dnnmodelsdir{'trj'} -M $mspfdir/$gentype");
#       gen_param("$mspfdir/$gentype");

#       # estimate statistics for modulation spectrum
#       make_mspf($gentype);
#    }
# }

# # TensorFlow & SPTK (generating speech parameter sequences (trj))
# if ($PGENT) {
#    print_time("generating speech parameter sequences (trj)");

#    if ($useDNN) {
#       $mix = 'trj';
#       $dir = "${prjdir}/gen/ver${ver}/$mix/$pgtype";
#       mkdir "${prjdir}/gen/ver${ver}/$mix", 0755;
#       mkdir $dir, 0755;

#       # predict duration from HMMs
#       shell("$HMGenS -S $scp{'gen'} -c $pgtype -H $rclammf{'cmp'}.1mix -N $rclammf{'dur'}.1mix -M $dir $tiedlst{'cmp'} $tiedlst{'dur'}");
#       foreach $type (@cmp) {
#          shell("rm -f $dir/*.$type");
#       }

#       mkdir "$dnnffidir{'gen'}", 0755;
#       convert_dur2lab($dir);
#       make_gen_data_dnn($dir);

#       # generate parameter
#       shell("$PYTHON $datdir/scripts/DNNSynthesis.py -C $cfg{'sdn'} -S $scp{'sdn'} -H $dnnmodelsdir{'trj'} -M $dir");

#       # generate smooth parameter sequence
#       gen_param("$dir");
#    }
# }

# # SPTK (synthesizing waveforms (trj))
# if ($WGENT) {
#    print_time("synthesizing waveforms (trj)");

#    if ($useDNN) {
#       $mix = 'trj';
#       $dir = "${prjdir}/gen/ver${ver}/$mix/$pgtype";
#       if ($useMSPF) {
#          $pf = 2;
#       }
#       else {
#          $pf = 1;
#       }
#       gen_wave( "$dir", $pf );
#    }
# }

# # HERest (semi-tied covariance matrices)
# if ($SEMIT) {
#    print_time("semi-tied covariance matrices");

#    foreach $set (@SET) {
#       shell("cp $reclmmf{$set} $stcmmf{$set}");
#    }

#    $opt = "-C $cfg{'stc'} -K $model{'cmp'} stc -u smvdmv";

#    make_stc_base();

#    shell("$HERest{'ful'} -H $stcmmf{'cmp'} -N $stcmmf{'dur'} -M $model{'cmp'} -R $model{'dur'} $opt $lst{'ful'} $lst{'ful'}");

#    # compress reestimated mmfs
#    foreach $set (@SET) {
#       shell("gzip -c $stcmmf{$set} > $stcmmf{$set}.embedded.gz");
#    }
# }

# # HHEd (making unseen models (stc))
# if ($MKUNS) {
#    print_time("making unseen models (stc)");

#    foreach $set (@SET) {
#       make_edfile_mkunseen($set);
#       shell("$HHEd{'trn'} -H $stcmmf{$set} -w $stcammf{$set} $mku{$set} $lst{'ful'}");
#    }
# }

# # HMGenS (generating speech parameter sequences (stc))
# if ($PGENS) {
#    print_time("generating speech parameter sequences (stc)");

#    $mix = 'stc';
#    $dir = "${prjdir}/gen/ver${ver}/$mix/$pgtype";
#    mkdir "${prjdir}/gen/ver${ver}/$mix", 0755;
#    mkdir $dir, 0755;

#    # generate parameter
#    shell("$HMGenS -S $scp{'gen'} -c $pgtype -H $stcammf{'cmp'} -N $stcammf{'dur'} -M $dir $tiedlst{'cmp'} $tiedlst{'dur'}");
# }

# # SPTK (synthesizing waveforms (stc))
# if ($WGENS) {
#    print_time("synthesizing waveforms (stc)");

#    $mix = 'stc';
#    $dir = "${prjdir}/gen/ver${ver}/$mix/$pgtype";
#    if ( !$useHmmGV ) {
#       $pf = 1;
#    }
#    else {
#       $pf = 0;
#    }
#    gen_wave( "$dir", $pf );
# }

# # HHED (increasing the number of mixture components (1mix -> 2mix))
# if ($UPMIX) {
#    print_time("increasing the number of mixture components (1mix -> 2mix)");

#    $set = 'cmp';
#    make_edfile_upmix($set);
#    shell("$HHEd{'trn'} -H $reclmmf{$set} -w $reclmmf{$set}.2mix $upm{$set} $lst{'ful'}");

#    $set = 'dur';
#    shell("cp $reclmmf{$set} $reclmmf{$set}.2mix");
# }

# # fix variables
# $reclmmf{'dur'} .= ".2mix";
# $reclmmf{'cmp'} .= ".2mix";
# $rclammf{'dur'} .= ".2mix";
# $rclammf{'cmp'} .= ".2mix";

# # HERest (embedded reestimation (2mix))
# if ($ERST5) {
#    print_time("embedded reestimation (2mix)");

#    for ( $i = 1 ; $i <= $nIte ; $i++ ) {
#       print("\n\nIteration $i of Embedded Re-estimation\n");
#       shell("$HERest{'ful'} -H $reclmmf{'cmp'} -N $reclmmf{'dur'} -M $model{'cmp'} -R $model{'dur'} $lst{'ful'} $lst{'ful'}");
#    }

#    # compress reestimated mmfs
#    foreach $set (@SET) {
#       shell("gzip -c $reclmmf{$set} > $reclmmf{$set}.embedded.gz");
#    }
# }

# # HHEd (making unseen models (2mix))
# if ($MKUN2) {
#    print_time("making unseen models (2mix)");

#    foreach $set (@SET) {
#       make_edfile_mkunseen($set);
#       shell("$HHEd{'trn'} -H $reclmmf{$set} -w $rclammf{$set} $mku{$set} $lst{'ful'}");
#    }
# }

# # HMGenS (generating speech parameter sequences (2mix))
# if ($PGEN2) {
#    print_time("generating speech parameter sequences (2mix)");

#    $mix = '2mix';
#    $dir = "${prjdir}/gen/ver${ver}/$mix/$pgtype";
#    mkdir "${prjdir}/gen/ver${ver}/$mix", 0755;
#    mkdir $dir, 0755;

#    # generate parameter
#    shell("$HMGenS -S $scp{'gen'} -c $pgtype -H $rclammf{'cmp'} -N $rclammf{'dur'} -M $dir $tiedlst{'cmp'} $tiedlst{'dur'}");
# }

# # SPTK (synthesizing waveforms (2mix))
# if ($WGEN2) {
#    print_time("synthesizing waveforms (2mix)");

#    $mix = '2mix';
#    $dir = "${prjdir}/gen/ver${ver}/$mix/$pgtype";
#    if ( !$useHmmGV ) {
#       $pf = 1;
#    }
#    else {
#       $pf = 0;
#    }
#    gen_wave( "$dir", $pf );
# }

# # sub routines ============================
# sub shell($) {
#    my ($command) = @_;
#    my ($exit);

#    $exit = system($command);

#    if ( $exit / 256 != 0 ) {
#       die "Error in $command\n";
#    }
# }

sub print_time ($) {
   my ($message) = @_;
   my ($ruler);
   
   $message .= `date`;

   $ruler = '';
   for ( $i = 0 ; $i <= length($message) + 10 ; $i++ ) {
      $ruler .= '=';
   }

   print "\n$ruler\n";
   print "Start @_ at " . `date`;
   print "$ruler\n\n";
}

# # sub routine for generating proto-type model
# sub make_proto {
#    my ( $i, $j, $k, $s );

#    # output prototype definition
#    # open proto type definition file
#    open( PROTO, ">$prtfile{'cmp'}" ) || die "Cannot open $!";

#    # output header
#    # output vector size & feature type
#    print PROTO "~o <VecSize> $vSize{'cmp'}{'total'} <USER> <DIAGC>";

#    # output information about multi-space probability distribution (MSD)
#    print PROTO "<MSDInfo> $nstream{'cmp'}{'total'} ";
#    foreach $type (@cmp) {
#       for ( $s = $strb{$type} ; $s <= $stre{$type} ; $s++ ) {
#          print PROTO " $msdi{$type} ";
#       }
#    }

#    # output information about stream
#    print PROTO "<StreamInfo> $nstream{'cmp'}{'total'}";
#    foreach $type (@cmp) {
#       for ( $s = $strb{$type} ; $s <= $stre{$type} ; $s++ ) {
#          printf PROTO " %d", $vSize{'cmp'}{$type} / $nstream{'cmp'}{$type};
#       }
#    }
#    print PROTO "\n";

#    # output HMMs
#    print PROTO "<BeginHMM>\n";
#    printf PROTO "  <NumStates> %d\n", $nState + 2;

#    # output HMM states
#    for ( $i = 2 ; $i <= $nState + 1 ; $i++ ) {

#       # output state information
#       print PROTO "  <State> $i\n";

#       # output stream weight
#       print PROTO "  <SWeights> $nstream{'cmp'}{'total'}";
#       foreach $type (@cmp) {
#          for ( $s = $strb{$type} ; $s <= $stre{$type} ; $s++ ) {
#             print PROTO " $strw{$type}";
#          }
#       }
#       print PROTO "\n";

#       # output stream information
#       foreach $type (@cmp) {
#          for ( $s = $strb{$type} ; $s <= $stre{$type} ; $s++ ) {
#             print PROTO "  <Stream> $s\n";
#             if ( $msdi{$type} == 0 ) {    # non-MSD stream
#                                           # output mean vector
#                printf PROTO "    <Mean> %d\n", $vSize{'cmp'}{$type} / $nstream{'cmp'}{$type};
#                for ( $k = 1 ; $k <= $vSize{'cmp'}{$type} / $nstream{'cmp'}{$type} ; $k++ ) {
#                   print PROTO "      " if ( $k % 10 == 1 );
#                   print PROTO "0.0 ";
#                   print PROTO "\n" if ( $k % 10 == 0 );
#                }
#                print PROTO "\n" if ( $k % 10 != 1 );

#                # output covariance matrix (diag)
#                printf PROTO "    <Variance> %d\n", $vSize{'cmp'}{$type} / $nstream{'cmp'}{$type};
#                for ( $k = 1 ; $k <= $vSize{'cmp'}{$type} / $nstream{'cmp'}{$type} ; $k++ ) {
#                   print PROTO "      " if ( $k % 10 == 1 );
#                   print PROTO "1.0 ";
#                   print PROTO "\n" if ( $k % 10 == 0 );
#                }
#                print PROTO "\n" if ( $k % 10 != 1 );
#             }
#             else {    # MSD stream
#                       # output MSD
#                print PROTO "  <NumMixes> 2\n";

#                # output 1st space (non 0-dimensional space)
#                # output space weights
#                print PROTO "  <Mixture> 1 0.5000\n";

#                # output mean vector
#                printf PROTO "    <Mean> %d\n", $vSize{'cmp'}{$type} / $nstream{'cmp'}{$type};
#                for ( $k = 1 ; $k <= $vSize{'cmp'}{$type} / $nstream{'cmp'}{$type} ; $k++ ) {
#                   print PROTO "      " if ( $k % 10 == 1 );
#                   print PROTO "0.0 ";
#                   print PROTO "\n" if ( $k % 10 == 0 );
#                }
#                print PROTO "\n" if ( $k % 10 != 1 );

#                # output covariance matrix (diag)
#                printf PROTO "    <Variance> %d\n", $vSize{'cmp'}{$type} / $nstream{'cmp'}{$type};
#                for ( $k = 1 ; $k <= $vSize{'cmp'}{$type} / $nstream{'cmp'}{$type} ; $k++ ) {
#                   print PROTO "      " if ( $k % 10 == 1 );
#                   print PROTO "1.0 ";
#                   print PROTO "\n" if ( $k % 10 == 0 );
#                }
#                print PROTO "\n" if ( $k % 10 != 1 );

#                # output 2nd space (0-dimensional space)
#                print PROTO "  <Mixture> 2 0.5000\n";
#                print PROTO "    <Mean> 0\n";
#                print PROTO "    <Variance> 0\n";
#             }
#          }
#       }
#    }

#    # output state transition matrix
#    printf PROTO "  <TransP> %d\n", $nState + 2;
#    print PROTO "    ";
#    for ( $j = 1 ; $j <= $nState + 2 ; $j++ ) {
#       print PROTO "1.000e+0 " if ( $j == 2 );
#       print PROTO "0.000e+0 " if ( $j != 2 );
#    }
#    print PROTO "\n";
#    print PROTO "    ";
#    for ( $i = 2 ; $i <= $nState + 1 ; $i++ ) {
#       for ( $j = 1 ; $j <= $nState + 2 ; $j++ ) {
#          print PROTO "6.000e-1 " if ( $i == $j );
#          print PROTO "4.000e-1 " if ( $i == $j - 1 );
#          print PROTO "0.000e+0 " if ( $i != $j && $i != $j - 1 );
#       }
#       print PROTO "\n";
#       print PROTO "    ";
#    }
#    for ( $j = 1 ; $j <= $nState + 2 ; $j++ ) {
#       print PROTO "0.000e+0 ";
#    }
#    print PROTO "\n";

#    # output footer
#    print PROTO "<EndHMM>\n";

#    close(PROTO);
# }

# sub make_duration_vfloor {
#    my ( $dm, $dv ) = @_;
#    my ( $i, $j );

#    # output variance flooring macro for duration model
#    open( VF, ">$vfloors{'dur'}" ) || die "Cannot open $!";
#    for ( $i = 1 ; $i <= $nState ; $i++ ) {
#       print VF "~v varFloor$i\n";
#       print VF "<Variance> 1\n";
#       $j = $dv * $vflr{'dur'};
#       print VF " $j\n";
#    }
#    close(VF);

#    # output average model for duration model
#    open( MMF, ">$avermmf{'dur'}" ) || die "Cannot open $!";
#    print MMF "~o\n";
#    print MMF "<STREAMINFO> $nState";
#    for ( $i = 1 ; $i <= $nState ; $i++ ) {
#       print MMF " 1";
#    }
#    print MMF "\n";
#    print MMF "<VECSIZE> ${nState}<NULLD><USER><DIAGC>\n";
#    print MMF "~h \"$avermmf{'dur'}\"\n";
#    print MMF "<BEGINHMM>\n";
#    print MMF "<NUMSTATES> 3\n";
#    print MMF "<STATE> 2\n";
#    for ( $i = 1 ; $i <= $nState ; $i++ ) {
#       print MMF "<STREAM> $i\n";
#       print MMF "<MEAN> 1\n";
#       print MMF " $dm\n";
#       print MMF "<VARIANCE> 1\n";
#       print MMF " $dv\n";
#    }
#    print MMF "<TRANSP> 3\n";
#    print MMF " 0.0 1.0 0.0\n";
#    print MMF " 0.0 0.0 1.0\n";
#    print MMF " 0.0 0.0 0.0\n";
#    print MMF "<ENDHMM>\n";
#    close(MMF);
# }

# # sub routine for generating proto-type model for GV
# sub make_proto_gv {
#    my ( $s, $type, $k );

#    open( PROTO, "> $prtfile{'gv'}" ) || die "Cannot open $!";
#    $s = 0;
#    foreach $type (@cmp) {
#       $s += $ordr{$type};
#    }
#    print PROTO "~o <VecSize> $s <USER> <DIAGC>\n";
#    print PROTO "<MSDInfo> $nPdfStreams{'cmp'} ";
#    foreach $type (@cmp) {
#       print PROTO "0 ";
#    }
#    print PROTO "\n";
#    print PROTO "<StreamInfo> $nPdfStreams{'cmp'} ";
#    foreach $type (@cmp) {
#       print PROTO "$ordr{$type} ";
#    }
#    print PROTO "\n";
#    print PROTO "<BeginHMM>\n";
#    print PROTO "  <NumStates> 3\n";
#    print PROTO "  <State> 2\n";
#    $s = 1;
#    foreach $type (@cmp) {
#       print PROTO "  <Stream> $s\n";
#       print PROTO "    <Mean> $ordr{$type}\n";
#       for ( $k = 1 ; $k <= $ordr{$type} ; $k++ ) {
#          print PROTO "      " if ( $k % 10 == 1 );
#          print PROTO "0.0 ";
#          print PROTO "\n" if ( $k % 10 == 0 );
#       }
#       print PROTO "\n" if ( $k % 10 != 1 );
#       print PROTO "    <Variance> $ordr{$type}\n";
#       for ( $k = 1 ; $k <= $ordr{$type} ; $k++ ) {
#          print PROTO "      " if ( $k % 10 == 1 );
#          print PROTO "1.0 ";
#          print PROTO "\n" if ( $k % 10 == 0 );
#       }
#       print PROTO "\n" if ( $k % 10 != 1 );
#       $s++;
#    }
#    print PROTO "  <TransP> 3\n";
#    print PROTO "    0.000e+0 1.000e+0 0.000e+0 \n";
#    print PROTO "    0.000e+0 0.000e+0 1.000e+0 \n";
#    print PROTO "    0.000e+0 0.000e+0 0.000e+0 \n";
#    print PROTO "<EndHMM>\n";
#    close(PROTO);
# }

# # sub routine for making training data, labels, scp, list, and mlf for GV
# sub make_data_gv {
#    my ( $type, $cmp, $base, $str, @arr, $start, $end, $find, $i, $j );

#    shell("rm -f $scp{'gv'}");
#    shell("touch $scp{'gv'}");
#    open( SCP, $scp{'trn'} ) || die "Cannot open $!";
#    if ($cdgv) {
#       open( LST, "> $gvdir/tmp.list" );
#    }
#    while (<SCP>) {
#       $cmp = $_;
#       chomp($cmp);
#       $base = `basename $cmp .cmp`;
#       chomp($base);
#       print " Making data, labels, and scp from $base.lab for GV...";
#       shell("rm -f $gvdatdir/tmp.cmp");
#       shell("touch $gvdatdir/tmp.cmp");
#       $i = 0;

#       foreach $type (@cmp) {
#          if ( $nosilgv && @slnt > 0 ) {
#             shell("rm -f $gvdatdir/tmp.$type");
#             shell("touch $gvdatdir/tmp.$type");
#             open( F, "$gvfaldir{'phn'}/$base.lab" ) || die "Cannot open $!";
#             while ( $str = <F> ) {
#                chomp($str);
#                @arr = split( / /, $str );
#                $find = 0;
#                for ( $j = 0 ; $j < @slnt ; $j++ ) {
#                   if ( $arr[2] eq "$slnt[$j]" ) { $find = 1; last; }
#                }
#                if ( $find == 0 ) {
#                   $start = int( $arr[0] * ( 1.0E-07 / ( $fs / $sr ) ) );
#                   $end   = int( $arr[1] * ( 1.0E-07 / ( $fs / $sr ) ) );
#                   shell("$BCUT -s $start -e $end -l $ordr{$type} < $datdir/$type/$base.$type >> $gvdatdir/tmp.$type");
#                }
#             }
#             close(F);
#          }
#          else {
#             shell("cp $datdir/$type/$base.$type $gvdatdir/tmp.$type");
#          }
#          if ( $msdi{$type} == 0 ) {
#             shell("cat      $gvdatdir/tmp.$type                              | $VSTAT -d -l $ordr{$type} -o 2 >> $gvdatdir/tmp.cmp");
#          }
#          else {
#             shell("$X2X +fa $gvdatdir/tmp.$type | grep -v '1e+10' | $X2X +af | $VSTAT -d -l $ordr{$type} -o 2 >> $gvdatdir/tmp.cmp");
#          }
#          system("rm -f $gvdatdir/tmp.$type");
#          $i += 4 * $ordr{$type};
#       }
#       shell("$PERL $datdir/scripts/addhtkheader.pl $sr $fs $i 9 $gvdatdir/tmp.cmp > $gvdatdir/$base.cmp");
#       $i = `$NAN $gvdatdir/$base.cmp`;
#       chomp($i);
#       if ( length($i) > 0 ) {
#          shell("rm -f $gvdatdir/$base.cmp");
#       }
#       else {
#          shell("echo $gvdatdir/$base.cmp >> $scp{'gv'}");
#          if ($cdgv) {
#             open( LAB, "$datdir/labels/full/$base.lab" ) || die "Cannot open $!";
#             $str = <LAB>;
#             close(LAB);
#             chomp($str);
#             while ( index( $str, " " ) >= 0 || index( $str, "\t" ) >= 0 ) { substr( $str, 0, 1 ) = ""; }
#             open( LAB, "> $gvlabdir/$base.lab" ) || die "Cannot open $!";
#             print LAB "$str\n";
#             close(LAB);
#             print LST "$str\n";
#          }
#       }
#       system("rm -f $gvdatdir/tmp.cmp");
#       print "done\n";
#    }
#    if ($cdgv) {
#       close(LST);
#       system("sort -u $gvdir/tmp.list > $lst{'gv'}");
#       system("rm -f $gvdir/tmp.list");
#    }
#    else {
#       system("echo gv > $lst{'gv'}");
#    }
#    close(SCP);

#    # make mlf
#    open( MLF, "> $mlf{'gv'}" ) || die "Cannot open $!";
#    print MLF "#!MLF!#\n";
#    print MLF "\"*/*.lab\" -> \"$gvlabdir\"\n";
#    close(MLF);
# }

# # sub routine to copy average.mmf to full.mmf for GV
# sub copy_aver2full_gv {
#    my ( $find, $head, $tail, $str );

#    $find = 0;
#    $head = "";
#    $tail = "";
#    open( MMF, "$avermmf{'gv'}" ) || die "Cannot open $!";
#    while ( $str = <MMF> ) {
#       if ( index( $str, "~h" ) >= 0 ) {
#          $find = 1;
#       }
#       elsif ( $find == 0 ) {
#          $head .= $str;
#       }
#       else {
#          $tail .= $str;
#       }
#    }
#    close(MMF);
#    $head .= `cat $vfloors{'gv'}`;
#    open( LST, "$lst{'gv'}" )       || die "Cannot open $!";
#    open( MMF, "> $fullmmf{'gv'}" ) || die "Cannot open $!";
#    print MMF "$head";
#    while ( $str = <LST> ) {
#       chomp($str);
#       print MMF "~h \"$str\"\n";
#       print MMF "$tail";
#    }
#    close(MMF);
#    close(LST);
# }

# sub copy_aver2clus_gv {
#    my ( $find, $head, $mid, $tail, $str, $tmp, $s, @pdfs );

#    # initaialize
#    $find = 0;
#    $head = "";
#    $mid  = "";
#    $tail = "";
#    $s    = 0;
#    @pdfs = ();
#    foreach $type (@cmp) {
#       push( @pdfs, "" );
#    }

#    # load
#    open( MMF, "$avermmf{'gv'}" ) || die "Cannot open $!";
#    while ( $str = <MMF> ) {
#       if ( index( $str, "~h" ) >= 0 ) {
#          $head .= `cat $vfloors{'gv'}`;
#          last;
#       }
#       else {
#          $head .= $str;
#       }
#    }
#    while ( $str = <MMF> ) {
#       if ( index( $str, "<STREAM>" ) >= 0 ) {
#          last;
#       }
#       else {
#          $mid .= $str;
#       }
#    }
#    while ( $str = <MMF> ) {
#       if ( index( $str, "<TRANSP>" ) >= 0 ) {
#          $tail .= $str;
#          last;
#       }
#       elsif ( index( $str, "<STREAM>" ) >= 0 ) {
#          $s++;
#       }
#       else {
#          $pdfs[$s] .= $str;
#       }
#    }
#    while ( $str = <MMF> ) {
#       $tail .= $str;
#    }
#    close(MMF);

#    # save
#    open( MMF, "> $clusmmf{'gv'}" ) || die "Cannot open $!";
#    print MMF "$head";
#    $s = 1;
#    foreach $type (@cmp) {
#       print MMF "~p \"gv_${type}_1\"\n";
#       print MMF "<STREAM> $s\n";
#       print MMF "$pdfs[$s-1]";
#       $s++;
#    }
#    print MMF "~h \"gv\"\n";
#    print MMF "$mid";
#    $s = 1;
#    foreach $type (@cmp) {
#       print MMF "<STREAM> $s\n";
#       print MMF "~p \"gv_${type}_1\"\n";
#       $s++;
#    }
#    print MMF "$tail";
#    close(MMF);
#    close(LST);
# }

# sub copy_clus2clsa_gv {
#    shell("cp $clusmmf{'gv'} $clsammf{'gv'}");
#    shell("cp $lst{'gv'} $tiedlst{'gv'}");
# }

# sub convert_state2phone {
#    my ( $line, @FILE, $file, $base, $s, $e, $phone, $ct, @ary );

#    @FILE = glob "$gvfaldir{'stt'}/*.lab";
#    foreach $file (@FILE) {
#       $base = `basename $file`;
#       chomp($base);

#       open( STATE, "$file" ) || die "Cannot open $!";
#       open( PHONE, ">$gvfaldir{'phn'}/$base" ) || die "Cannot open $!";

#       $ct = 1;
#       while ( $line = <STATE> ) {
#          $line =~ s/^\s*(.*?)\s*$/$1/;
#          if ( $ct == 1 ) {
#             @ary   = split /\s+/, $line;
#             $s     = $ary[0];
#             $phone = ( $ary[2] =~ /^.+?-(.+?)\+/ ) ? $1 : "";
#          }
#          elsif ( $ct == $nState ) {
#             @ary = split /\s+/, $line;
#             $e   = $ary[1];
#             $ct  = 0;
#             print PHONE "$s $e $phone\n";
#          }
#          $ct++;
#       }

#       close(PHONE);
#       close(STATE);
#    }
# }

# sub convert_dur2lab($) {
#    my ($gendir) = @_;
#    my ( $line, @FILE, $file, $base, $s, $e, $model, $ct, $t, $p, @ary );

#    $p    = int( 1.0E+07 * $fs / $sr );
#    @FILE = glob "$gendir/*.dur";
#    foreach $file (@FILE) {
#       $base = `basename $file .dur`;
#       chomp($base);

#       open( DUR, "$file" ) || die "Cannot open $!";
#       open( LAB, ">$gendir/$base.lab" ) || die "Cannot open $!";

#       $t  = 0;
#       $ct = 1;
#       while ( $line = <DUR> ) {
#          if ( $ct <= $nState ) {
#             $line =~ s/^\s*(.*?)\s*$/$1/;
#             ( $model, $dur, @ary ) = split /\s+/, $line;
#             $model =~ s/\.state\[\d+\]://;
#             $dur =~ s/duration=//;
#             $s = $t * $p;
#             $e = ( $t + $dur ) * $p;
#             $t += $dur;
#             print LAB "$s $e $model\[" . ( $ct + 1 ) . "\]";
#             print LAB " $model" if ( $ct == 1 );
#             print LAB "\n";
#             $ct++;
#          }
#          else {
#             $ct = 1;
#          }
#       }

#       close(LAB);
#       close(DUR);
#    }
# }

# # sub routine for making labels and scp for DNN
# sub make_train_data_dnn {
#    my ( $line, $base, $lab, $ffi, $ffo );

#    # make frame-by-frame input features
#    foreach $lab ( glob "$gvfaldir{'stt'}/*.lab" ) {
#       $base = `basename $lab .lab`;
#       chomp($base);
#       print " Making data from $lab for neural network training...";
#       $line = "$PERL $datdir/scripts/makefeature.pl $qconf " . int( 1.0E+07 * $fs / $sr ) . " $lab | ";
#       $line .= "$X2X +af > $dnnffidir{'ful'}/$base.ffi";
#       shell($line);
#       print "done\n";
#    }

#    # make scp
#    open( SCP, ">$scp{'tdn'}" ) || die "Cannot open $!";
#    foreach $ffi ( glob "$dnnffidir{'ful'}/*.ffi" ) {
#       $base = `basename $ffi .ffi`;
#       chomp($base);
#       $ffo = "$datdir/ffo/$base.ffo";
#       if ( -s $ffi && -s $ffo ) {
#          print SCP "$ffi $ffo\n";
#       }
#    }
#    close(SCP);
# }

# sub make_gen_data_dnn($) {
#    my ($gendir) = @_;
#    my ( $line, $base, $lab );

#    # make frame-by-frame input features
#    foreach $lab ( glob "$gendir/*.lab" ) {
#       $base = `basename $lab .lab`;
#       chomp($base);
#       print " Making data from $lab for neural network running...";
#       $line = "$PERL $datdir/scripts/makefeature.pl $qconf " . int( 1.0E+07 * $fs / $sr ) . " $lab 2> /dev/null | ";
#       $line .= "$X2X +af > $dnnffidir{'gen'}/$base.ffi";
#       shell($line);
#       print "done\n";
#    }

#    # make scp
#    open( SCP, ">$scp{'sdn'}" ) || die "Cannot open $!";
#    print SCP "$_\n" for glob "$dnnffidir{'gen'}/*.ffi";
#    close(SCP);
# }

# # sub routine for generating baseclass for STC
# sub make_stc_base {
#    my ( $type, $s, $class );

#    # output baseclass definition
#    # open baseclass definition file
#    open( BASE, ">$stcbase{'cmp'}" ) || die "Cannot open $!";

#    # output header
#    print BASE "~b \"stc.base\"\n";
#    print BASE "<MMFIDMASK> *\n";
#    print BASE "<PARAMETERS> MIXBASE\n";

#    # output information about stream
#    print BASE "<STREAMINFO> $nstream{'cmp'}{'total'}";
#    foreach $type (@cmp) {
#       for ( $s = $strb{$type} ; $s <= $stre{$type} ; $s++ ) {
#          printf BASE " %d", $vSize{'cmp'}{$type} / $nstream{'cmp'}{$type};
#       }
#    }
#    print BASE "\n";

#    # output number of baseclasses
#    $class = 0;
#    foreach $type (@cmp) {
#       for ( $s = $strb{$type} ; $s <= $stre{$type} ; $s++ ) {
#          if ( $msdi{$type} == 0 ) {
#             $class++;
#          }
#          else {
#             $class += 2;
#          }
#       }
#    }
#    print BASE "<NUMCLASSES> $class\n";

#    # output baseclass pdfs
#    $class = 1;
#    foreach $type (@cmp) {
#       for ( $s = $strb{$type} ; $s <= $stre{$type} ; $s++ ) {
#          if ( $msdi{$type} == 0 ) {
#             printf BASE "<CLASS> %d {*.state[2-%d].stream[%d].mix[%d]}\n", $class, $nState + 1, $s, 1;
#             $class++;
#          }
#          else {
#             printf BASE "<CLASS> %d {*.state[2-%d].stream[%d].mix[%d]}\n", $class, $nState + 1, $s, 1;
#             printf BASE "<CLASS> %d {*.state[2-%d].stream[%d].mix[%d]}\n", $class + 1, $nState + 1, $s, 2;
#             $class += 2;
#          }
#       }
#    }

#    # close file
#    close(BASE);
# }

# # sub routine for generating config files
# sub make_config {
#    my ( $s, $type, @boolstring, $b, $bSize );
#    $boolstring[0] = 'FALSE';
#    $boolstring[1] = 'TRUE';

#    # config file for model training
#    open( CONF, ">$cfg{'trn'}" ) || die "Cannot open $!";
#    print CONF "APPLYVFLOOR = T\n";
#    print CONF "NATURALREADORDER = T\n";
#    print CONF "NATURALWRITEORDER = T\n";
#    print CONF "VFLOORSCALESTR = \"Vector $nstream{'cmp'}{'total'}";
#    foreach $type (@cmp) {
#       for ( $s = $strb{$type} ; $s <= $stre{$type} ; $s++ ) {
#          print CONF " $vflr{$type}";
#       }
#    }
#    print CONF "\"\n";
#    printf CONF "DURVARFLOORPERCENTILE = %f\n", 100 * $vflr{'dur'};
#    print CONF "APPLYDURVARFLOOR = T\n";
#    print CONF "MAXSTDDEVCOEF = $maxdev\n";
#    print CONF "MINDUR = $mindur\n";
#    close(CONF);

#    # config file for model training (without variance flooring)
#    open( CONF, ">$cfg{'nvf'}" ) || die "Cannot open $!";
#    print CONF "APPLYVFLOOR = F\n";
#    print CONF "DURVARFLOORPERCENTILE = 0.0\n";
#    print CONF "APPLYDURVARFLOOR = F\n";
#    close(CONF);

#    # config file for model tying
#    foreach $type (@cmp) {
#       open( CONF, ">$cfg{$type}" ) || die "Cannot open $!";
#       print CONF "MINLEAFOCC = $mocc{$type}\n";
#       close(CONF);
#    }
#    foreach $type (@dur) {
#       open( CONF, ">$cfg{$type}" ) || die "Cannot open $!";
#       print CONF "MINLEAFOCC = $mocc{$type}\n";
#       close(CONF);
#    }

#    # config file for STC
#    open( CONF, ">$cfg{'stc'}" ) || die "Cannot open $!";
#    print CONF "MAXSEMITIEDITER = 20\n";
#    print CONF "SEMITIEDMACRO   = \"cmp\"\n";
#    print CONF "SAVEFULLC = T\n";
#    print CONF "BASECLASS = \"$stcbase{'cmp'}\"\n";
#    print CONF "TRANSKIND = SEMIT\n";
#    print CONF "USEBIAS   = F\n";
#    print CONF "ADAPTKIND = BASE\n";
#    print CONF "BLOCKSIZE = \"";

#    foreach $type (@cmp) {
#       for ( $s = $strb{$type} ; $s <= $stre{$type} ; $s++ ) {
#          $bSize = $vSize{'cmp'}{$type} / $nstream{'cmp'}{$type} / $nblk{$type};
#          print CONF "IntVec $nblk{$type} ";
#          for ( $b = 1 ; $b <= $nblk{$type} ; $b++ ) {
#             print CONF "$bSize ";
#          }
#       }
#    }
#    print CONF "\"\n";
#    print CONF "BANDWIDTH = \"";
#    foreach $type (@cmp) {
#       for ( $s = $strb{$type} ; $s <= $stre{$type} ; $s++ ) {
#          $bSize = $vSize{'cmp'}{$type} / $nstream{'cmp'}{$type} / $nblk{$type};
#          print CONF "IntVec $nblk{$type} ";
#          for ( $b = 1 ; $b <= $nblk{$type} ; $b++ ) {
#             print CONF "$band{$type} ";
#          }
#       }
#    }
#    print CONF "\"\n";
#    close(CONF);

#    # config file for parameter generation
#    open( CONF, ">$cfg{'syn'}" ) || die "Cannot open $!";
#    print CONF "NATURALREADORDER = T\n";
#    print CONF "NATURALWRITEORDER = T\n";
#    print CONF "USEALIGN = T\n";
#    print CONF "HGEN: TRACE = 1\n";

#    print CONF "PDFSTRSIZE  = \"IntVec $nPdfStreams{'cmp'}";    # PdfStream structure
#    foreach $type (@cmp) {
#       print CONF " $nstream{'cmp'}{$type}";
#    }
#    print CONF "\"\n";

#    print CONF "PDFSTRORDER = \"IntVec $nPdfStreams{'cmp'}";    # order of each PdfStream
#    foreach $type (@cmp) {
#       print CONF " $ordr{$type}";
#    }
#    print CONF "\"\n";

#    print CONF "PDFSTREXT   = \"StrVec $nPdfStreams{'cmp'}";    # filename extension for each PdfStream
#    foreach $type (@cmp) {
#       print CONF " $type";
#    }
#    print CONF "\"\n";

#    print CONF "WINFN  = \"";
#    foreach $type (@cmp) {
#       print CONF "StrVec $nwin{$type} @{$win{$type}} ";        # window coefficients files for each PdfStream
#    }
#    print CONF "\"\n";
#    print CONF "WINDIR = $windir\n";                            # directory which stores window coefficients files

#    print CONF "MAXEMITER  = $maxEMiter\n";
#    print CONF "EMEPSILON  = $EMepsilon\n";
#    print CONF "USEGV      = $boolstring[$useHmmGV]\n";
#    print CONF "GVMODELMMF = $clsammf{'gv'}\n";
#    print CONF "GVHMMLIST  = $tiedlst{'gv'}\n";
#    print CONF "MAXGVITER  = $maxGViter\n";
#    print CONF "GVEPSILON  = $GVepsilon\n";
#    print CONF "MINEUCNORM = $minEucNorm\n";
#    print CONF "STEPINIT   = $stepInit\n";
#    print CONF "STEPINC    = $stepInc\n";
#    print CONF "STEPDEC    = $stepDec\n";
#    print CONF "HMMWEIGHT  = $hmmWeight\n";
#    print CONF "GVWEIGHT   = $gvWeight\n";
#    print CONF "OPTKIND    = $optKind\n";

#    if ( $nosilgv && @slnt > 0 ) {
#       $s = @slnt;
#       print CONF "GVOFFMODEL = \"StrVec $s";
#       for ( $s = 0 ; $s < @slnt ; $s++ ) {
#          print CONF " $slnt[$s]";
#       }
#       print CONF "\"\n";
#    }
#    print CONF "CDGV       = $boolstring[$cdgv]\n";

#    close(CONF);

#    # config file for alignend parameter generation
#    open( CONF, ">$cfg{'apg'}" ) || die "Cannot open $!";
#    print CONF "MODELALIGN = T\n";
#    close(CONF);
# }

# # sub routine for generating config file for DNN
# sub make_config_dnn {
#    my ( $nin, $nhid, $nout );
#    my @activations = qw(Linear Sigmoid Tanh ReLU);
#    my @optimizers  = qw(SGD Momentum AdaGrad AdaDelta Adam RMSprop);

#    $nin = `$PERL $datdir/scripts/makefeature.pl $qconf`;
#    chomp $nin;
#    $nhid = join ", ", ( split /\s+/, $nHiddenUnits );
#    $nout = 0;
#    foreach $type (@cmp) {
#       if ( $msdi{$type} != 0 ) {
#          $nout += 1;
#       }
#       $nout += $vSize{'cmp'}{$type};
#    }

#    open( CONF, ">$cfg{'tdn'}" ) || die "Cannot open $!";
#    print CONF "[Architecture]\n";
#    print CONF "num_input_units: $nin\n";
#    print CONF "num_hidden_units: [$nhid]\n";
#    print CONF "num_output_units: $nout\n";
#    print CONF "hidden_activation: \"$activations[$activation]\"\n";
#    print CONF "output_activation: \"$activations[0]\"\n";
#    print CONF "\n[Strategy]\n";
#    print CONF "optimizer: \"$optimizers[$optimizer]\"\n";
#    print CONF "learning_rate: $learnRate\n";
#    print CONF "keep_prob: $keepProb\n";
#    print CONF "queue_size: $queueSize\n";
#    print CONF "batch_size: $batchSize\n";
#    print CONF "num_epochs: $nEpoch\n";
#    print CONF "num_threads: $nThread\n";
#    print CONF "random_seed: $randomSeed\n";
#    print CONF "frame_by_frame: 1\n";
#    print CONF "adaptation: 0\n";
#    print CONF "\n[Output]\n";
#    print CONF "num_models_to_keep: $nKeep\n";
#    print CONF "log_interval: $logInterval\n";
#    print CONF "save_interval: $saveInterval\n";
#    print CONF "\n[Others]\n";
#    print CONF "all_spkrs: [\"$spkr\"]\n";
#    print CONF "num_feature_dimensions: [";

#    foreach $type (@cmp) {
#       print CONF "$ordr{$type}";
#       if ( $cmp[$#cmp] eq $type ) {
#          print CONF "]\n";
#       }
#       else {
#          print CONF ", ";
#       }
#    }
#    print CONF "restore_ckpt: -1\n";
#    close(CONF);

#    open( CONF, ">$cfg{'trj'}" ) || die "Cannot open $!";
#    print CONF "[Architecture]\n";
#    print CONF "num_input_units: $nin\n";
#    print CONF "num_hidden_units: [$nhid]\n";
#    print CONF "num_output_units: $nout\n";
#    print CONF "hidden_activation: \"$activations[$activation]\"\n";
#    print CONF "output_activation: \"$activations[0]\"\n";
#    print CONF "\n[Strategy]\n";
#    print CONF "optimizer: \"$optimizers[$optimizer]\"\n";
#    print CONF "learning_rate: $trjLearnRate\n";
#    print CONF "gv_weight: $dnnGVWeight\n";
#    print CONF "keep_prob: $keepProb\n";
#    print CONF "queue_size: $queueSize\n";
#    print CONF "batch_size: 1\n";
#    print CONF "num_epochs: $nTrjEpoch\n";
#    print CONF "num_threads: $nThread\n";
#    print CONF "random_seed: $randomSeed\n";
#    print CONF "frame_by_frame: 0\n";
#    print CONF "adaptation: 0\n";
#    print CONF "\n[Output]\n";
#    print CONF "num_models_to_keep: $nKeep\n";
#    print CONF "log_interval: $logInterval\n";
#    print CONF "save_interval: $saveInterval\n";
#    print CONF "\n[Others]\n";
#    print CONF "all_spkrs: [\"$spkr\"]\n";
#    print CONF "num_feature_dimensions: [";

#    foreach $type (@cmp) {
#       print CONF "$ordr{$type}";
#       if ( $cmp[$#cmp] eq $type ) {
#          print CONF "]\n";
#       }
#       else {
#          print CONF ", ";
#       }
#    }
#    print CONF "msd_flags: [";
#    foreach $type (@cmp) {
#       print CONF "$msdi{$type}";
#       if ( $cmp[$#cmp] eq $type ) {
#          print CONF "]\n";
#       }
#       else {
#          print CONF ", ";
#       }
#    }
#    print CONF "window_filenames: [\"";
#    foreach $type (@cmp) {
#       print CONF join "\", \"", @{ $win{$type} };
#       if ( $cmp[$#cmp] eq $type ) {
#          print CONF "\"]\n";
#       }
#       else {
#          print CONF "\", \"";
#       }
#    }
#    print CONF "restore_ckpt: 0\n";
#    close(CONF);

#    open( CONF, ">$cfg{'sdn'}" ) || die "Cannot open $!";
#    print CONF "[Architecture]\n";
#    print CONF "num_input_units: $nin\n";
#    print CONF "num_hidden_units: [$nhid]\n";
#    print CONF "num_output_units: $nout\n";
#    print CONF "hidden_activation: \"$activations[$activation]\"\n";
#    print CONF "output_activation: \"$activations[0]\"\n";
#    print CONF "\n[Strategy]\n";
#    print CONF "num_threads: $nThread\n";
#    print CONF "frame_by_frame: 1\n";
#    print CONF "\n[Others]\n";
#    print CONF "all_spkrs: [\"$spkr\"]\n";
#    print CONF "num_feature_dimensions: [";

#    foreach $type (@cmp) {
#       print CONF "$ordr{$type}";
#       if ( $cmp[$#cmp] eq $type ) {
#          print CONF "]\n";
#       }
#       else {
#          print CONF ", ";
#       }
#    }
#    print CONF "restore_ckpt: 0\n";
#    close(CONF);
# }

# # sub routine for generating .hed files for decision-tree clustering
# sub make_edfile_state($) {
#    my ($type) = @_;
#    my ( @lines, $i, @nstate );

#    $nstate{'cmp'} = $nState;
#    $nstate{'dur'} = 1;

#    open( QSFILE, "$qs{$type}" ) || die "Cannot open $!";
#    @lines = <QSFILE>;
#    close(QSFILE);

#    open( EDFILE, ">$cxc{$type}" ) || die "Cannot open $!";
#    print EDFILE "// load stats file\n";
#    print EDFILE "RO $gam{$type} \"$stats{$t2s{$type}}\"\n\n";
#    print EDFILE "TR 0\n\n";
#    print EDFILE "// questions for decision tree-based context clustering\n";
#    print EDFILE @lines;
#    print EDFILE "TR 3\n\n";
#    print EDFILE "// construct decision trees\n";

#    for ( $i = 2 ; $i <= $nstate{ $t2s{$type} } + 1 ; $i++ ) {
#       print EDFILE "TB $thr{$type} ${type}_s${i}_ {*.state[${i}].stream[$strb{$type}-$stre{$type}]}\n";
#    }
#    print EDFILE "\nTR 1\n\n";
#    print EDFILE "// output constructed trees\n";
#    print EDFILE "ST \"$tre{$type}\"\n";
#    close(EDFILE);
# }

# # sub routine for generating .hed files for decision-tree clustering of GV
# sub make_edfile_state_gv($$) {
#    my ( $type, $s ) = @_;
#    my (@lines);

#    open( QSFILE, "$qs_utt{$type}" ) || die "Cannot open $!";
#    @lines = <QSFILE>;
#    close(QSFILE);

#    open( EDFILE, ">$gvcxc{$type}" ) || die "Cannot open $!";
#    if ($cdgv) {
#       print EDFILE "// load stats file\n";
#       print EDFILE "RO $gvgam{$type} \"$stats{'gv'}\"\n";
#       print EDFILE "TR 0\n\n";
#       print EDFILE "// questions for decision tree-based context clustering\n";
#       print EDFILE @lines;
#       print EDFILE "TR 3\n\n";
#       print EDFILE "// construct decision trees\n";
#       print EDFILE "TB $gvthr{$type} gv_${type}_ {*.state[2].stream[$s]}\n";
#       print EDFILE "\nTR 1\n\n";
#       print EDFILE "// output constructed trees\n";
#       print EDFILE "ST \"$gvtre{$type}\"\n";
#    }
#    else {
#       open( TREE, ">$gvtre{$type}" ) || die "Cannot open $!";
#       print TREE " {*}[2].stream[$s]\n   \"gv_${type}_1\"\n";
#       close(TREE);
#       print EDFILE "// construct tying structure\n";
#       print EDFILE "TI gv_${type}_1 {*.state[2].stream[$s]}\n";
#    }
#    close(EDFILE);
# }

# # sub routine for untying structures
# sub make_edfile_untie($) {
#    my ($set) = @_;
#    my ( $type, $i, @nstate );

#    $nstate{'cmp'} = $nState;
#    $nstate{'dur'} = 1;

#    open( EDFILE, ">$unt{$set}" ) || die "Cannot open $!";

#    print EDFILE "// untie parameter sharing structure\n";
#    foreach $type ( @{ $ref{$set} } ) {
#       for ( $i = 2 ; $i <= $nstate{$set} + 1 ; $i++ ) {
#          if ( $#{ $ref{$set} } eq 0 ) {
#             print EDFILE "UT {*.state[$i]}\n";
#          }
#          else {
#             if ( $strw{$type} > 0.0 ) {
#                print EDFILE "UT {*.state[$i].stream[$strb{$type}-$stre{$type}]}\n";
#             }
#          }
#       }
#    }

#    close(EDFILE);
# }

# # sub routine to increase the number of mixture components
# sub make_edfile_upmix($) {
#    my ($set) = @_;
#    my ( $type, $i, @nstate );

#    $nstate{'cmp'} = $nState;
#    $nstate{'dur'} = 1;

#    open( EDFILE, ">$upm{$set}" ) || die "Cannot open $!";

#    print EDFILE "// increase the number of mixtures per stream\n";
#    foreach $type ( @{ $ref{$set} } ) {
#       for ( $i = 2 ; $i <= $nstate{$set} + 1 ; $i++ ) {
#          if ( $#{ $ref{$set} } eq 0 ) {
#             print EDFILE "MU +1 {*.state[$i].mix}\n";
#          }
#          else {
#             print EDFILE "MU +1 {*.state[$i].stream[$strb{$type}-$stre{$type}].mix}\n";
#          }
#       }
#    }

#    close(EDFILE);
# }

# # sub routine to convert statistics file for cmp into one for dur
# sub convstats {
#    my @LINE;

#    open( IN,  "$stats{'cmp'}" )  || die "Cannot open $!";
#    open( OUT, ">$stats{'dur'}" ) || die "Cannot open $!";
#    while (<IN>) {
#       @LINE = split(' ');
#       printf OUT ( "%4d %14s %4d %4d\n", $LINE[0], $LINE[1], $LINE[2], $LINE[2] );
#    }
#    close(IN);
#    close(OUT);
# }

# # sub routine for generating .hed files for mmf -> hts_engine conversion
# sub make_edfile_convert($) {
#    my ($type) = @_;

#    open( EDFILE, ">$cnv{$type}" ) || die "Cannot open $!";
#    print EDFILE "\nTR 2\n\n";
#    print EDFILE "// load trees for $type\n";
#    print EDFILE "LT \"$tre{$type}\"\n\n";

#    print EDFILE "// convert loaded trees for hts_engine format\n";
#    print EDFILE "CT \"$trd{$t2s{$type}}\"\n\n";

#    print EDFILE "// convert mmf for hts_engine format\n";
#    print EDFILE "CM \"$model{$t2s{$type}}\"\n";

#    close(EDFILE);
# }

# # sub routine for generating .hed files for GV mmf -> hts_engine conversion
# sub make_edfile_convert_gv($) {
#    my ($type) = @_;

#    open( EDFILE, ">$gvcnv{$type}" ) || die "Cannot open $!";
#    print EDFILE "\nTR 2\n\n";
#    print EDFILE "// load trees for $type\n";
#    print EDFILE "LT \"$gvtre{$type}\"\n\n";

#    print EDFILE "// convert loaded trees for hts_engine format\n";
#    print EDFILE "CT \"$gvdir\"\n\n";

#    print EDFILE "// convert mmf for hts_engine format\n";
#    print EDFILE "CM \"$gvdir\"\n";

#    close(EDFILE);
# }

# # sub routine for generating .hed files for making unseen models
# sub make_edfile_mkunseen($) {
#    my ($set) = @_;
#    my ($type);

#    open( EDFILE, ">$mku{$set}" ) || die "Cannot open $!";
#    print EDFILE "\nTR 2\n\n";
#    foreach $type ( @{ $ref{$set} } ) {
#       print EDFILE "// load trees for $type\n";
#       print EDFILE "LT \"$tre{$type}\"\n\n";
#    }

#    print EDFILE "// make unseen model\n";
#    print EDFILE "AU \"$lst{'all'}\"\n\n";
#    print EDFILE "// make model compact\n";
#    print EDFILE "CO \"$tiedlst{$set}\"\n\n";

#    close(EDFILE);
# }

# # sub routine for generating .hed files for making unseen models for GV
# sub make_edfile_mkunseen_gv {
#    my ($type);

#    open( EDFILE, ">$mku{'gv'}" ) || die "Cannot open $!";
#    print EDFILE "\nTR 2\n\n";
#    foreach $type (@cmp) {
#       print EDFILE "// load trees for $type\n";
#       print EDFILE "LT \"$gvtre{$type}\"\n\n";
#    }

#    print EDFILE "// make unseen model\n";
#    print EDFILE "AU \"$lst{'all'}\"\n\n";
#    print EDFILE "// make model compact\n";
#    print EDFILE "CO \"$tiedlst{'gv'}\"\n\n";

#    close(EDFILE);
# }

# # sub routine for generating low pass filter of hts_engine API
# sub make_lpf {
#    my ( $lfil, @coef, $coefSize, $i, $j );

#    $lfil     = `$PERL $datdir/scripts/makefilter.pl $sr 0`;
#    @coef     = split( '\s', $lfil );
#    $coefSize = @coef;

#    shell("rm -f $pdf{'lpf'}");
#    shell("touch $pdf{'lpf'}");
#    for ( $i = 0 ; $i < $nState ; $i++ ) {
#       shell("echo 1 | $X2X +ai >> $pdf{'lpf'}");
#    }
#    for ( $i = 0 ; $i < $nState ; $i++ ) {
#       for ( $j = 0 ; $j < $coefSize ; $j++ ) {
#          shell("echo $coef[$j] | $X2X +af >> $pdf{'lpf'}");
#       }
#       for ( $j = 0 ; $j < $coefSize ; $j++ ) {
#          shell("echo 0.0 | $X2X +af >> $pdf{'lpf'}");
#       }
#    }

#    open( INF, "> $trv{'lpf'}" );
#    for ( $i = 2 ; $i <= $nState + 1 ; $i++ ) {
#       print INF "{*}[${i}]\n";
#       print INF "   \"lpf_s${i}_1\"\n";
#    }
#    close(INF);

#    open( WIN, "> $voice/lpf.win1" );
#    print WIN "1 1.0\n";
#    close(WIN);
# }

# # sub routine for generating HTS voice for hts_engine API
# sub make_htsvoice($$) {
#    my ( $voicedir, $voicename ) = @_;
#    my ( $i, $type, $tmp, @coef, $coefSize, $file_index, $s, $e );

#    open( HTSVOICE, "> ${voicedir}/${voicename}.htsvoice" );

#    # global information
#    print HTSVOICE "[GLOBAL]\n";
#    print HTSVOICE "HTS_VOICE_VERSION:1.0\n";
#    print HTSVOICE "SAMPLING_FREQUENCY:${sr}\n";
#    print HTSVOICE "FRAME_PERIOD:${fs}\n";
#    print HTSVOICE "NUM_STATES:${nState}\n";
#    print HTSVOICE "NUM_STREAMS:" . ( ${ nPdfStreams { 'cmp' } } + 1 ) . "\n";
#    print HTSVOICE "STREAM_TYPE:";

#    for ( $i = 0 ; $i < @cmp ; $i++ ) {
#       if ( $i != 0 ) {
#          print HTSVOICE ",";
#       }
#       $tmp = get_stream_name( $cmp[$i] );
#       print HTSVOICE "${tmp}";
#    }
#    print HTSVOICE ",LPF\n";
#    print HTSVOICE "FULLCONTEXT_FORMAT:${fclf}\n";
#    print HTSVOICE "FULLCONTEXT_VERSION:${fclv}\n";
#    if ( $useHmmGV && $nosilgv && @slnt > 0 ) {
#       print HTSVOICE "GV_OFF_CONTEXT:";
#       for ( $i = 0 ; $i < @slnt ; $i++ ) {
#          if ( $i != 0 ) {
#             print HTSVOICE ",";
#          }
#          print HTSVOICE "\"*-${slnt[$i]}+*\"";
#       }
#    }
#    print HTSVOICE "\n";
#    print HTSVOICE "COMMENT:\n";

#    # stream information
#    print HTSVOICE "[STREAM]\n";
#    foreach $type (@cmp) {
#       $tmp = get_stream_name($type);
#       print HTSVOICE "VECTOR_LENGTH[${tmp}]:${ordr{$type}}\n";
#    }
#    $type     = "lpf";
#    $tmp      = get_stream_name($type);
#    @coef     = split( '\s', `$PERL $datdir/scripts/makefilter.pl $sr 0` );
#    $coefSize = @coef;
#    print HTSVOICE "VECTOR_LENGTH[${tmp}]:${coefSize}\n";
#    foreach $type (@cmp) {
#       $tmp = get_stream_name($type);
#       print HTSVOICE "IS_MSD[${tmp}]:${msdi{$type}}\n";
#    }
#    $type = "lpf";
#    $tmp  = get_stream_name($type);
#    print HTSVOICE "IS_MSD[${tmp}]:0\n";
#    foreach $type (@cmp) {
#       $tmp = get_stream_name($type);
#       print HTSVOICE "NUM_WINDOWS[${tmp}]:${nwin{$type}}\n";
#    }
#    $type = "lpf";
#    $tmp  = get_stream_name($type);
#    print HTSVOICE "NUM_WINDOWS[${tmp}]:1\n";
#    foreach $type (@cmp) {
#       $tmp = get_stream_name($type);
#       if ($useHmmGV) {
#          print HTSVOICE "USE_GV[${tmp}]:1\n";
#       }
#       else {
#          print HTSVOICE "USE_GV[${tmp}]:0\n";
#       }
#    }
#    $type = "lpf";
#    $tmp  = get_stream_name($type);
#    print HTSVOICE "USE_GV[${tmp}]:0\n";
#    foreach $type (@cmp) {
#       $tmp = get_stream_name($type);
#       if ( $tmp eq "MCP" ) {
#          print HTSVOICE "OPTION[${tmp}]:ALPHA=$fw\n";
#       }
#       elsif ( $tmp eq "LSP" ) {
#          print HTSVOICE "OPTION[${tmp}]:ALPHA=$fw,GAMMA=$gm,LN_GAIN=$lg\n";
#       }
#       else {
#          print HTSVOICE "OPTION[${tmp}]:\n";
#       }
#    }
#    $type = "lpf";
#    $tmp  = get_stream_name($type);
#    print HTSVOICE "OPTION[${tmp}]:\n";

#    # position
#    $file_index = 0;
#    print HTSVOICE "[POSITION]\n";
#    $file_size = get_file_size("${voicedir}/dur.pdf");
#    $s         = $file_index;
#    $e         = $file_index + $file_size - 1;
#    print HTSVOICE "DURATION_PDF:${s}-${e}\n";
#    $file_index += $file_size;
#    $file_size = get_file_size("${voicedir}/tree-dur.inf");
#    $s         = $file_index;
#    $e         = $file_index + $file_size - 1;
#    print HTSVOICE "DURATION_TREE:${s}-${e}\n";
#    $file_index += $file_size;

#    foreach $type (@cmp) {
#       $tmp = get_stream_name($type);
#       print HTSVOICE "STREAM_WIN[${tmp}]:";
#       for ( $i = 0 ; $i < $nwin{$type} ; $i++ ) {
#          $file_size = get_file_size("${voicedir}/$win{$type}[$i]");
#          $s         = $file_index;
#          $e         = $file_index + $file_size - 1;
#          if ( $i != 0 ) {
#             print HTSVOICE ",";
#          }
#          print HTSVOICE "${s}-${e}";
#          $file_index += $file_size;
#       }
#       print HTSVOICE "\n";
#    }
#    $type = "lpf";
#    $tmp  = get_stream_name($type);
#    print HTSVOICE "STREAM_WIN[${tmp}]:";
#    $file_size = get_file_size("$voicedir/$win{$type}[0]");
#    $s         = $file_index;
#    $e         = $file_index + $file_size - 1;
#    print HTSVOICE "${s}-${e}";
#    $file_index += $file_size;
#    print HTSVOICE "\n";

#    foreach $type (@cmp) {
#       $tmp       = get_stream_name($type);
#       $file_size = get_file_size("${voicedir}/${type}.pdf");
#       $s         = $file_index;
#       $e         = $file_index + $file_size - 1;
#       print HTSVOICE "STREAM_PDF[$tmp]:${s}-${e}\n";
#       $file_index += $file_size;
#    }
#    $type      = "lpf";
#    $tmp       = get_stream_name($type);
#    $file_size = get_file_size("${voicedir}/${type}.pdf");
#    $s         = $file_index;
#    $e         = $file_index + $file_size - 1;
#    print HTSVOICE "STREAM_PDF[$tmp]:${s}-${e}\n";
#    $file_index += $file_size;

#    foreach $type (@cmp) {
#       $tmp       = get_stream_name($type);
#       $file_size = get_file_size("${voicedir}/tree-${type}.inf");
#       $s         = $file_index;
#       $e         = $file_index + $file_size - 1;
#       print HTSVOICE "STREAM_TREE[$tmp]:${s}-${e}\n";
#       $file_index += $file_size;
#    }
#    $type      = "lpf";
#    $tmp       = get_stream_name($type);
#    $file_size = get_file_size("${voicedir}/tree-${type}.inf");
#    $s         = $file_index;
#    $e         = $file_index + $file_size - 1;
#    print HTSVOICE "STREAM_TREE[$tmp]:${s}-${e}\n";
#    $file_index += $file_size;

#    if ($useHmmGV) {
#       foreach $type (@cmp) {
#          $tmp       = get_stream_name($type);
#          $file_size = get_file_size("${voicedir}/gv-${type}.pdf");
#          $s         = $file_index;
#          $e         = $file_index + $file_size - 1;
#          print HTSVOICE "GV_PDF[$tmp]:${s}-${e}\n";
#          $file_index += $file_size;
#       }
#    }
#    if ( $useHmmGV && $cdgv ) {
#       foreach $type (@cmp) {
#          $tmp       = get_stream_name($type);
#          $file_size = get_file_size("${voicedir}/tree-gv-${type}.inf");
#          $s         = $file_index;
#          $e         = $file_index + $file_size - 1;
#          print HTSVOICE "GV_TREE[$tmp]:${s}-${e}\n";
#          $file_index += $file_size;
#       }
#    }

#    # data information
#    print HTSVOICE "[DATA]\n";
#    open( I, "${voicedir}/dur.pdf" ) || die "Cannot open $!";
#    @STAT = stat(I);
#    read( I, $DATA, $STAT[7] );
#    close(I);
#    print HTSVOICE $DATA;
#    open( I, "${voicedir}/tree-dur.inf" ) || die "Cannot open $!";
#    @STAT = stat(I);
#    read( I, $DATA, $STAT[7] );
#    close(I);
#    print HTSVOICE $DATA;

#    foreach $type (@cmp) {
#       $tmp = get_stream_name($type);
#       for ( $i = 0 ; $i < $nwin{$type} ; $i++ ) {
#          open( I, "${voicedir}/$win{$type}[$i]" ) || die "Cannot open $!";
#          @STAT = stat(I);
#          read( I, $DATA, $STAT[7] );
#          close(I);
#          print HTSVOICE $DATA;
#       }
#    }
#    $type = "lpf";
#    $tmp  = get_stream_name($type);
#    open( I, "${voicedir}/$win{$type}[0]" ) || die "Cannot open $!";
#    @STAT = stat(I);
#    read( I, $DATA, $STAT[7] );
#    close(I);
#    print HTSVOICE $DATA;

#    foreach $type (@cmp) {
#       $tmp = get_stream_name($type);
#       open( I, "${voicedir}/${type}.pdf" ) || die "Cannot open $!";
#       @STAT = stat(I);
#       read( I, $DATA, $STAT[7] );
#       close(I);
#       print HTSVOICE $DATA;
#    }
#    $type = "lpf";
#    $tmp  = get_stream_name($type);
#    open( I, "${voicedir}/${type}.pdf" ) || die "Cannot open $!";
#    @STAT = stat(I);
#    read( I, $DATA, $STAT[7] );
#    close(I);
#    print HTSVOICE $DATA;

#    foreach $type (@cmp) {
#       $tmp = get_stream_name($type);
#       open( I, "${voicedir}/tree-${type}.inf" ) || die "Cannot open $!";
#       @STAT = stat(I);
#       read( I, $DATA, $STAT[7] );
#       close(I);
#       print HTSVOICE $DATA;
#    }
#    $type = "lpf";
#    $tmp  = get_stream_name($type);
#    open( I, "${voicedir}/tree-${type}.inf" ) || die "Cannot open $!";
#    @STAT = stat(I);
#    read( I, $DATA, $STAT[7] );
#    close(I);
#    print HTSVOICE $DATA;

#    if ($useHmmGV) {
#       foreach $type (@cmp) {
#          $tmp = get_stream_name($type);
#          open( I, "${voicedir}/gv-${type}.pdf" ) || die "Cannot open $!";
#          @STAT = stat(I);
#          read( I, $DATA, $STAT[7] );
#          close(I);
#          print HTSVOICE $DATA;
#       }
#    }
#    if ( $useHmmGV && $cdgv ) {
#       foreach $type (@cmp) {
#          $tmp = get_stream_name($type);
#          open( I, "${voicedir}/tree-gv-${type}.inf" ) || die "Cannot open $!";
#          @STAT = stat(I);
#          read( I, $DATA, $STAT[7] );
#          close(I);
#          print HTSVOICE $DATA;
#       }
#    }
#    close(HTSVOICE);
# }

# # sub routine for getting stream name for HTS voice
# sub get_stream_name($) {
#    my ($from) = @_;
#    my ($to);

#    if ( $from eq 'mgc' ) {
#       if ( $gm == 0 ) {
#          $to = "MCP";
#       }
#       else {
#          $to = "LSP";
#       }
#    }
#    else {
#       $to = uc $from;
#    }

#    return $to;
# }

# # sub routine for getting file size
# sub get_file_size($) {
#    my ($file) = @_;
#    my ($file_size);

#    $file_size = `$WC -c < $file`;
#    chomp($file_size);

#    return $file_size;
# }

# # sub routine for formant emphasis in Mel-cepstral domain
# sub postfiltering_mcp($$) {
#    my ( $base, $gendir ) = @_;
#    my ( $i, $line );

#    # output postfiltering weight coefficient
#    $line = "echo 1 1 ";
#    for ( $i = 2 ; $i < $ordr{'mgc'} ; $i++ ) {
#       $line .= "$pf_mcp ";
#    }
#    $line .= "| $X2X +af > $gendir/weight";
#    shell($line);

#    # calculate auto-correlation of original mcep
#    $line = "$FREQT -m " . ( $ordr{'mgc'} - 1 ) . " -a $fw -M $co -A 0 < $gendir/${base}.mgc | ";
#    $line .= "$C2ACR -m $co -M 0 -l $fl > $gendir/${base}.r0";
#    shell($line);

#    # calculate auto-correlation of postfiltered mcep
#    $line = "$VOPR -m -n " . ( $ordr{'mgc'} - 1 ) . " < $gendir/${base}.mgc $gendir/weight | ";
#    $line .= "$FREQT -m " . ( $ordr{'mgc'} - 1 ) . " -a $fw -M $co -A 0 | ";
#    $line .= "$C2ACR -m $co -M 0 -l $fl > $gendir/${base}.p_r0";
#    shell($line);

#    # calculate MLSA coefficients from postfiltered mcep
#    $line = "$VOPR -m -n " . ( $ordr{'mgc'} - 1 ) . " < $gendir/${base}.mgc $gendir/weight | ";
#    $line .= "$MC2B -m " . ( $ordr{'mgc'} - 1 ) . " -a $fw | ";
#    $line .= "$BCP -n " .  ( $ordr{'mgc'} - 1 ) . " -s 0 -e 0 > $gendir/${base}.b0";
#    shell($line);

#    # calculate 0.5 * log(acr_orig/acr_post)) and add it to 0th MLSA coefficient
#    $line = "$VOPR -d < $gendir/${base}.r0 $gendir/${base}.p_r0 | ";
#    $line .= "$SOPR -LN -d 2 | ";
#    $line .= "$VOPR -a $gendir/${base}.b0 > $gendir/${base}.p_b0";
#    shell($line);

#    # generate postfiltered mcep
#    $line = "$VOPR -m -n " . ( $ordr{'mgc'} - 1 ) . " < $gendir/${base}.mgc $gendir/weight | ";
#    $line .= "$MC2B -m " .  ( $ordr{'mgc'} - 1 ) . " -a $fw | ";
#    $line .= "$BCP -n " .   ( $ordr{'mgc'} - 1 ) . " -s 1 -e " . ( $ordr{'mgc'} - 1 ) . " | ";
#    $line .= "$MERGE -n " . ( $ordr{'mgc'} - 2 ) . " -s 0 -N 0 $gendir/${base}.p_b0 | ";
#    $line .= "$B2MC -m " .  ( $ordr{'mgc'} - 1 ) . " -a $fw > $gendir/${base}.p_mgc";
#    shell($line);

#    $line = "rm -f $gendir/weight $gendir/${base}.r0 $gendir/${base}.p_r0 $gendir/${base}.b0 $gendir/${base}.p_b0";
#    shell($line);
# }

# # sub routine for formant emphasis in LSP domain
# sub postfiltering_lsp($$) {
#    my ( $base, $gendir ) = @_;
#    my ( $file, $lgopt, $line, $i, @lsp, $d_1, $d_2, $plsp, $data );

#    $file = "$gendir/${base}.mgc";
#    if ($lg) {
#       $lgopt = "-L";
#    }
#    else {
#       $lgopt = "";
#    }

#    $line = "$LSPCHECK -m " . ( $ordr{'mgc'} - 1 ) . " -s " . ( $sr / 1000 ) . " $lgopt -c -r 0.1 -g -G 1.0E-10 $file | ";
#    $line .= "$LSP2LPC -m " . ( $ordr{'mgc'} - 1 ) . " -s " .                     ( $sr / 1000 ) . " $lgopt | ";
#    $line .= "$MGC2MGC -m " . ( $ordr{'mgc'} - 1 ) . " -a $fw -c $gm -n -u -M " . ( $fl - 1 ) . " -A 0.0 -G 1.0 | ";
#    $line .= "$SOPR -P | $VSUM -t $fl | $SOPR -LN -m 0.5 > $gendir/${base}.ene1";
#    shell($line);

#    # postfiltering
#    open( LSP,  "$X2X +fa < $gendir/${base}.mgc |" );
#    open( GAIN, ">$gendir/${base}.gain" );
#    open( PLSP, ">$gendir/${base}.lsp" );
#    while (1) {
#       @lsp = ();
#       for ( $i = 0 ; $i < $ordr{'mgc'} && ( $line = <LSP> ) ; $i++ ) {
#          push( @lsp, $line );
#       }
#       if ( $ordr{'mgc'} != @lsp ) { last; }

#       $data = pack( "f", $lsp[0] );
#       print GAIN $data;
#       for ( $i = 1 ; $i < $ordr{'mgc'} ; $i++ ) {
#          if ( $i > 1 && $i < $ordr{'mgc'} - 1 ) {
#             $d_1 = $pf_lsp * ( $lsp[ $i + 1 ] - $lsp[$i] );
#             $d_2 = $pf_lsp * ( $lsp[$i] - $lsp[ $i - 1 ] );
#             $plsp = $lsp[ $i - 1 ] + $d_2 + ( $d_2 * $d_2 * ( ( $lsp[ $i + 1 ] - $lsp[ $i - 1 ] ) - ( $d_1 + $d_2 ) ) ) / ( ( $d_2 * $d_2 ) + ( $d_1 * $d_1 ) );
#          }
#          else {
#             $plsp = $lsp[$i];
#          }
#          $data = pack( "f", $plsp );
#          print PLSP $data;
#       }
#    }
#    close(PLSP);
#    close(GAIN);
#    close(LSP);

#    $line = "$MERGE -s 1 -l 1 -L " . ( $ordr{'mgc'} - 1 ) . " -N " . ( $ordr{'mgc'} - 2 ) . " $gendir/${base}.lsp < $gendir/${base}.gain | ";
#    $line .= "$LSPCHECK -m " . ( $ordr{'mgc'} - 1 ) . " -s " .                     ( $sr / 1000 ) . " $lgopt -c -r 0.1 -g -G 1.0E-10 | ";
#    $line .= "$LSP2LPC -m " .  ( $ordr{'mgc'} - 1 ) . " -s " .                     ( $sr / 1000 ) . " $lgopt | ";
#    $line .= "$MGC2MGC -m " .  ( $ordr{'mgc'} - 1 ) . " -a $fw -c $gm -n -u -M " . ( $fl - 1 ) . " -A 0.0 -G 1.0 | ";
#    $line .= "$SOPR -P | $VSUM -t $fl | $SOPR -LN -m 0.5 > $gendir/${base}.ene2 ";
#    shell($line);

#    $line = "$VOPR -l 1 -d $gendir/${base}.ene2 $gendir/${base}.ene2 | $SOPR -LN -m 0.5 | ";
#    $line .= "$VOPR -a $gendir/${base}.gain | ";
#    $line .= "$MERGE -s 1 -l 1 -L " . ( $ordr{'mgc'} - 1 ) . " -N " . ( $ordr{'mgc'} - 2 ) . " $gendir/${base}.lsp > $gendir/${base}.p_mgc";
#    shell($line);

#    $line = "rm -f $gendir/${base}.ene1 $gendir/${base}.ene2 $gendir/${base}.gain $gendir/${base}.lsp";
#    shell($line);
# }

# # sub routine for generating parameter sequences using MLPG and neural network outputs
# sub gen_param($) {
#    my ($gendir) = @_;
#    my ( $line, @FILE, $file, $base, $T, $s, $e, $t );

#    my $ffosize = 0;
#    foreach $type (@cmp) {
#       if ( $msdi{$type} != 0 ) {
#          $ffosize += 1;
#       }
#       $ffosize += $vSize{'cmp'}{$type};
#    }

#    $line = `ls $gendir/*.ffo`;
#    @FILE = split( '\n', $line );
#    print "Processing directory $gendir:\n";
#    foreach $file (@FILE) {
#       $base = `basename $file .ffo`;
#       chomp($base);

#       print " Generating parameter sequences from $base.ffo...";
#       $T = get_file_size("$gendir/${base}.ffo") / $ffosize / 4;
#       $s = 0;
#       $e = -1;
#       foreach my $type (@cmp) {
#          if ( $msdi{$type} != 0 ) {
#             $s = $e + 1;
#             $e = $s;
#             shell("$BCP +f -s $s -e $e -l $ffosize $file | $SOPR -s 0.5 -UNIT | $INTERPOLATE -l 1 -p $ordr{$type} -d > $gendir/$base.$type.msd1");
#             shell("$SOPR -s 1.0 -m 1.0E+10 < $gendir/$base.$type.msd1 > $gendir/$base.$type.msd2");
#          }
#          $s = $e + 1;
#          $e = $s + $vSize{'cmp'}{$type} - 1;
#          shell("$BCP +f -s $s -e $e -l $ffosize $file > $gendir/$base.$type.mean");
#          shell("rm -f $gendir/$base.$type.var");
#          for ( $t = 0 ; $t < $T ; $t++ ) {
#             shell("$BCUT +f -s $s -e $e $gendir/$base.var >> $gendir/$base.$type.var");
#          }
#          my $opt = "";
#          for ( my $d = 1 ; $d < $nwin{$type} ; $d++ ) {
#             shell("$X2X +af < $windir/$win{$type}[$d] | $BCUT -l 1 -s 1 +f > $gendir/$base.$type.win$d");
#             $opt .= " -d $gendir/$base.$type.win$d ";
#          }
#          $line = "$MERGE -l $vSize{'cmp'}{$type} -L $vSize{'cmp'}{$type} $gendir/$base.$type.mean < $gendir/$base.$type.var | ";
#          $line .= "$MLPG -l $ordr{$type} $opt ";
#          if ( $msdi{$type} != 0 ) {
#             $line .= " | $VOPR -l 1 -m $gendir/$base.$type.msd1 ";
#             $line .= " | $VOPR -l 1 -a $gendir/$base.$type.msd2 ";
#          }
#          $line .= "> $gendir/$base.$type";
#          shell($line);
#          shell("rm -f $gendir/$base.$type.mean $gendir/$base.$type.var $gendir/$base.$type.win* $gendir/$base.$type.msd*");
#       }

#       print "done\n";
#    }
# }

# # sub routine for speech synthesis from log f0 and Mel-cepstral coefficients
# sub gen_wave($$) {
#    my ( $gendir, $pf ) = @_;
#    my ( $line, @FILE, $lgopt, $file, $base, $T, $mgc, $lf0, $bap );

#    $line = `ls $gendir/*.mgc`;
#    @FILE = split( '\n', $line );
#    if ($lg) {
#       $lgopt = "-L";
#    }
#    else {
#       $lgopt = "";
#    }

#    print "Processing directory $gendir:\n";
#    foreach $file (@FILE) {
#       $base = `basename $file .mgc`;
#       chomp($base);

#       if ( $gm == 0 ) {

#          # apply postfiltering
#          if ( $pf == 2 ) {
#             postfiltering_mspf( $base, $gendir, 'mgc' );
#             $mgc = "$gendir/$base.p_mgc";
#          }
#          elsif ( $pf == 1 && $pf_mcp != 1.0 ) {
#             postfiltering_mcp( $base, $gendir );
#             $mgc = "$gendir/$base.p_mgc";
#          }
#          else {
#             $mgc = $file;
#          }
#       }
#       else {

#          # apply postfiltering
#          if ( $pf == 2 ) {
#             postfiltering_mspf( $base, $gendir, 'mgc' );
#             $mgc = "$gendir/$base.p_mgc";
#          }
#          elsif ( $pf == 1 && $pf_lsp != 1.0 ) {
#             postfiltering_lsp( $base, $gendir );
#             $mgc = "$gendir/$base.p_mgc";
#          }
#          else {
#             $mgc = $file;
#          }

#          # MGC-LSPs -> MGC coefficients
#          $line = "$LSPCHECK -m " . ( $ordr{'mgc'} - 1 ) . " -s " . ( $sr / 1000 ) . " $lgopt -c -r 0.1 -g -G 1.0E-10 $mgc | ";
#          $line .= "$LSP2LPC -m " . ( $ordr{'mgc'} - 1 ) . " -s " . ( $sr / 1000 ) . " $lgopt | ";
#          $line .= "$MGC2MGC -m " . ( $ordr{'mgc'} - 1 ) . " -a $fw -c $gm -n -u -M " . ( $ordr{'mgc'} - 1 ) . " -A $fw -C $gm " . " > $gendir/$base.c_mgc";
#          shell($line);

#          $mgc = "$gendir/$base.c_mgc";
#       }

#       $lf0 = "$gendir/$base.lf0";
#       $bap = "$gendir/$base.bap";

#       if ( !$usestraight && -s $file && -s $lf0 ) {
#          print " Synthesizing a speech waveform from $base.mgc and $base.lf0...";

#          # convert log F0 to pitch
#          $line = "$SOPR -magic -1.0E+10 -EXP -INV -m $sr -MAGIC 0.0 $lf0 > $gendir/${base}.pit";
#          shell($line);

#          # synthesize waveform
#          $lfil = `$PERL $datdir/scripts/makefilter.pl $sr 0`;
#          $hfil = `$PERL $datdir/scripts/makefilter.pl $sr 1`;
#          $line = "$SOPR -m 0 $gendir/$base.pit | $EXCITE -n -p $fs | $DFS -b $hfil > $gendir/$base.unv";
#          shell($line);

#          $line = "$EXCITE -n -p $fs $gendir/$base.pit | ";
#          $line .= "$DFS -b $lfil | $VOPR -a $gendir/$base.unv | ";
#          $line .= "$MGLSADF -P 7 -m " . ( $ordr{'mgc'} - 1 ) . " -p $fs -a $fw -c $gm $mgc | ";
#          $line .= "$X2X +fs -o > $gendir/$base.raw";
#          shell($line);

#          $line = "$RAW2WAV -s " . ( $sr / 1000 ) . " -d $gendir $gendir/$base.raw";
#          shell($line);

#          $line = "rm -f $gendir/$base.unv";
#          shell($line);

#          print "done\n";
#       }
#       elsif ( $usestraight && -s $file && -s $lf0 && -s $bap ) {
#          print " Synthesizing a speech waveform from $base.mgc, $base.lf0, and $base.bap... ";

#          # convert log F0 to F0
#          $line = "$SOPR -magic -1.0E+10 -EXP -MAGIC 0.0 $lf0 > $gendir/${base}.f0 ";
#          shell($line);
#          $T = get_file_size("$gendir/${base}.f0") / 4;

#          # convert Mel-cepstral coefficients to spectrum
#          if ( $gm == 0 ) {
#             shell( "$MGC2SP -a $fw -g $gm -m " . ( $ordr{'mgc'} - 1 ) . " -l $ft -o 2 $mgc > $gendir/$base.sp" );
#          }
#          else {
#             shell( "$MGC2SP -a $fw -c $gm -m " . ( $ordr{'mgc'} - 1 ) . " -l $ft -o 2 $mgc > $gendir/$base.sp" );
#          }

#          # convert band-aperiodicity to aperiodicity
#          shell( "$MGC2SP -a $fw -g 0 -m " . ( $ordr{'bap'} - 1 ) . " -l $ft -o 0 $bap > $gendir/$base.ap" );

#          # synthesize waveform
#          open( SYN, ">$gendir/${base}.m" ) || die "Cannot open $!";
#          printf SYN "path(path,'%s');\n",                 ${STRAIGHT};
#          printf SYN "prm.spectralUpdateInterval = %f;\n", 1000.0 * $fs / $sr;
#          printf SYN "prm.levelNormalizationIndicator = 0;\n\n";
#          printf SYN "fprintf(1,'\\nSynthesizing %s\\n');\n", "$gendir/$base.wav";
#          printf SYN "fid1 = fopen('%s','r','%s');\n",        "$gendir/$base.sp", "ieee-le";
#          printf SYN "fid2 = fopen('%s','r','%s');\n",        "$gendir/$base.ap", "ieee-le";
#          printf SYN "fid3 = fopen('%s','r','%s');\n",        "$gendir/$base.f0", "ieee-le";
#          printf SYN "sp = fread(fid1,[%d, %d],'float');\n", ( $ft / 2 + 1 ), $T;
#          printf SYN "ap = fread(fid2,[%d, %d],'float');\n", ( $ft / 2 + 1 ), $T;
#          printf SYN "f0 = fread(fid3,[%d, %d],'float');\n", 1, $T;
#          printf SYN "fclose(fid1);\n";
#          printf SYN "fclose(fid2);\n";
#          printf SYN "fclose(fid3);\n";
#          printf SYN "sp = sp/32768.0;\n";
#          printf SYN "[sy] = exstraightsynth(f0,sp,ap,%d,prm);\n", $sr;
#          printf SYN "wavwrite(sy,%d,'%s');\n\n", $sr, "$gendir/$base.wav";
#          printf SYN "quit;\n";
#          close(SYN);
#          shell("$MATLAB < $gendir/${base}.m");

#          $line = "rm -f $gendir/$base.m";
#          shell($line);

#          print "done\n";
#       }
#    }
# }

# # sub routine for modulation spectrum-based postfilter
# sub postfiltering_mspf($$$) {
#    my ( $base, $gendir, $type ) = @_;
#    my ( $gentype, $T, $line, $d, @seq );

#    $gentype = $gendir;
#    $gentype =~ s/$prjdir\/gen\/ver$ver\/+/gen\//g;
#    $T = get_file_size("$gendir/$base.$type") / $ordr{$type} / 4;

#    # subtract utterance-level mean
#    $line = get_cmd_utmean( "$gendir/$base.$type", $type );
#    shell("$line > $gendir/$base.$type.mean");
#    $line = get_cmd_vopr( "$gendir/$base.$type", "-s", "$gendir/$base.$type.mean", $type );
#    shell("$line > $gendir/$base.$type.subtracted");

#    for ( $d = 0 ; $d < $ordr{$type} ; $d++ ) {

#       # calculate modulation spectrum/phase
#       $line = get_cmd_seq2ms( "$gendir/$base.$type.subtracted", $type, $d );
#       shell("$line > $gendir/$base.$type.mspec_dim$d");
#       $line = get_cmd_seq2mp( "$gendir/$base.$type.subtracted", $type, $d );
#       shell("$line > $gendir/$base.$type.mphase_dim$d");

#       # convert
#       $line = "cat $gendir/$base.$type.mspec_dim$d | ";
#       $line .= "$VOPR -l " . ( $mspfFFTLen / 2 + 1 ) . " -s $mspfmean{$type}{$gentype}[$d] | ";
#       $line .= "$VOPR -l " . ( $mspfFFTLen / 2 + 1 ) . " -d $mspfstdd{$type}{$gentype}[$d] | ";
#       $line .= "$VOPR -l " . ( $mspfFFTLen / 2 + 1 ) . " -m $mspfstdd{$type}{'nat'}[$d] | ";
#       $line .= "$VOPR -l " . ( $mspfFFTLen / 2 + 1 ) . " -a $mspfmean{$type}{'nat'}[$d] | ";

#       # apply weight
#       $line .= "$VOPR -l " . ( $mspfFFTLen / 2 + 1 ) . " -s $gendir/$base.$type.mspec_dim$d | ";
#       $line .= "$SOPR -m $mspfe{$type} | ";
#       $line .= "$VOPR -l " . ( $mspfFFTLen / 2 + 1 ) . " -a $gendir/$base.$type.mspec_dim$d > $gendir/$base.p_$type.mspec_dim$d";
#       shell($line);

#       # calculate filtered sequence
#       push( @seq, msmp2seq( "$gendir/$base.p_$type.mspec_dim$d", "$gendir/$base.$type.mphase_dim$d", $T ) );
#    }
#    open( SEQ, ">$gendir/$base.$type.tmp" ) || die "Cannot open $!";
#    print SEQ join( "\n", @seq );
#    close(SEQ);
#    shell("$X2X +af $gendir/$base.$type.tmp | $TRANSPOSE -m $ordr{$type} -n $T > $gendir/$base.p_$type.subtracted");

#    # add utterance-level mean
#    $line = get_cmd_vopr( "$gendir/$base.p_$type.subtracted", "-a", "$gendir/$base.$type.mean", $type );
#    shell("$line > $gendir/$base.p_$type");

#    # remove temporal files
#    shell("rm -f $gendir/$base.$type.mspec_dim* $gendir/$base.$type.mphase_dim* $gendir/$base.p_$type.mspec_dim*");
#    shell("rm -f $gendir/$base.$type.subtracted $gendir/$base.p_$type.subtracted $gendir/$base.$type.mean $gendir/$base.$type.tmp");
# }

# # sub routine for calculating temporal sequence from modulation spectrum/phase
# sub msmp2seq($$$) {
#    my ( $file_ms, $file_mp, $T ) = @_;
#    my ( @msp, @seq, @wseq, @ms, @mp, $d, $pos, $bias, $mspfShift );

#    @ms = split( /\n/, `$SOPR -EXP  $file_ms | $X2X +fa` );
#    @mp = split( /\n/, `$SOPR -m pi $file_mp | $X2X +fa` );
#    $mspfShift = ( $mspfLength - 1 ) / 2;

#    # ifft (modulation spectrum & modulation phase -> temporal sequence)
#    for ( $pos = 0, $bias = 0 ; $pos <= $#ms ; $pos += $mspfFFTLen / 2 + 1 ) {
#       for ( $d = 0 ; $d <= $mspfFFTLen / 2 ; $d++ ) {
#          $msp[ $d + $bias ] = $ms[ $d + $pos ] * cos( $mp[ $d + $pos ] );
#          $msp[ $d + $mspfFFTLen + $bias ] = $ms[ $d + $pos ] * sin( $mp[ $d + $pos ] );
#          if ( $d != 0 && $d != $mspfFFTLen / 2 ) {
#             $msp[ $mspfFFTLen - $d + $bias ] = $msp[ $d + $bias ];
#             $msp[ 2 * $mspfFFTLen - $d + $bias ] = -$msp[ $d + $mspfFFTLen + $bias ];
#          }
#       }
#       $bias += 2 * $mspfFFTLen;
#    }
#    open( MSP, ">$file_ms.tmp" ) || die "Cannot open $!";
#    print MSP join( "\n", @msp );
#    close(MSP);
#    @wseq = split( "\n", `$X2X +af $file_ms.tmp | $IFFTR -l $mspfFFTLen | $X2X +fa` );
#    shell("rm -f $file_ms.tmp");

#    # overlap-addition
#    for ( $pos = 0, $bias = 0 ; $pos <= $#wseq ; $pos += $mspfFFTLen ) {
#       for ( $d = 0 ; $d < $mspfFFTLen ; $d++ ) {
#          $seq[ $d + $bias ] += $wseq[ $d + $pos ];
#       }
#       $bias += $mspfShift;
#    }

#    return @seq[ $mspfShift .. ( $T + $mspfShift - 1 ) ];
# }

# # sub routine for shell command to get utterance mean
# sub get_cmd_utmean($$) {
#    my ( $file, $type ) = @_;

#    return "$VSTAT -l $ordr{$type} -o 1 < $file ";
# }

# # sub routine for shell command to subtract vector from sequence
# sub get_cmd_vopr($$$$) {
#    my ( $file, $opt, $vec, $type ) = @_;
#    my ( $value, $line );

#    if ( $ordr{$type} == 1 ) {
#       $value = `$X2X +fa < $vec`;
#       chomp($value);
#       $line = "$SOPR $opt $value < $file ";
#    }
#    else {
#       $line = "$VOPR -l $ordr{$type} $opt $vec < $file ";
#    }
#    return $line;
# }

# # sub routine for shell command to calculate modulation spectrum from sequence
# sub get_cmd_seq2ms($$$) {
#    my ( $file, $type, $d ) = @_;
#    my ( $T, $line, $mspfShift );

#    $T         = get_file_size("$file") / $ordr{$type} / 4;
#    $mspfShift = ( $mspfLength - 1 ) / 2;

#    $line = "$BCP -l $ordr{$type} -L 1 -s $d -e $d < $file | ";
#    $line .= "$WINDOW -l $T -L " . ( $T + $mspfShift ) . " -n 0 -w 5 | ";
#    $line .= "$FRAME -l $mspfLength -p $mspfShift | ";
#    $line .= "$WINDOW -l $mspfLength -L $mspfFFTLen -n 0 -w 3 | ";
#    $line .= "$SPEC -l $mspfFFTLen -o 1 -e 1e-30 ";

#    return $line;
# }

# # sub routine for shell command to calculate modulation phase from sequence
# sub get_cmd_seq2mp($$$) {
#    my ( $file, $type, $d ) = @_;
#    my ( $T, $line, $mspfShift );

#    $T         = get_file_size("$file") / $ordr{$type} / 4;
#    $mspfShift = ( $mspfLength - 1 ) / 2;

#    $line = "$BCP -l $ordr{$type} -L 1 -s $d -e $d < $file | ";
#    $line .= "$WINDOW -l $T -L " . ( $T + $mspfShift ) . " -n 0 -w 5 | ";
#    $line .= "$FRAME -l $mspfLength -p $mspfShift | ";
#    $line .= "$WINDOW -l $mspfLength -L $mspfFFTLen -n 0 -w 3 | ";
#    $line .= "$PHASE -l $mspfFFTLen -u ";

#    return $line;
# }

# # sub routine for making force-aligned label files
# sub make_full_fal {
#    my ( $line, $base, $istr, $lstr, @iarr, @larr );

#    open( ISCP, "$scp{'trn'}" )   || die "Cannot open $!";
#    open( OSCP, ">$scp{'mspf'}" ) || die "Cannot open $!";

#    while (<ISCP>) {
#       $line = $_;
#       chomp($line);
#       $base = `basename $line .cmp`;
#       chomp($base);

#       open( LAB,  "$datdir/labels/full/$base.lab" ) || die "Cannot open $!";
#       open( IFAL, "$gvfaldir{'phn'}/$base.lab" )    || die "Cannot open $!";
#       open( OFAL, ">$mspffaldir/$base.lab" )        || die "Cannot open $!";

#       while ( ( $istr = <IFAL> ) && ( $lstr = <LAB> ) ) {
#          chomp($istr);
#          chomp($lstr);
#          @iarr = split( / /, $istr );
#          @larr = split( / /, $lstr );
#          print OFAL "$iarr[0] $iarr[1] $larr[$#larr]\n";
#       }

#       close(LAB);
#       close(IFAL);
#       close(OFAL);
#       print OSCP "$mspffaldir/$base.lab\n";
#    }

#    close(ISCP);
#    close(OSCP);
# }

# # sub routine for calculating statistics of modulation spectrum
# sub make_mspf($) {
#    my ($gentype) = @_;
#    my ( $cmp, $base, $type, $mspftype, $orgdir, $line, $d );
#    my ( $str, @arr, $start, $end, $find, $j );

#    # reset modulation spectrum files
#    foreach $type ('mgc') {
#       foreach $mspftype ( 'nat', $gentype ) {
#          for ( $d = 0 ; $d < $ordr{$type} ; $d++ ) {
#             shell("rm -f $mspfstatsdir{$mspftype}/${type}_dim$d.data");
#             shell("touch $mspfstatsdir{$mspftype}/${type}_dim$d.data");
#          }
#       }
#    }

#    # calculate modulation spectrum from natural/generated sequences
#    open( SCP, "$scp{'trn'}" ) || die "Cannot open $!";
#    while (<SCP>) {
#       $cmp = $_;
#       chomp($cmp);
#       $base = `basename $cmp .cmp`;
#       chomp($base);
#       print " Making data from $base.lab for modulation spectrum...";

#       foreach $type ('mgc') {
#          foreach $mspftype ( 'nat', $gentype ) {

#             # determine original feature directory
#             if   ( $mspftype eq 'nat' ) { $orgdir = "$datdir/$type"; }
#             else                        { $orgdir = "$mspfdir/$mspftype"; }

#             # subtract utterance-level mean
#             $line = get_cmd_utmean( "$orgdir/$base.$type", $type );
#             shell("$line > $mspfdatdir{$mspftype}/$base.$type.mean");
#             $line = get_cmd_vopr( "$orgdir/$base.$type", "-s", "$mspfdatdir{$mspftype}/$base.$type.mean", $type );
#             shell("$line > $mspfdatdir{$mspftype}/$base.$type.subtracted");

#             # extract non-silence frames
#             if ( @slnt > 0 ) {
#                shell("rm -f $mspfdatdir{$mspftype}/$base.$type.subtracted.no-sil");
#                shell("touch $mspfdatdir{$mspftype}/$base.$type.subtracted.no-sil");
#                open( F, "$gvfaldir{'phn'}/$base.lab" ) || die "Cannot open $!";
#                while ( $str = <F> ) {
#                   chomp($str);
#                   @arr = split( / /, $str );
#                   $find = 0;
#                   for ( $j = 0 ; $j < @slnt ; $j++ ) {
#                      if ( $arr[2] eq "$slnt[$j]" ) { $find = 1; last; }
#                   }
#                   if ( $find == 0 ) {
#                      $start = int( $arr[0] * ( 1.0E-07 / ( $fs / $sr ) ) );
#                      $end   = int( $arr[1] * ( 1.0E-07 / ( $fs / $sr ) ) );
#                      shell("$BCUT -s $start -e $end -l $ordr{$type} < $mspfdatdir{$mspftype}/$base.$type.subtracted >> $mspfdatdir{$mspftype}/$base.$type.subtracted.no-sil");
#                   }
#                }
#                close(F);
#             }
#             else {
#                shell("cp $mspfdatdir{$mspftype}/$base.$type.subtracted $mspfdatdir{$mspftype}/$base.$type.subtracted.no-sil");
#             }

#             # calculate modulation spectrum of each dimension
#             for ( $d = 0 ; $d < $ordr{$type} ; $d++ ) {
#                $line = get_cmd_seq2ms( "$mspfdatdir{$mspftype}/$base.$type.subtracted.no-sil", $type, $d );
#                shell("$line >> $mspfstatsdir{$mspftype}/${type}_dim$d.data");
#             }

#             # remove temporal files
#             shell("rm -f $mspfdatdir{$mspftype}/$base.$type.mean");
#             shell("rm -f $mspfdatdir{$mspftype}/$base.$type.subtracted.no-sil");
#          }
#       }
#       print "done\n";
#    }
#    close(SCP);

#    # estimate modulation spectrum statistics
#    foreach $type ('mgc') {
#       foreach $mspftype ( 'nat', $gentype ) {
#          for ( $d = 0 ; $d < $ordr{$type} ; $d++ ) {
#             shell( "$VSTAT -o 1 -l " . ( $mspfFFTLen / 2 + 1 ) . " -d $mspfstatsdir{$mspftype}/${type}_dim$d.data > $mspfmean{$type}{$mspftype}[$d]" );
#             shell( "$VSTAT -o 2 -l " . ( $mspfFFTLen / 2 + 1 ) . " -d $mspfstatsdir{$mspftype}/${type}_dim$d.data | $SOPR -SQRT > $mspfstdd{$type}{$mspftype}[$d]" );

#             # remove temporal files
#             shell("rm -f $mspfstatsdir{$mspftype}/${type}_dim$d.data");
#          }
#       }
#    }
# }

##################################################################################################
