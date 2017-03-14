#!/usr/bin/env perl
use List::Util qw(min);
use LWP::Simple;
use warnings;
$common_dir    = "/home/speech/.gethost/";
$lock_file     = $common_dir . ".lock";
$status_file   = $common_dir . $ENV{"USER"};
$available_url = "http://140.112.21.35:5311/available";
$wait_time  = 5;
$retry_wait = 1;
$max_thread_req = 16;
$preserve_ratio = 0.1;
#$wait_time_max  = 600;
$cached_time    = 600;

# set real UID to effective UID
$> = $<;

@ARGV != 3 && @ARGV != 2 && die "usage: $0 gpus threads [host_list]";

$gpu_num    = $ARGV[0];
$thread_num = $ARGV[1];

$host_list = ".*";
if(@ARGV == 3){
   $host_list  = $ARGV[2];
   $host_list =~ s/\s/\|/g;
}

$ret_host = "";

if($thread_num > $max_thread_req){
   $thread_num = $max_thread_req;
   print STDERR "Requesting cpus $thread_num larger than $max_thread_req, setting to $max_thread_req\n";
}

if($thread_num <= 0){
   die "threads-num should be larger than 0";
}

if($gpu_num == 0){
   $wait_time = 1;
}else{
   $wait_time *= $gpu_num;
}

# waiting time increase as we demand more threads
$wait_time *= $thread_num; 

while($ret_host eq ""){

   # lock file
   `touch $lock_file && chmod g+w $lock_file` if ! -e $lock_file;
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
   $now = time();

   # get server status
   $contents = get($available_url);
   $contents =~ s/\A.*?\n//g;
   @ret_arr  = ();
   foreach (split('\n', $contents)){
      @array = split('\t', $_);
      if(not exists($stat{$array[0]})){
         $stat{$array[0]}{time} = $now;
         $stat{$array[0]}{cpus} = $array[2];
         $stat{$array[0]}{gpus} = $array[3] + $array[4];
         $stat{$array[0]}{used_cpus} = 0;
         $stat{$array[0]}{used_gpus} = 0;

      # update status
      }elsif($stat{$array[0]}{used_cpus} == 0 && 
            $stat{$array[0]}{used_gpus} == 0 &&
            $stat{$array[0]}{time} + $cached_time < $now){
         $stat{$array[0]}{time} = $now;
         $stat{$array[0]}{cpus} = $array[2];
         $stat{$array[0]}{gpus} = $array[3] + $array[4];

#      }else{
#         $stat{$array[0]}{cpus} = min $array[4], $stat{$array[0]}{cpus};
#         $stat{$array[0]}{gpus} = min $array[5] + $array[6], $stat{$array[0]}{gpus};
      }

      if($array[0] =~ /$host_list/){
         $host_cpu = $stat{$array[0]}{cpus} - $array[1] * $preserve_ratio; 
         $host_gpu = $stat{$array[0]}{gpus};

         # requesting cpu jobs only, keep some cpus for gpu jobs
         if($gpu_num == 0){
            $host_cpu -= $host_gpu;
         }

         for($n = 1, $doing = 1; $doing ; $n = $n + 1){
            if($n * $thread_num <= $host_cpu && 
                  $n * $gpu_num <= $host_gpu){
               push(@ret_arr, $array[0]);
            } else {
               $doing = 0;
            }
         }
      }
   }

   if(scalar @ret_arr != 0){
      $ret_host = $ret_arr[int(rand(scalar @ret_arr))];
   }

   # update stat
   if($ret_host ne ""){
      $stat{$ret_host}{cpus} -= $thread_num;
      $stat{$ret_host}{gpus} -= $gpu_num;
      $stat{$ret_host}{used_cpus} += $thread_num;
      $stat{$ret_host}{used_gpus} += $gpu_num;
   }
   seek(LOCK, 0, 0);
   foreach my $key (sort keys %stat){
      print LOCK "$key $stat{$key}{time} $stat{$key}{cpus} $stat{$key}{gpus} $stat{$key}{used_cpus} $stat{$key}{used_gpus}\n";
   }
   truncate(LOCK, tell(LOCK));

   flock(LOCK, 8) || die "failed unlocking $lock_file";
   close(LOCK);

   if($ret_host eq ""){
#print STDERR "No available host, requesting cpus $thread_num and gpus $gpu_num, retry after $retry_wait seconds.\n";
      sleep($retry_wait);
#      $retry_wait = $retry_wait * 2;
#      if($retry_wait > $wait_time_max){
#         $retry_wait = $wait_time_max;
#      }
   }
}

`touch $status_file` if ! -e $status_file;
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

if(not exists($stat_me{$array[0]})){
   $stat_me{$ret_host}{cpus} = $thread_num;
   $stat_me{$ret_host}{gpus} = $gpu_num;
}else{
   $stat_me{$ret_host}{cpus} += $thread_num;
   $stat_me{$ret_host}{gpus} += $gpu_num;
}

seek(STATUS, 0, 0);
foreach my $key (sort keys %stat_me){
   print STATUS "$key $stat_me{$key}{cpus} $stat_me{$key}{gpus}\n";
}
truncate(STATUS, tell(STATUS));

flock(STATUS, 8) || die "failed unlocking $lock_file";
close(STATUS);

print STDOUT "$ret_host";

