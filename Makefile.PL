# $Id: Makefile.PL,v 1.2 2002/12/29 15:36:54 vek Exp $

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'SETI::WebStats',
    'VERSION_FROM'	=> 'WebStats.pm', # finds $VERSION
    'PREREQ_PM'		=> { LWP::UserAgent => 0,
                         XML::Simple => 0 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'WebStats.pm', # retrieve abstract from module
	   AUTHOR     => 'Kevin Spencer <vek@perlmonk.org>') : ()),
);
