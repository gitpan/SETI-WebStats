package SETI::WebStats;

use Carp qw(croak);
use LWP::UserAgent;
use XML::Simple;
use strict;
use warnings;
use vars qw($VERSION);

$VERSION = '1.00';

use constant URL =>
	"http://setiathome.sol.berkeley.edu/fcgi-bin/fcgi?cmd=user_xml&email=%s";

sub new {
	my ($class, $emailAddr) = @_;
	if (! $emailAddr) {
		croak("SETI::WebStats: no email address given.");
		return;
	}
	my $self = {};
	$self->{url}     = sprintf(URL, $emailAddr);
	$self->{version} = $VERSION;
	bless $self, $class;
	if (! $self->_getStats) {
		croak("SETI::WebStats: No response from server.");
		return;
	}
	if (! $self->_isValidAccount) {
		croak("SETI::WebStats: $emailAddr is not a valid SETI\@home account.");
		return;
	}
	$self->_parseXML;
	return $self;
}

####################
# UserInfo methods #
####################

sub userInfo {
	my $self = shift;
	return $self->{data}->{userinfo};
}

sub userTime {
	my $self = shift;
	return $self->{data}->{userinfo}->{usertime};
}

sub aveCpu {
	my $self = shift;
	return $self->{data}->{userinfo}->{avecpu};
}

sub numResults {
	my $self = shift;
	return $self->{data}->{userinfo}->{numresults};
}

sub regDate {
	my $self = shift;
	return $self->{data}->{userinfo}->{regdate};
}

sub profileURL {
	my $self = shift;
	if ($self->{data}->{userinfo}->{userprofile}) {
		return $self->{data}->{userinfo}->{userprofile}->{a}->{href};
	} else {
		return "No URL";
	}
}

sub resultsPerDay {
	my $self = shift;
	return $self->{data}->{userinfo}->{resultsperday};
}

sub lastResultTime {
	my $self = shift;
	return $self->{data}->{userinfo}->{lastresulttime} || 0;
}

sub cpuTime {
	my $self = shift;
	return $self->{data}->{userinfo}->{cputime};
}

sub name {
	my $self = shift;
	if (ref $self->{data}->{userinfo}->{name}) {
		return $self->{data}->{userinfo}->{name}->{a}->{content};
	} else {
		return $self->{data}->{userinfo}->{name};
	}
}

sub homePage {
	my $self = shift;
	if (ref $self->{data}->{userinfo}->{name}) {
		if ($self->{data}->{userinfo}->{name}->{a}->{href}) {
			return $self->{data}->{userinfo}->{name}->{a}->{href};
		} else {
			return "No Home Page";
		}
	} else {
		return "No Home Page";
	}
}

####################
# RankInfo methods #
####################

sub rankInfo {
	my $self = shift;
	return $self->{data}->{rankinfo};
}

sub haveSameRank {
	my $self = shift;
	return $self->{data}->{rankinfo}->{num_samerank};
}

sub totalUsers {
	my $self = shift;
	return $self->{data}->{rankinfo}->{ranktotalusers};
}

sub rankPercent {
	my $self = shift;
	return (100 - $self->{data}->{rankinfo}->{top_rankpct});
}

sub rank {
	my $self = shift;
	return $self->{data}->{rankinfo}->{rank};
}

#####################
# GroupInfo methods #
#####################

sub groupInfo {
	my $self = shift;
	return $self->{data}->{groupinfo}->{a};
}

sub groupName {
	my $self = shift;
	if ($self->{data}->{groupinfo}->{group}) {
		return $self->{data}->{groupinfo}->{group}->{a}->{content};
	}
}

sub groupUrl {
	my $self = shift;
	if ($self->{data}->{groupinfo}->{group}) {
		return $self->{data}->{groupinfo}->{group}->{a}->{href};
	}
}

sub url {
	my $self = shift;
	return $self->{url};
}

#################
# Debug methods #
#################

sub version {
	my $self = shift;
	return $self->{version};
}

sub xml {
	my $self = shift;
	return $self->{xml};
}

###################
# Private methods #
###################

sub _getStats {
	my $self = shift;
	my $ua   = LWP::UserAgent->new;
	$ua->agent("SETI::WebStats/$VERSION " . $ua->agent);
	my $req  = HTTP::Request->new('GET', $self->{url});
	my $resp = $ua->request($req);
	return if (! $resp->is_success);
	my $xml  = $resp->content;
	$self->{xml} = $resp->content;
}

sub _isValidAccount {
	my $self = shift;
	return $self->{xml} =~ /No user/ ? 0 : 1;
}

sub _parseXML {
	my $self = shift;
	local ($^W) = 0; # silence XML::SAX::Expat
	$self->{data} = XMLin($self->{xml});
	local ($^W) = 1;
}

1;
__END__

=head1 NAME

SETI::WebStats - Gather SETI@home statistics from the SETI@home web server

=head1 SYNOPSIS

  use SETI::WebStats;

  my $emailAddr  = "foo\@bar.org";
  my $seti       = SETI::WebStats->new($emailAddr);

  my $ranking    = $seti->rank;
  my $unitsProcd = $seti->numResults;

  my $userInfo   = $seti->userInfo;
  for (keys(%$userInfo)) {
     print $_, "->", $userInfo->{$_}, "\n";
  }
  

=head1 DESCRIPTION

A simple Perl interface to the SETI@home web server.  The C<SETI::WebStats> module queries the SETI@home web server to retrieve user statistics.  The data availible from the server is similar to that displayed on the C<Individual User Statistics> web page.  In order to query the server, you will need a valid SETI@home account i.e e-mail address.  At this time only user statistics are availible.  A later version might incorporate country/group statistics also.

=head1 METHODS

=head2 new

This returns the statistics object.  It takes a mandatory e-mail address as it's only argument:

  my $stats = SETI::WebStats->new($emailAddr);

The C<new> method will query the the SETI@home server and parse the retrieved XML via two internal methods C<_getStats> and C<_parseXML>.

=head2 userInfo

The C<userInfo> method will return a hash reference of user information:

  my $userInfo = $stats->userInfo;

The hash reference looks like this:

  $userInfo = {
	usertime       => '3.530 years',
	avecpu         => '15 hr 54 min 36.3 sec',
	numresults     => '670',
	regdate        => 'Fri May 28 20:28:45 1999',
	resultsperday  => '0.51',
	lastresulttime => 'Sat Jun  8 03:47:50 2002',
	cputime        => '     1.217 years',
	name           => 'John Doe'};

=head2 rankInfo

The C<rankInfo> method will return a hash reference of rank information:

  my $rankInfo = $stats->rankInfo;

The hash reference looks like this:

  $rankInfo = {
	num_samerank   => '3',
	ranktotalusers => '4152567',
	top_rankpct    => '0.516',
	rank           => '21410'};

=head1 User Methods

Each User statistic can also be accessed individually via the following methods:

=head2 userTime

  my $userTime = $stats->userTime;

=head2 aveCpu

  my $aveCpu = $stats->aveCpu;

=head2 numResults

  my $procd = $stats->numResults;

=head2 regDate

  my $registerDate = $stats->regDate;

=head2 resultsPerDay

  my $dailyResults = $stats->resultsPerDay;

=head2 lastResultTime

  my $lastUnit = $stats->lastResultTime;

=head2 cpuTime

  my $cpuTime = $stats->cpuTime;

=head2 name

  my $accountName = $stats->name;

=head1 Rank Methods

Each Rank statistic can also be accessed individually via the following methods:

=head2 haveSameRank

  my $usersWithSameRank = $stats->haveSameRank;

=head2 totalUsers

  my $totalUsers = $stats->totalUsers;

=head2 rankPercent

  my $percent = $stats->rankPercent;

=head2 rank

  my $rank = $stats->rank;

=head1 TO DO

Needs a little work.  Remove hardcoding of URL.  Add country/group statistics.  Add meaningful tests.  All will be addressed in upcoming releases.

=head1 AUTHOR

Kevin Spencer <vek@{NOSPAM}perlmonk.org>

=head1 SEE ALSO

L<perl>, L<SETI::Stats>, L<http://setiathome.ssl.berkeley.edu>.

=cut
