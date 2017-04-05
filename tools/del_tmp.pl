#!/usr/bin/env perl
use warnings; #sed replacement for -w perl parameter
use Digest::MD5 qw(md5_hex);

# use Data::Dumper;
$usage = <<"END";
usage: del_tmp.pl path
END

@ARGV != 1 && die $usage;
if(not -e $ARGV[0]){ die "no such file/directory $ARGV[0]\n"; }

$path      = `readlink -f $ARGV[0]`;
$path      =~ s/\R//g;
$md5       = md5_hex($path);
$lock_file = "/home/$ENV{'USER'}/.copy_to_tmp.$md5";
$tmpdir    = "/tmp/$md5";

system("exec.sh 'rm -rf $tmpdir'");
system("rm -rf $lock_file");
