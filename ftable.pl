#! /usr/bin/env perl
# Author: Tiago Lopo Da Silva
# Date: 20/10/2013
# Purpose: Print formatted table

use strict; 
use warnings;
use POSIX;
use Switch;
use Getopt::Long qw(:config no_ignore_case);
use Data::Dumper;

our $comma="<comma>";
our $dollar="<dollar>";
our $pipe="|";
our $plus="+";
our $minus="-";
our $FS=',';
our $nb=0;

my %h;
if ($#ARGV >= 0){
	my $lf; my $cf; my $rf; my $print;

	GetOptions(	'l|left:s'         => \$lf,
        	   	'r|right:s'        => \$rf,
           		'c|center:s'       => \$cf,
           		'p|print:s'       => \$print,
           		'F:s'       	   => \$FS,
           		'n|noborder'       => \$nb,
          	) || print_usage();

	%h=get_details($lf,$cf,$rf,$print);
}else {
	%h=get_details();
}
print_table(\%h);

sub get_quoted_fields {
    my $str1 = $_[0];
    my $qf;
    while ( $str1 =~ /(["'].*?["'])/ ){
        $qf.="$1${comma}";
        $str1 =~ s/$1//;
    }
    return $qf;
}

sub get_translated {
    my $qf = $_[0];
    my $str= $_[1];
    my @arr; 
    my %h; 

    if (defined ($qf)) {
        @arr = split(/$comma/,$qf);
    }

    foreach my $i ( @arr ){
        my $tmpvar=$i;
        $i =~ s/$FS/$comma/g; 
        $h{$tmpvar} = $i; 
    }

    while ( my($key,$value) = each(%h) ){
        $key =~ s/\$/\\\$/g;
        eval "\$str =~ s/$key/$value/g; ";
    }
  
    return $str;
}

sub split_csv {
    my $str=$_[0];
    $str =~ s/\$/$dollar/g;
    $str =~ s/\(/<op>/g;
    $str =~ s/\)/<cp>/g;
    $str =~ s/\//<slash>/g;
    my $str1=$str;
    my $qf;
    my @a; 

    $qf=get_quoted_fields("$str1");

    my $translated = get_translated($qf,$str);
    
    @a =  split (/$FS/,$translated);
 
    foreach my $i ( @a ){
	    my $safe_fs=$FS;
	    switch($safe_fs) {
	    	case '\.' {$safe_fs =~ s/\\//g;}
	    	case '\t' {$safe_fs =~ s/\\t/\t/g;}
	    	case '\s' {$safe_fs =~ s/\\s/ /g;}
		
	    }

            $i =~ s/$comma/$safe_fs/eg;
            $i =~ s/$dollar/\$/g;
            $i =~ s/<op>/\(/g;
            $i =~ s/<cp>/\)/g;
            $i =~ s/<slash>/\//g;
            $i =~ s/["']//g;
            $i =~ s/\s+/ /g;
    }

    return @a;
}

sub fill_str {
	my $f_char=$_[0];
	my $f_times=$_[1];
	my $str;
	$str="$f_char"x$f_times;
	return $str;
}

sub print_border {
	my @length=@{$_[0]};
	foreach my $i (@length){
		unless (defined($i)){$i=1;}
		print "$plus";
		my $counter=0;
		while ( $counter < ($i+2) ){
			print "$minus";
			$counter++;
		}
	}
	print "$pipe\n";
}

sub print_left {
	my $length=$_[0];
	my $col=$_[1];
	unless (defined($length)){ $length="";}
	unless (defined($col)){ $col="";}
	my $str="printf ' %-".$length."s ','".$col."';";
	eval $str
}

sub print_right {
	my $length=$_[0];
	my $col=$_[1];
	unless (defined($length)){ $length="";}
	unless (defined($col)){ $col="";}
	my $str="printf ' %".$length."s ','".$col."';";
	eval $str
}

sub print_center {
	my $length=$_[0];
	my $col=$_[1];
	my $str;
	unless (defined($length)){ $length=1}
	my $cl=length($col);
	my $padding=(($length - $cl)/2);
        my $lp; my $rp;
	if ( (($length - $cl) % 2 ) == 0 ){
		$lp=$padding;	
		$rp=$padding;	
	}else{
		$lp=ceil($padding);	
		$rp=floor($padding);	
	}
	
	my $l_str ; my $r_str;
	$l_str=fill_str(" ",$lp);
	$r_str=fill_str(" ",$rp);
	$str="printf ' %".$length."s ','".$l_str.$col.$r_str."';";
	eval $str;
}

sub get_details {
	my @align = get_align($_[0],$_[1],$_[2]);
	my @print = get_print($_[3]);
	my @content;
	my @tmp_arr;
	my @tmp_arr2;
	my @length;
	my $n_col=0;
	my $counter=0;
	
	my $p_print;
	if(@print){ $p_print=1; }else{ $p_print=0;}
 
	while (<>){
		@tmp_arr= split_csv("$_");
		unless( $p_print ){
			for ( my $i=0 ; $i <= $#tmp_arr; $i++){
				$print[$i]=$i;	
			}
		}
		my $counter2=0;
		foreach my $i (@print){
			$tmp_arr2[$counter2] = $tmp_arr[$i];
			$counter2++
		}
		$counter2=0; 
		foreach my $i (@tmp_arr2){
				defined($i) && $i =~ s/^\s+//;
				defined($i) && $i =~ s/\s+$//;
				$content[$counter][$counter2] = $i;
				my $li= length($i);
				if ( defined( $length[$counter2] ) ){
					if( $li > $length[$counter2] ) {
						$length[$counter2]=$li;
					}
				}else{
					$length[$counter2]=$li;
				}	
			$counter2++; 
		}
		if ( $counter2 > $n_col ){ $n_col=$counter2;}
		$counter++; 
	
	}

	my %h= ( 
			content => \@content,
			length  => \@length,
			align => \@align,
			print => \@print,
			nb => $nb,
			n_col => $n_col,
			FS => $FS,
		);
	
	return %h;
}


sub print_table{
	my %h = %{$_[0]};
	my @content=@{$h{"content"}};
	my @length=@{$h{"length"}};
	my @align=@{$h{"align"}};
	my @print=@{$h{"print"}};
	my $nb=$h{"nb"};
	my $n_col=$h{"n_col"};
	my $counter=0;

	foreach my $line (@content){
		$nb || print_border(\@length);
		my $str; 
		my $counter2=0;
		for ( my $i=0; $i < $n_col ; $i++ ){
			my $col = $content[$counter][$i];
			unless (defined($col)) { $col = ""}
			$col =~ s/"//g;
			$col =~ s/'//g;
			my $l=$length[$counter2];
			$nb || print "$pipe";

			my $left="false"; my $right="false";
			my $center="false";
			switch ($align[$counter2]){
				case "l" { $left="true";}
				case "r" { $right="true";}
				else  { $center="true";}
			}

			if ( $right eq "true" ){
				print_right($l,$col);
			}
			if ( $left eq "true" ){
				print_left($l,$col);
			}
		
			if ( $center eq "true" ){
				print_center($l,$col);
			}
	
			$counter2++;
		}
		unless ($nb) {print "$pipe\n"}else{print "\n"}
		$counter++;
	}
	$nb || print_border(\@length);
}

sub get_align {
	my $lf = $_[0];
	my $cf = $_[1];
	my $rf = $_[2];
	my @align;

	defined($lf) && (my  @lf = split (/,/,$lf));
	defined($cf) && (my  @cf = split (/,/,$cf));
	defined($rf) && (my  @rf = split (/,/,$rf));

	foreach my $i (@lf){
		$align[$i] = "l";	
	}

	foreach my $i (@cf){
		$align[$i] = "c";	
	}

	foreach my $i (@rf){
		$align[$i] = "r";	
	}
	shift(@align);
	return @align;
}

sub get_print {
	my $print = $_[0];
	my @print;
	defined($print) && (my @a = split(/,/,$print));
	my $counter=1;
	foreach my $i (@a){
		$print[$counter] = $i-1;
		$counter++;
	}
	shift(@print);
	return @print;
}

sub print_usage {

my $usage = << 'EOF';
Usage: ftable [OPTIONS] [FILE]

Options:
  -l, --left
        List of field numbers (separated by comma) to be left aligned

  -r, --right
        List of field numbers (separated by comma) to be right aligned

  -c, --center 
        List of field numbers (separated by comma) to be center aligned
        It is default if no alignmnet provided

  -p, --print
        List of field numbers (separated by comma) to be printed and ordered

  -n, --noborder 
        Do not print border

  -F, --field-separator
        Field separator, if no specified "comma" (,) is the default value

Examples:

        ftable -F ':'  -p 3,1,6 /etc/passwd
        ftable -l 1 -c 2,3 -r 4 /tmp/table.csv
        ftable -n -F ':' /etc/passwd  
EOF
	print $usage;
	exit 2;
}
