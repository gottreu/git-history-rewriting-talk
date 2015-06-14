#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

my $slides = do {
  local $/ = undef;
  open my $s, "<", "slidey.md";
  <$s>; 
};

open my $in, "<", "talk-via-file.html.template";
open my $out, ">", "talk-via-file.html";

while(<$in>) {
  s/\s*#THIS_BIT_HERE\n/$slides/;
  print $out $_;
}
