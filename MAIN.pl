#!/usr/local/bin/perl
use utf8;
use 5.014;
use strict;
use warnings;
use LWP::UserAgent;
use HTTP::Request::Common;
use JSON;
use Data::Dumper; 
use English qw( -no_match_vars );
use Marpa::R2;
use My_Actions;
use My_Grammar;
use Encode;
#POST REQUEST##############################################2

require LWP::UserAgent;
my $ua = LWP::UserAgent->new;
my $req = POST 'http://localhost:8081/:marpa/getGrammar?=';    
$req->header( 'Content-Type' => 'application/json' );
$req->content( '{"a" : "b"}' );

my $res = $ua->request($req);

my $ref = decode_json($res->decoded_content);
my $dsl = "";
foreach (@$ref) {
	$dsl = $dsl . $_ . "\n";
}

# print $dsl;
############################################################
############################################################


#Initialize grammar#
# my $grammar = Marpa::R2::Scanless::G->new( { source => \$My_Grammar::dsl } );
my $grammar = Marpa::R2::Scanless::G->new( { source => \$dsl } );
my $recce = Marpa::R2::Scanless::R->new(
    { grammar => $grammar, semantics_package => 'My_Actions' } );

#Get input from file#
my $input_file = "input.omdoc";
open( my $input_fh, "<", $input_file ) || die "Can't open $input_file: $!";
my $input = join('', <$input_fh>);
#print "Grammar input:\n" . $input . "\n";

#Feed the input to the grammar#
my $length = length $input;
my $start = 0; #default - zero 
my $pos = $recce->read( \$input, $start, $length - $start );
my $actual_events = [];
my %predicted = ();

READ: while (1) {
 
  my @current_events = ();
  EVENT:
  for my $event ( @{ $recce->events() } ) {
    my ($name) = @{$event};
    push @current_events, $name;
  }
 
  for (@current_events) {
    if (!/^predicted_/) { 
      push @$actual_events, [$predicted{$_},$pos, $_];
      delete $predicted{$_};
    }
  }
  for (@current_events) {
    if (/^predicted_/) {
      s/^predicted_//;
      if (!defined($predicted{$_})) {
        $predicted{$_} = $pos;
      }
    }
  }

  last READ if $pos >= $length;
  eval {$pos = $recce->resume(); };
  last READ if $@;
} ## end READ: while (1)

my $value_ref = $recce->value();
if ( not defined $value_ref ) {
  die "No parse\n";
}
my $actual_value = ${$value_ref};
print "Actual value: $actual_value\n";
print "Actual events: ",Dumper($actual_events);


