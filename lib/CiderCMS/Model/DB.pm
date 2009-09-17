package CiderCMS::Model::DB;

use strict;
use base 'Catalyst::Model::DBI';
use File::Slurp qw(read_file);

__PACKAGE__->config(
    dsn           => 'dbi:Pg:dbname=cidercms',
    user          => '',
    password      => '',
    options       => {
        pg_enable_utf8 => 1,
        quote_char     => '"',
        name_sep       => '.',
    },
);

=head1 NAME

CiderCMS::Model::DB - DBI Model Class

=head1 METHODS

=head2 create_instance($c, {id => 'test.example', name => 'Testsite'})

Creates a new instance including schema and instance directory

=cut

sub create_instance {
    my ($self, $c, $data) = @_;

    my $dbh = $self->dbh;

    my $instance_path = $c->config->{root} . '/instances/' . $data->{id}; 

    mkdir $instance_path;
    mkdir "$instance_path/static";
    mkdir "$instance_path/templates";
    mkdir "$instance_path/templates/layout";
    mkdir "$instance_path/templates/content";

    $dbh->do(qq(create schema "$data->{id}")) or die qq(could not create schema "$data->{id}");
    $dbh->do(qq(set search_path="$data->{id}",public)) or die qq(could not set search path "$data->{id}",public!?);

    $dbh->do(scalar read_file($c->config->{root} . '/initial_schema.sql')) or die 'could not import initial schema';
}

=head1 SYNOPSIS

See L<CiderCMS>

=head1 DESCRIPTION

DBI Model Class.

=head1 AUTHOR

Stefan Seifert

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
