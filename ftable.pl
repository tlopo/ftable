#! /opt/perl/bin/perl
# Author: Tiago Lopo Da Silva
# Date: 20/10/2013
# Purpose: Print formatted table based on csv file

# Usage:
# ./ftable.pl <alignment> <filename>
# example: 
#	Left align 1st column, right align 2nd column and centralize 3rd column
#		./ftable.pl 'l,r,c' test.cs
#	Read from pipe
#		app | ./ftable.pl -
#	or
#		app | ./ftable.pl 
#


use strict; 
use warnings;
use POSIX;
use Switch;
use Data::Dumper;

our $comma="<comma>";
our $dollar="<dollar>";
our $pipe="|";
our $plus="+";
our $minus="-";

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
        $i =~ s/,/$comma/g; 
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
    
    @a =  split (/,/,$translated);
 
    foreach my $i ( @a ){
            $i =~ s/$comma/,/g;
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
	my @align;
	if ( defined($_[0]) ){
		@align=split (/,/,"$_[0]");
	}
	my @b;
	my @a;
	my @length;
	my $l=0; 
	while (<>){
		@a= split_csv("$_");
		my $c=0; 
		foreach my $i (@a){
			$i =~ s/^\s+//;
			$i =~ s/\s+$//;
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
		$l++; 
	
	}
	my %h= ( 
			content => \@b,
			length  => \@length,
			align => \@align
		);
	return %h;
}


sub print_table{
	my %h = %{$_[0]};
	my @content=@{$h{"content"}};
	my @length=@{$h{"length"}};
	my @align=@{$h{"align"}};
	my $a=0;
	foreach my $line (@content){
		print_border(\@length);
		my $str; 
		my $b=0;
		foreach my $col (@{$content[$a]}){

			$col =~ s/"//g;
			$col =~ s/'//g;
			my $l=$length[$b];
			print "$pipe";

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
		print "$pipe\n";
		$a++;
	}
	print_border(\@length);
}

my %h;
if ($#ARGV > 0){
	%h=get_details( shift(@ARGV) );
}else {
	%h=get_details();
}
#print Dumper(\%h); 
print_table(\%h);
