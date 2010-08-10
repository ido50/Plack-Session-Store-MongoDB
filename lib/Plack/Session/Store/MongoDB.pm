package Plack::Session::Store::MongoDB;

use warnings;
use strict;
use parent 'Plack::Session::Store';
use MongoDB;
use Carp;

use Plack::Util::Accessor qw/host port db_name coll_name db/;

=head1 NAME

Plack::Session::Store::MongoDB - MongoDB based session store for Plack apps.

=head1 SYNOPSIS

	use Plack::Builder;
	use Plack::Middleware::Session;
	use Plack::Session::Store::MongoDB;

	my $app = sub {
		return [ 200, [ 'Content-Type' => 'text/plain' ], [ 'Hello Foo' ] ];
	};

	builder {
		enable 'Session',
		store => Plack::Session::Store::MongoDB->new(
			db_name => 'myapp',
			coll_name => 'myapp_sessions',	# defaults to 'session'
			host => 'mongodb.myhost.com',	# defaults to 'localhost'
			port => 27017			# this is the default
		);
		$app;
	};

=head1 DESCRIPTION

This module implements a L<MongoDB> storage for session data. This has the
advantage of being a simple (no need to generate a database scheme or even
create the necessary database/collections), yet powerful backend.

It requires, of course, a running MongoDB daemon to work with.

=head1 METHODS

=head2 new( %params )

Creates a new instance of this module. Requires a hash of parameters
containing 'db_name' with the name of the MongoDB database to use,
and optionally a 'host' parameter with the hostname of the server where
the MongoDB daemon is running (will default to 'localhost'), a 'port'
parameter defining the port where the MongoDB daemon is listening (will
default to 27017, the default MongoDB port), and a 'coll_name' parameter
with the name of the collection in which sessions will be stored (will
default to 'sessions').

=cut

sub new {
	my ($class, %params) = @_;

	croak "You must provide the name of the database to use (parameter 'db_name')."
		unless $params{db_name};

	# default values for parameters
	$params{host} ||= 'localhost';
	$params{port} ||= 27017;
	$params{coll_name} ||= 'sessions';

	# initiate connection to the MongoDB backend
	$params{db} = MongoDB::Connection->new(host => $params{host}, port => $params{port})->get_database($params{db_name});

	return bless \%params, $class;
}

=head2 fetch( $session_id )

Fetches a session object from the database.

=cut

sub fetch {
	my ($self, $session_id) = @_;

	$self->db->get_collection($self->coll_name)->find_one({ _id => $session_id });
}

=head2 store( $session_id, \%session_obj )

Stores a session object in the database. If a database error occurs when
attempting to store the session, this method will die.

=cut

sub store {
	my ($self, $session_id, $session_obj) = @_;

	$session_obj->{_id} = $session_id;

	$self->db->get_collection($self->coll_name)->insert($session_obj, { safe => 1 })
		|| croak "Failed inserting session object to MongoDB database: ".$self->db->last_error;
}

=head2 remove( $session_id )

Removes the session object from the database. If a database error occurs
when attempting to remove the session, this method will generate a warning.

=cut

sub remove {
	my ($self, $session_id) = @_;

	$self->db->get_collection($self->coll_name)->remove({ _id => $session_id }, { just_one => 1, safe => 1 })
		|| carp "Failed removing session object from MongoDB database: ".$self->db->last_error;
}

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50 dot net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-plack-session-store-mongodb at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Plack-Session-Store-MongoDB>. I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Plack::Session::Store::MongoDB

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Plack-Session-Store-MongoDB>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Plack-Session-Store-MongoDB>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Plack-Session-Store-MongoDB>

=item * Search CPAN

L<http://search.cpan.org/dist/Plack-Session-Store-MongoDB/>

=back

=head1 ACKNOWLEDGEMENTS

Daisuke Maki, author of L<Plack::Session::Store::DBI>, on which this
module is based.

Tests adapted from the L<Plack::Middleware::Session> distribution.

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Ido Perlmuter.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
