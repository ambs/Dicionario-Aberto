#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../.local/perl5lib";

use DA::API;
DA::API->to_app;
