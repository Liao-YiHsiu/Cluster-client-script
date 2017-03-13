#!/usr/bin/env perl
use warnings;
use LWP::Simple;
$common_dir    = "/home/speech/.gethost/";
$lock_file     = $common_dir . ".lock";
$status_file   = $common_dir . $ENV{"USER"};

# set real UID to effective UID
$> = $<;

@ARGV != 3 && die "usage: $0 gpus threads host";

$gpu_num    = $ARGV[0];
$thread_num = $ARGV[1];
$host       = $ARGV[2];

open(LOCK, "+<$lock_file") || die "fail open $lock_file\n";
until(flock(LOCK, 6)){
   sleep(0.1);
}
%stat = ();
while(<LOCK>){
   $_ =~ s/\R//g;
   @array = split(' ', $_);
   $stat{$array[0]}{time} = $array[1];
   $stat{$array[0]}{cpus} = $array[2];
   $stat{$array[0]}{gpus} = $array[3];
   $stat{$array[0]}{used_cpus} = $array[4];
   $stat{$array[0]}{used_gpus} = $array[5];
}

$stat{$host}{cpus} += $thread_num;
$stat{$host}{gpus} += $gpu_num;
$stat{$host}{used_cpus} -= $thread_num;
$stat{$host}{used_gpus} -= $gpu_num;

if($stat{$host}{used_cpus} == 0 && $stat{$host}{used_gpus} == 0){
   $stat{$host}{time} = time();
}

seek(LOCK, 0, 0);
foreach my $key (sort keys %stat){
   print LOCK "$key $stat{$key}{time} $stat{$key}{cpus} $stat{$key}{gpus} $stat{$key}{used_cpus} $stat{$key}{used_gpus}\n";
}
truncate(LOCK, tell(LOCK));

flock(LOCK, 8) || die "failed to unlock $lock_file\n";
close(LOCK) || die "failed to close $lock_file\n";

open(STATUS, "+<$status_file") || die "fail open $status_file\n";
until(flock(STATUS, 6)){
   sleep(0.1);
}

%stat_me = ();
while(<STATUS>){
   $_ =~ s/\R//g;
   @array = split(' ', $_);
   $stat_me{$array[0]}{cpus} = $array[1];
   $stat_me{$array[0]}{gpus} = $array[2];
}

$stat_me{$host}{cpus} -= $thread_num;
$stat_me{$host}{gpus} -= $gpu_num;

seek(STATUS, 0, 0);
foreach my $key (sort keys %stat_me){
   print STATUS "$key $stat_me{$key}{cpus} $stat_me{$key}{gpus}\n";
}
truncate(STATUS, tell(STATUS));

flock(STATUS, 8) || die "failed unlocking $lock_file";
close(STATUS);
