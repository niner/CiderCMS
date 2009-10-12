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
    $self->create_attribute($c, {type => 'site', id => 'children', name => 'Children', sort_id => 1, data_type => 'Object', repetitive => 1, mandatory => 0, default_value => ''});

    $c->stash({instance => $data->{id}});
    $self->initialize($c);

    CiderCMS::Object->new({c => $c, type => 'site', dcid => '', data => {title => $data->{title}}})->insert;

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

=head2 traverse_path($c, $path)

Traverses a path (given as hashref) and returns the objects found

=cut

sub traverse_path {
    my ($self, $c, $path) = @_;

    my @objects;
    my $object;
    my $dbh = $self->dbh;

    foreach (@$path) {
        my $may_be_id = /\A\d+\z/;
        $object = $dbh->selectrow_hashref(
            'select id, type from sys_object where parent '
            . (@objects ? ' = ?' : ' is null')
            . ' and ' . ($may_be_id ? '(id=? or dcid=?)' : 'dcid=?'),
            undef,
            (@objects ? $objects[-1]->{id} : ()),
            $_,
            ($may_be_id ? $_ : ()),
        ) or die qq{node "$_" not found};

        push @objects, $self->inflate_object($c, $object);
    }

    return @objects;
}

=head2 get_object($c, $id)

Returns a content object for the given ID.

=cut

#TODO great point to add some caching
sub get_object {
    my ($self, $c, $id) = @_;

    return $self->inflate_object($c, $self->dbh->selectrow_hashref('select id, type from sys_object where id = ?', undef, $id));
}

=head2 inflate_object($c, $object)

Takes a stub object (consisting of id and type information) and inflates it to a full blown and initialized CiderCMS::Object.

=cut

sub inflate_object {
    my ($self, $c, $object) = @_;

    $object = $self->dbh->selectrow_hashref(qq(select * from "$object->{type}" where id=?), undef, $object->{id});

    return CiderCMS::Object->new({c => $c, id => $object->{id}, type => $object->{type}, dcid => $object->{dcid}, parent => $object->{parent}, sort_id => $object->{sort_id}, data => $object});
}

=head2 object_children

Returns the children of an object as list in list context and as array ref in scalar context.

=cut

sub object_children {
    my ($self, $c, $object) = @_;

    my @children = map {
        $self->inflate_object($c, $_)
    } @{ $self->dbh->selectall_arrayref('select id, type from sys_object where parent = ?', {Slice => {}}, $object->{id}) };

    return wantarray ? @children : \@children;
}

=head2 create_type($c, {id => 'type1', name => 'Type 1', page_element => 0})

Creates a new type by creating a database table for it and an entry in the sys_types table.

=cut

sub create_type {
    my ($self, $c, $data) = @_;

    my $dbh = $self->dbh;
    my $id = $data->{id};
    $data->{page_element} ||= 0;

    $dbh->do('begin');

    $dbh->do('insert into sys_types (id, name, page_element) values (?, ?, ?)', undef, $id, $data->{name}, $data->{page_element});

    $dbh->do(q/set client_min_messages='warning'/); # avoid the CREATE TABLE / PRIMARY KEY will create implicit index NOTICE
    $dbh->do(qq/create table "$id" (id integer not null, parent integer, sort_id integer default 0 not null, type varchar not null references sys_types (id) default '$id', changed timestamp not null default now(), tree_changed timestamp not null default now(), active_start timestamp, active_end timestamp, dcid varchar)/);
    $dbh->do(q/set client_min_messages='notice'/); # back to full information

    $dbh->do(qq/create trigger "${id}_bi" before insert on "$id" for each row execute procedure sys_objects_bi()/);
    $dbh->do(qq/create trigger "${id}_bu" before update on "$id" for each row execute procedure sys_objects_bu()/);
    $dbh->do(qq/create trigger "${id}_ad" after  delete on "$id" for each row execute procedure sys_objects_ad()/);

    $dbh->do('commit');

    return;
}

=head2 update_type($c, $id, {id => 'type1', name => 'Type 1', page_element => 0})

Updates an existing type.

=cut

sub update_type {
    my ($self, $c, $id, $data) = @_;

    my $dbh = $self->dbh;
    $data->{page_element} ||= 0;

    if ($data->{id} ne $id) {
        $dbh->do('begin'); # can't do a simple update, because that would break foreign key constraints
        $dbh->do('insert into sys_types (id, name, page_element) values (?, ?, ?)', undef, @$data{qw(id name page_element)});
        $dbh->do(qq/update sys_attributes set type = ? where type = ?/, undef, $data->{id}, $id);
        $dbh->do(qq/alter table "$id" rename to "$data->{id}"/);
        $dbh->do(qq/delete from sys_types where id = ?/, undef, $id);
        $dbh->do('commit');
    }
    else {
        $dbh->do('update sys_types set id = ?, name = ?, page_element = ? where id = ?', undef, @$data{qw(id name page_element)}, $id);
    }
}

=head2 create_attribute($c, {type => 'type1', id => 'attr1', name => 'Attribute 1', sort_id => 0, data_type => 'String', repetitive => 0, mandatory => 1, default_value => ''})

Adds a new attribute to a type by creating the column in the type's table and an entry in the sys_attributes table.

=cut

sub create_attribute {
    my ($self, $c, $data) = @_;

    my $dbh = $self->dbh;

    $_ = $_ ? 1 : 0 foreach @$data{qw(mandatory repetitive)};

    $dbh->do('begin');

    $dbh->do('insert into sys_attributes (type, id, name, data_type, repetitive, mandatory, default_value) values (?, ?, ?, ?, ?, ?, ?)', undef, @$data{qw(type id name data_type repetitive mandatory default_value)});

    if (my $data_type = "CiderCMS::Attribute::$data->{data_type}"->db_type) {
        my $query = qq/alter table "$data->{type}" add column "$data->{id}" $data_type/;
        $query .= ' not null' if $data->{mandatory};
        $query .= ' default ' . $dbh->quote($data->{default}) if defined $data->{default} and $data->{default} ne '';
        $dbh->do($query);
    }

    $dbh->do('commit');

    return;
}

=head2 update_attribute($c, {type => 'type1', id => 'attr1', name => 'Attribute 1', sort_id => 0, data_type => 'String', repetitive => 0, mandatory => 1, default_value => ''})

Updates an existing attribute.

=cut

sub update_attribute {
    my ($self, $c, $type, $id, $data) = @_;

    my $dbh = $self->dbh;

    $_ = $_ ? 1 : 0 foreach @$data{qw(mandatory repetitive)};

    $dbh->do('begin');

    $dbh->do('update sys_attributes set id = ?, name = ?, data_type = ?, repetitive = ?, mandatory = ?, default_value = ? where type = ? and id = ?', undef, @$data{qw(id name data_type repetitive mandatory default_value)}, $type, $id);

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

=head2 update_object($c, $object)

Updates a CiderCMS::Object in the database.

=cut

sub update_object {
    my ($self, $c, $object) = @_;

    my $dbh = $self->dbh;
    my $type = $object->{type};
    
    my ($columns, $values) = $object->get_dirty_columns(); # DBIx::Class::Row yeah

    my $update_statement = qq{update "$type" set } . join (q{, }, map qq{"$_" = ?}, @sys_object_columns, @$columns) . ' where id = ?';

    if (my $retval = $dbh->do($update_statement, undef, (map $object->{$_}, @sys_object_columns), @$values, $object->{id})) {
        return $retval;
    }
    else {
        croak $dbh->errstr;
    }
}

=head2 delete_object($c, $object)

Deletes a CiderCMS::Object from the database.

=cut

sub delete_object {
    my ($self, $c, $object) = @_;

    my $dbh = $self->dbh;
    my $type = $object->{type};

    if (my $retval = $dbh->do(qq{delete from "$type" where id = ?}, undef, $object->{id})) {
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
