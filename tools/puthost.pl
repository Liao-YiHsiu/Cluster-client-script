#!/usr/bin/env perl
use warnings;
$common_dir    = "/home/speech/.gethost/";
$lock_file     = $common_dir . ".lock";
$status_file   = $common_dir . $ENV{"USER"};

# set real UID to effective UID
$> = $<;

@ARGV != 4 && die "usage: $0 host gpus threads gpu_id";

$ret_host   = $ARGV[0];
$gpu_num    = $ARGV[1];
$thread_num = $ARGV[2];
$ret_gpu_id = $ARGV[3];

if($gpu_num < 0){
   die "gpu number is negative!";
}

if($thread_num <= 0){
   die "thread-num should be larger than 0";
}

open(LOCK, "+<$lock_file") || die "fail open $lock_file\n";
until(flock(LOCK, 6)){
   select(undef, undef, undef, 0.01);
}

open(STATUS, "+<$status_file") || die "fail open $status_file\n";
until(flock(STATUS, 6)){
   select(undef, undef, undef, 0.01);
}

%stat_me = ();
while(<STATUS>){
   $_ =~ s/\R//g;
   @array = split(' ', $_);
   $host = $array[0];
   $stat_me{$host}{cpus} = $array[1];
   $stat_me{$host}{gpu}{0} = $array[2];
   $stat_me{$host}{gpu}{1} = $array[3];
}

%stat = ();
while(<LOCK>){
   $_ =~ s/\R//g;
   @array = split(' ', $_);
   $host  = $array[0];
   $stat{$host}{time} = $array[1];
   $stat{$host}{cpus} = $array[2];
   $stat{$host}{gpu}{0} = $array[3];
   $stat{$host}{gpu}{1} = $array[4];
   $stat{$host}{used_cpus} = $array[5];
   $stat{$host}{used_gpu}{0} = $array[6];
   $stat{$host}{used_gpu}{1} = $array[7];
}

if($thread_num > $stat_me{$ret_host}{cpus}){
   print STDERR "Error! Try to free more cpus($thread_num) than allocated($stat_me{$ret_host}{cpus}), release $stat_me{$ret_host}{cpus} cpus only\n";
   $thread_num = $stat_me{$ret_host}{cpus};
}

if($thread_num == 0){
   exit -1;
}

$stat{$ret_host}{cpus} += $thread_num;
$stat{$ret_host}{used_cpus} -= $thread_num;

if($gpu_num == 1){
   $stat{$ret_host}{gpu}{$ret_gpu_id} = 1;
   $stat{$ret_host}{used_gpu}{$ret_gpu_id} = 0;
}elsif($gpu_num == 2){
   $stat{$ret_host}{gpu}{0} = 1;
   $stat{$ret_host}{gpu}{1} = 1;
   $stat{$ret_host}{used_gpu}{0} = 0;
   $stat{$ret_host}{used_gpu}{1} = 0;
}

if($stat{$ret_host}{used_cpus} == 0 &&
      $stat{$ret_host}{used_gpu}{0} == 0 && $stat{$ret_host}{used_gpu}{1} == 0){
   $stat{$ret_host}{time} = time();
}

seek(LOCK, 0, 0);
foreach my $key (sort keys %stat){
   print LOCK "$key $stat{$key}{time} $stat{$key}{cpus} $stat{$key}{gpu}{0} $stat{$key}{gpu}{1} $stat{$key}{used_cpus} $stat{$key}{used_gpu}{0} $stat{$key}{used_gpu}{1}\n";
}
truncate(LOCK, tell(LOCK));

flock(LOCK, 8) || die "failed to unlock $lock_file\n";
close(LOCK) || die "failed to close $lock_file\n";


$stat_me{$ret_host}{cpus} -= $thread_num;
if($gpu_num == 1){
   $stat_me{$ret_host}{gpu}{$ret_gpu_id} = 0;
}elsif($gpu_num == 2){
   $stat_me{$ret_host}{gpu}{0} = 0;
   $stat_me{$ret_host}{gpu}{1} = 0;
}

seek(STATUS, 0, 0);
foreach my $key (sort keys %stat_me){
   print STATUS "$key $stat_me{$key}{cpus} $stat_me{$key}{gpu}{0} $stat_me{$key}{gpu}{1}\n";
}
truncate(STATUS, tell(STATUS));

flock(STATUS, 8) || die "failed unlocking $lock_file";
close(STATUS);
