package DA::Database;

use 5.006;
use strict;
use warnings;

use Scalar::Util qw.blessed.;
use DBI;

=head1 NAME

DA::Database - Module to manage Dicionario-Aberto DB

=head1 SYNOPSIS

    use DA::Database;

    my $dic = DA::Database->new($dbh);

=head1 SUBROUTINES/METHODS

=head2 new

Creates a new Dicionário-Aberto access object.

=cut

sub new {
	my $class = shift;

	my $self = bless {}, $class;

	my $thing = shift;


	if (ref($thing) eq "CODE") {
		$self->{dbh_sub} = $thing;
	}
	elsif (blessed($thing) && $thing->can("prepare")) {
		$self->{dbh} = $thing;
	} 
	else {
		$self->{dbh} = DBI->connect($thing, @_);
	}

	return bless $self, $class;
}

sub dbh {
	my ($self) = shift;

	if (exists($self->{dbh_sub})) {
		return $self->{dbh_sub}->();
	}
	if (exists($self->{dbh})) {
		return $self->{dbh};
	}
	die "no DBH?";
}

sub wotd {
	my ($self) = @_;
	my $sth = $self->dbh->prepare("SELECT `value` FROM `metadata` WHERE `key` = ?");
	$sth->execute('wotd');

	my ($wid) = $sth->fetchrow_array;

	$sth = $self->dbh->prepare(<<"---");
 SELECT `xml` FROM `word` INNER JOIN `revision` 
     ON `word`.`word_id` = `revision`.`word_id`
      AND `word`.`last_revision` = `revision`.`revision_id` 
     WHERE `word`.`word_id` = ?;
---

	$sth->execute($wid);
	my ($xml) = $sth->fetchrow_array;
	return $xml;
}

sub retrieve_news {
	my ($self, %filter) = @_;

	my @where = ();
	if (exists($filter{id}) && $filter{id} =~ /^\d+$/) {
		push @where, "WHERE idnew = $filter{id}"
	}

	if (exists($filter{count}) && $filter{count} =~ /^\d+$/) {
		push @where, "LIMIT $filter{count}"
	}

	push @where, "ORDER BY date DESC";

	my $sql = "SELECT idnew, user, date, title, text FROM new";
	$sql = join(" ", $sql, @where);

	my $sth = $self->dbh->prepare($sql);
	$sth->execute();

	my $news = $sth->fetchall_arrayref({});

	return $news;
}

=head1 AUTHOR

Alberto Simoes, C<< <ambs at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Alberto Simoes.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of DA::Database
