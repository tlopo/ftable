#! /opt/perl/bin/perl
# Author: Tiago Lopo Da Silva
# Date: 20/10/2013
# Purpose: Print formatted table based on csv file

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
          	);
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
    my $s= $_[1];
    my @a; 
    my %h; 

    if (defined ($qf)) {
        @a = split(/$comma/,$qf);
    }

    foreach my $i ( @a ){
        my $b=$i;
        $i =~ s/$FS/$comma/g; 
        $h{$b} = $i; 
    }

    while ( my($key,$value) = each(%h) ){
        $key =~ s/\$/\\\$/g;
        eval "\$s =~ s/$key/$value/g; ";
    }
  
    return $s;
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
	my $a=$_[0];
	my $b=$_[1];
	my $c=0;
	my $str;
	while ( $c < $b){
		$str.=$a;
		$c++;
	}
	$str.="";
	return $str;
}

sub print_border {
	my @l=@{$_[0]};
	foreach my $i (@l){
		print "$plus";
		my $a=0;
		while ( $a < ($i+2) ){
			print "$minus";
			$a++;
		}
	}
	print "$pipe\n";
}

sub print_left {
	my $l=$_[0];
	my $col=$_[1];
	unless (defined($l)){ $l="";}
	unless (defined($col)){ $col="";}
	my $str="printf ' %-".$l."s ','".$col."';";
	eval $str
}

sub print_right {
	my $l=$_[0];
	my $col=$_[1];
	unless (defined($l)){ $l="";}
	unless (defined($col)){ $col="";}
	my $str="printf ' %".$l."s ','".$col."';";
	eval $str
}

sub print_center {
	my $l=$_[0];
	my $col=$_[1];
	my $str;
	my $cl=length($col);
	my $padding=(($l - $cl)/2);
        my $lp; my $rp;
	if ( (($l - $cl) % 2 ) == 0 ){
		$lp=$padding;	
		$rp=$padding;	
	}else{
		$lp=ceil($padding);	
		$rp=floor($padding);	
	}
	
	my $l_str ; my $r_str;
	$l_str=fill_str(" ",$lp);
	$r_str=fill_str(" ",$rp);
	$str="printf ' %".$l."s ','".$l_str.$col.$r_str."';";
	eval $str;
}

sub get_details {
	my @align = get_align($_[0],$_[1],$_[2]);
	my @print = get_print($_[3]);
	my @b;
	my @a;
	my @d;
	my @length;
	my $n_col=0;
	my $l=0;
	
	my $p_print;
	if(@print){ $p_print=1; }else{ $p_print=0;}
 
	while (<>){
		@a= split_csv("$_");
		unless( $p_print ){
			for ( my $x=0 ; $x <= $#a; $x++){
				$print[$x]=$x;	
			}
		}
		my $m=0;
		foreach my $n (@print){
			$d[$m] = $a[$n];
			$m++
		}
		my $c=0; 
		foreach my $i (@d){
			defined($i) && $i =~ s/^\s+//;
			defined($i) && $i =~ s/\s+$//;
			$b[$l][$c] = $i;
			my $li= length($i);
			if ( defined( $length[$c] ) ){
				if( $li > $length[$c] ) {
					$length[$c]=$li;
				}
			}else{
				$length[$c]=$li;
			}	
			$c++; 
		}
		if ( $c > $n_col ){ $n_col=$c;}
		$l++; 
	
	}
	my %h= ( 
			content => \@b,
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
	my $a=0;

	#print Dumper(\@print);
	foreach my $line (@content){
		$nb || print_border(\@length);
		my $str; 
		my $b=0;
		for ( my $z=0; $z < $n_col ; $z++ ){
			my $col = $content[$a][$z];
			unless (defined($col)) { $col = ""}
			$col =~ s/"//g;
			$col =~ s/'//g;
			my $l=$length[$b];
			$nb || print "$pipe";

			my $left="false"; my $right="false";
			my $center="false";
			switch ($align[$b]){
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
	
			$b++;
		}
		unless ($nb) {print "$pipe\n"}else{print "\n"}
		$a++;
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
	my $c=1;
	foreach my $i (@a){
		$print[$c] = $i-1;
		$c++;
	}
	shift(@print);
	return @print;
}
