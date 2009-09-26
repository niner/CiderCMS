package CiderCMS::Model::DB;

use strict;
use warnings;

use base 'Catalyst::Model::DBI';
use File::Slurp qw(read_file);
use Carp qw(croak);

use CiderCMS::Object;

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

=head2 create_instance($c, {id => 'test.example', title => 'Testsite'})

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

    $dbh->do(qq(create schema "$data->{id}")) or croak qq(could not create schema "$data->{id}");
    $dbh->do(qq(set search_path="$data->{id}",public)) or croak qq(could not set search path "$data->{id}",public!?);

    $dbh->do(scalar read_file($c->config->{root} . '/initial_schema.sql')) or croak 'could not import initial schema';

    $self->create_type($c, {id => 'site', name => 'Site', page_element => 0});
    $self->create_attribute($c, {type => 'site', id => 'title', name => 'Title', sort_id => 0, data_type => 'String', repetitive => 0, mandatory => 1, default_value => ''});

    $c->stash({instance => $data->{id}});
    $self->initialize($c);

    CiderCMS::Object->new({c => $c, type => 'site', data => {title => $data->{title}}})->insert;

    return;
}

=head2 initialize($c)

Fetches type and attribute information from the DB and puts it on the stash:
    types => {
        type1 => {
            id           => 'type1',
            name         => 'Type 1',
            page_element => 0,
            attributes   => [
                # same as {attrs}{attr1}
            ],
            attrs        => {
                attr1 => {
                    type          => 'type1',
                    class         => 'CiderCMS::Attribute::String',
                    id            => 'attr1',
                    name          => 'Attribute 1',
                    sort_id       => 0,
                    data_type     => 'String',
                    repetitive    => 0,
                    mandatory     => 1,
                    default_value => '',
                },
            },
        },
    }

Should be called after every change to the schema.

=cut

sub initialize {
    my ($self, $c) = @_;

    my $dbh = $self->dbh;
    my $instance = $c->stash->{instance};
    $dbh->do(qq(set search_path="$instance",public)) or croak qq(could not set search path "$instance",public);

    my $types = $dbh->selectall_arrayref('select * from sys_types', {Slice => {}});
    my $attrs = $dbh->selectall_arrayref('select * from sys_attributes order by sort_id', {Slice => {}});

    my %types = map { $_->{id} => { %$_, attributes => [], attr => {} } } @$types;

    foreach (@$attrs) {
        push @{ $types{$_->{type}}{attributes} }, $_;
        $types{$_->{type}}{attr}{$_->{id}} = $_;

        $_->{class} = "CiderCMS::Attribute::$_->{data_type}";
    }

    $c->stash({
        types => \%types,
    });

    return;
}

=head2 create_type($c, {id => 'type1', name => 'Type 1', page_element => 0})

Creates a new type by creating a database table for it and an entry in the sys_types table.

=cut

sub create_type {
    my ($self, $c, $data) = @_;

    my $dbh = $self->dbh;
    my $id = $data->{id};

    $dbh->do('begin');

    $dbh->do('insert into sys_types (id, name, page_element) values (?, ?, ?)', undef, $id, $data->{name}, $data->{page_element});

    $dbh->do(qq/create table "$id" (id integer not null primary key, parent integer, sort_id integer default 0 not null, type varchar not null references sys_types (id) default '$id', changed timestamp not null default now(), tree_changed timestamp not null default now(), active_start timestamp, active_end timestamp, dcid varchar)/);

    $dbh->do(qq/create trigger "${id}_bi" before insert on "$id" for each row execute procedure sys_objects_bi()/);
    $dbh->do(qq/create trigger "${id}_bu" before update on "$id" for each row execute procedure sys_objects_bu()/);
    $dbh->do(qq/create trigger "${id}_ad" after  delete on "$id" for each row execute procedure sys_objects_ad()/);

    $dbh->do('commit');

    return;
}

=head2 create_attribute($c, {type => 'type1', id => 'attr1', name => 'Attribute 1', sort_id => 0, data_type => 'String', repetitive => 0, mandatory => 1, default_value => ''})

Adds a new attribute to a type by creating the column in the type's table and an entry in the sys_attributes table.

=cut

my %data_types = (String => 'varchar');

sub create_attribute {
    my ($self, $c, $data) = @_;

    my $dbh = $self->dbh;

    $dbh->do('begin');

    $dbh->do('insert into sys_attributes (type, id, name, data_type, repetitive, mandatory, default_value) values (?, ?, ?, ?, ?, ?, ?)', undef, @$data{qw(type id name data_type repetitive mandatory default_value)});

    if (exists $data_types{$data->{data_type}}) {
        my $query = qq/alter table "$data->{type}" add column "$data->{id}" $data_types{$data->{data_type}}/;
        $query .= ' not null' if $data->{mandatory};
        $query .= ' default ' . $dbh->quote($data->{default}) if defined $data->{default} and $data->{default} ne '';
        $dbh->do($query);
    }

    $dbh->do('commit');

    return;
}

=head2 insert_object($c, $object)

Inserts a CiderCMS::Object into the database.

=cut

my @sys_object_columns = qw(id parent sort_id type active_start active_end dcid);

sub insert_object {
    my ($self, $c, $object) = @_;

    my $dbh = $self->dbh;
    my $type = $object->{type};
    
    my ($columns, $values) = $object->get_dirty_columns(); # DBIx::Class::Row yeah

    my $insert_statement = qq{insert into "$type" (} . join (q{, }, map qq{"$_"}, @sys_object_columns, @$columns) . ') values (' . join (q{, }, map '?', @sys_object_columns, @$columns) . ')';

    if (my $retval = $dbh->do($insert_statement, undef, (map $object->{$_}, @sys_object_columns), @$values)) {
        $object->{id} = $dbh->last_insert_id(undef, undef, 'sys_object', undef, {sequence => 'sys_object_id_seq'});
        return $retval;
    }
    else {
        croak $dbh->errstr;
    }
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
