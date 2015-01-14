#!perl

use strict;
use warnings;

use Irssi qw(
  print
  signal_add
  settings_add_str
  settings_add_bool
  settings_add_int
  settings_get_str
  settings_get_int
  command
);
use vars qw($VERSION %IRSSI);

$VERSION = "0.01";
%IRSSI = (
    authors	=> 'Fernando Vezzosi',
    contact	=> 'irssi@repnz.net',
    name	=> '',
    description	=> '',
    license	=> 'Public Domain',
);

my $last_sent_time=0;

sub do_relay_message {
  my $text = shift;

  open CMD, '| ' . settings_get_str('hlrelay_command');
  print CMD $text . "\n";
  close CMD;
  print "Relayed message [retval=$?]";
}

sub sig_printtext {
  my ($dest, $text, $stripped) = @_;
  my $thistime=time;
  my $ign_pattern=settings_get_str('hlrelay_ignore_pattern');

  return unless (
     ($dest->{level} & (MSGLEVEL_HILIGHT | MSGLEVEL_MSGS)) && # it is an hilight
     ($dest->{level} & MSGLEVEL_NOHILIGHT) == 0 &&
     (settings_get_bool('hlrelay_only_when_away') ? $dest->{server}->{usermode_away} == 1 : 1)
  );

  my $min_seconds = settings_get_int('hlrelay_delay_min');
  return if # too little time passed? return!
    $min_seconds && ( $thistime - $last_sent_time <= $min_seconds );

  return if # we want to ignore this message
    (($ign_pattern ne '') and ($text =~ m/$ign_pattern/));

  $last_sent_time = $thistime;
  do_relay_message($stripped);
}

signal_add('print text', 'sig_printtext');

settings_add_bool('highlight-relay', 'hlrelay_only_when_away', 0);
settings_add_int ('highlight-relay', 'hlrelay_delay_min', 0);
settings_add_str ('highlight-relay', 'hlrelay_ignore_pattern', '');
settings_add_str ('highlight-relay', 'hlrelay_command', '');

command("/set hlrelay_");
