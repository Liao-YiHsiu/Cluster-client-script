#!/usr/bin/env perl
use warnings; #sed replacement for -w perl parameter
use Digest::MD5 qw(md5_hex);

# use Data::Dumper;
$usage = <<"END";
usage: copy_to_tmp.pl path
END

@ARGV != 1 && die $usage;
if(not -e $ARGV[0]){ die "no such file/directory $ARGV[0]\n"; }

$path      = `readlink -f $ARGV[0]`;
$path      =~ s/\R//g;
$md5       = md5_hex($path);
$lock_file = "/home/$ENV{'USER'}/.copy_to_tmp.$md5";
$tmpdir    = "/tmp/$md5";
$hostname  = `hostname`;
$hostname  =~ s/\R//g;

`touch $lock_file` if ! -e $lock_file;

my ($LOCK, $status_ref) = lock_and_get($lock_file);
my %status = %$status_ref;

if(0 == scalar keys %status){
   $status{$hostname} = "copying";
   write_and_close($LOCK, \%status);
   if(system("rm -rf $tmpdir; cp -rf $path $tmpdir") != 0){
      ($LOCK, $status_ref) = lock_and_get($lock_file);
      %status = %$status_ref;
      delete $status{$hostname};
      write_and_close($LOCK, \%status);
      die "copy $path to $tmpdir failed\n";
   }

   ($LOCK, $status_ref) = lock_and_get($lock_file);
   %status = %$status_ref;
   $status{$hostname} = "ready";
   write_and_close($LOCK, \%status);

}elsif(not exists $status{$hostname}){
   my $host = "";
   while($host eq ""){
      foreach my $key(keys %status){
         if($status{$key} eq "ready"){
            $host=$key;
            last;
         }
      }
      
      if($host ne ""){
         $status{$host} = "uploading";
         $status{$hostname} = "downloading";
         write_and_close($LOCK, \%status);

         if(system("rm -rf $tmpdir; scp -r $host:$tmpdir $tmpdir") != 0){
            ($LOCK, $status_ref) = lock_and_get($lock_file);
            %status = %$status_ref;
            $status{$host} = "ready";
            delete $status{$hostname};
            write_and_close($LOCK, \%status);
            die "Copy file from $host:$tmpdir to $tmpdir failed\n";
         }
         ($LOCK, $status_ref) = lock_and_get($lock_file);
         %status = %$status_ref;
         $status{$host} = "ready";
         $status{$hostname} = "ready";
         write_and_close($LOCK, \%status);

      }else{
         $status{$hostname} = "searching";
         write_and_close($LOCK, \%status);
         select(undef, undef, undef, 1);
         ($LOCK, $status_ref) = lock_and_get($lock_file);
         %status = %$status_ref;
      }
   }
}else{
   while(1){
      if($status{$hostname} eq "ready" || 
         $status{$hostname} eq "uploading"){
         if(not -e $tmpdir){
            delete $status{$hostname};
            write_and_close($LOCK, \%status);
            die "$tmpdir has been deleted!\n";
         }
         unlock_and_close($LOCK);
         last;
      }
      unlock_and_close($LOCK);
      select(undef, undef, undef, 1);
      ($LOCK, $status_ref) = lock_and_get($lock_file);
      %status = %$status_ref;
   }
}


print STDOUT "$tmpdir\n";


####################### sub routines ########################
sub lock_and_get{
   @_ != 1 && die "Error arguements(@_) to lock_and_get\n";

   my $lock_file = $_[0];

   open($fd, "+<$lock_file") || die "fail open $lock_file\n";
   until(flock($fd, 6)){
      select(undef, undef, undef, 0.2);
   }
   my %data = ();
   while(<$fd>){
      $_ =~ s/\R//g;
      my @array = split(' ', $_);
      $data{$array[0]} = $array[1];
   }

   return ($fd, \%data);
}

sub write_and_close{
   @_ != 2 && die "Error arguements(@_) to unlock\n";

   my ($fd, $data_ref) = @_;
   my %data = %$data_ref;

   seek($fd, 0, 0);
   foreach my $key (sort keys %data){
      print $fd "$key $data{$key}\n";
   }
   truncate($fd, tell($fd));

   flock($fd, 8) || die "failed unlocking $fd\n";
   close($fd);

   return;
}

sub unlock_and_close{
   @_ != 1 && die "Error arguements(@_) to unlock\n";

   my $fd = $_[0];

   flock($fd, 8) || die "failed unlocking $fd\n";
   close($fd);

   return;
}
