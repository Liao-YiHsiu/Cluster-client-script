#!/usr/bin/env perl
use List::Util qw(min);
use LWP::Simple;
use warnings;
$common_dir    = "/home/speech/.gethost/";
$lock_file     = $common_dir . ".lock";
$status_file   = $common_dir . $ENV{"USER"};
$available_url = "http://140.112.21.35:5311/available";
$retry_wait    = 1;
$max_thread_req = 16;
$max_gpu_req    = 2;
$preserve_ratio = 0.06;
$cached_time    = 600;

@ARGV != 3 && @ARGV != 2 && die "usage: $0 gpus threads [host_list]";

$gpu_num    = $ARGV[0];
$thread_num = $ARGV[1];

$host_list = ".*";
if(@ARGV == 3){
   $host_list  = $ARGV[2];
   $host_list =~ s/\s/\|/g;
}

$ret_host = "";
$ret_gpu_id = -1;

if($thread_num > $max_thread_req){
   print STDERR "Requesting cpus $thread_num larger than $max_thread_req, setting to $max_thread_req\n";
   $thread_num = $max_thread_req;
}

if($gpu_num > $max_gpu_req){
   print STDERR "Requesting gpus $gpu_num larger than $max_gpu_req, setting to $max_gpu_req\n";
   $gpu_num = $max_gpu_req;
}

if($thread_num <= 0){
   die "threads-num should be larger than 0";
}

while($ret_host eq ""){
   # lock file
   `touch $lock_file && chmod g+w $lock_file` if ! -e $lock_file;
   open(LOCK, "+<$lock_file") || die "fail open $lock_file\n";
   until(flock(LOCK, 6)){
      select(undef, undef, undef, 0.01);
   }
   %stat = ();
   while(<LOCK>){
      $_ =~ s/\R//g;
      @array = split(' ', $_);
      $host  = $array[0];
      $stat{$host}{time} = $array[1];
      $stat{$host}{cpus} = $array[2];
      $stat{$host}{gpu0} = $array[3];
      $stat{$host}{gpu1} = $array[4];
      $stat{$host}{used_cpus} = $array[5];
      $stat{$host}{used_gpu0} = $array[6];
      $stat{$host}{used_gpu1} = $array[7];
   }
   $now = time();

   # get server status
   $contents = get($available_url);
   $contents =~ s/\A.*?\n//g;
   @ret_arr  = ();
   @ret_gpu_arr = ();
   foreach (split('\n', $contents)){
      @array = split('\t', $_);
      $host = $array[0];
      $host_cpu_num = $array[1];
     
      # initialize status
      if(not exists($stat{$host})){
         $stat{$host}{time} = $now;
         $stat{$host}{cpus} = $array[2];
         $stat{$host}{gpu0} = $array[3];
         $stat{$host}{gpu1} = $array[4];
         $stat{$host}{used_cpus} = 0;
         $stat{$host}{used_gpu0} = 0;
         $stat{$host}{used_gpu1} = 0;

      # update status
      }elsif($stat{$host}{used_cpus} == 0 && 
            $stat{$host}{used_gpu0} == 0 &&
            $stat{$host}{used_gpu1} == 0 &&
            $stat{$host}{time} + $cached_time < $now){
         $stat{$host}{time} = $now;
         $stat{$host}{cpus} = $array[2];
         $stat{$host}{gpu0} = $array[3];
         $stat{$host}{gpu1} = $array[4];
      }

      if($host =~ /$host_list/){
         $host_cpu = $stat{$host}{cpus} - $host_cpu_num * $preserve_ratio; 

         # requesting cpu jobs only, keep some cpus for gpu jobs
         if($gpu_num == 0){
            $host_cpu -= $stat{$host}{gpu0} + $stat{$host}{gpu1};
            for($n = 1; $n * $thread_num <= $host_cpu; $n = $n + 1){
               push(@ret_arr, $host);
            }
         }elsif($gpu_num == 1){
            if($host_cpu >= $thread_num){
               if($stat{$host}{gpu0} == 1){
                  push(@ret_arr, $host);
                  push(@ret_gpu_arr, 0);
               }
               if($stat{$host}{gpu1} == 1){
                  push(@ret_arr, $host);
                  push(@ret_gpu_arr, 1);
               }
            }
         }else{
            if($host_cpu >= $thread_num && 
                  $stat{$host}{gpu0} == 1 && $stat{$host}{gpu1} == 1){
               push(@ret_arr, $host);
            }
         }
      }
   }

   if(scalar @ret_arr != 0){
      $idx = int(rand(scalar @ret_arr));
      $ret_host = $ret_arr[$idx];
      if($gpu_num == 1){
         $ret_gpu_id = $ret_gpu_arr[$idx];
      }
   }

   # update stat
   if($ret_host ne ""){
      $stat{$ret_host}{cpus} -= $thread_num;
      $stat{$ret_host}{used_cpus} += $thread_num;
      if($gpu_num == 1){
         $stat{$ret_host}{'gpu'.$ret_gpu_id} = 0;
         $stat{$ret_host}{'used_gpu'.$ret_gpu_id} = 1;
      }elsif($gpu_num == 2){
         $stat{$ret_host}{gpu0} = 0;
         $stat{$ret_host}{gpu1} = 0;
         $stat{$ret_host}{used_gpu0} = 1;
         $stat{$ret_host}{used_gpu1} = 1;
      }
   }
   seek(LOCK, 0, 0);
   foreach my $key (sort keys %stat){
      print LOCK "$key $stat{$key}{time} $stat{$key}{cpus} $stat{$key}{gpu0} $stat{$key}{gpu1} $stat{$key}{used_cpus} $stat{$key}{used_gpu0} $stat{$key}{used_gpu1}\n";
   }
   truncate(LOCK, tell(LOCK));

   flock(LOCK, 8) || die "failed unlocking $lock_file";
   close(LOCK);

   if($ret_host eq ""){
      select(undef, undef, undef, $retry_wait);
   }
}

`touch $status_file` if ! -e $status_file;
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

if(not exists($stat_me{$ret_host})){
   $stat_me{$ret_host}{cpus} = $thread_num;
   if($gpu_num == 0){
      $stat_me{$ret_host}{gpu}{0} = 0;
      $stat_me{$ret_host}{gpu}{1} = 0;
   }elsif($gpu_num == 1){
      $another_id = ($ret_gpu_id + 1) % 2;
      $stat_me{$ret_host}{gpu}{$ret_gpu_id} = 1;
      $stat_me{$ret_host}{gpu}{$another_id} = 0;
   }elsif($gpu_num == 2){
      $stat_me{$ret_host}{gpu}{0} = 1;
      $stat_me{$ret_host}{gpu}{1} = 1;
   }
}else{
   $stat_me{$ret_host}{cpus} += $thread_num;
   if($gpu_num == 1){
      $stat_me{$ret_host}{gpu}{$ret_gpu_id} = 1;
   }elsif($gpu_num == 2){
      $stat_me{$ret_host}{gpu}{0} = 1;
      $stat_me{$ret_host}{gpu}{1} = 1;
   }
}

seek(STATUS, 0, 0);
foreach my $key (sort keys %stat_me){
   print STATUS "$key $stat_me{$key}{cpus} $stat_me{$key}{gpu}{0} $stat_me{$key}{gpu}{1}\n";
}
truncate(STATUS, tell(STATUS));

flock(STATUS, 8) || die "failed unlocking $lock_file";
close(STATUS);

print STDOUT "$ret_host $ret_gpu_id";
