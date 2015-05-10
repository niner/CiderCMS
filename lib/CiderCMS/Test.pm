package CiderCMS::Test;

use strict;
use warnings;
use utf8;

use Test::More;
use Exporter;
use FindBin qw($Bin); ## no critic (ProhibitPackageVars)
use File::Copy qw(copy);
use File::Path qw(remove_tree);
use File::Slurp qw(write_file);
use English '-no_match_vars';

use base qw(Exporter);

=head1 NAME

CiderCMS::Test - Infrastructure for test files

=head1 SYNOPSIS

use CiderCMS::Test qw(test_instance => 1, mechanize => 1);

=head1 DESCRIPTION

This module contains methods for simplifying writing of tests.
It supports creating a test instance on import and initializing $mech.

=head1 EXPORTS

=head2 $instance

The randomly created name of the test instance.

=head2 $c

A CiderCMS object for accessing the test instance.

=head2 $model

A CiderCMS::Model::DB object.

=head2 $mech

A Test::WWW::Mechanize::Catalyst object for conducting UI tests.

=cut

## no critic (ProhibitReusedNames)
our ($instance, $c, $model, $mech);          ## no critic (ProhibitPackageVars)
our @EXPORT = qw($instance $c $model $mech); ## no critic (ProhibitPackageVars, ProhibitAutomaticExportation)
sub import {
    my ($self, %params) = @_;

    if ($params{test_instance}) {
        ($instance, $c, $model, $mech) = $self->setup_test_environment(%params);
        __PACKAGE__->export_to_level(1, $self, @EXPORT);
    }

    return;
}

=head1 METHODS

=head2 init_mechanize()

=cut

sub init_mechanize {
    my ($self) = @_;

    my $result = eval q{use Test::WWW::Mechanize::Catalyst 'CiderCMS'}; ## no critic (ProhibitStringyEval)
    plan skip_all => "Test::WWW::Mechanize::Catalyst required: $EVAL_ERROR"
        if $EVAL_ERROR;

    require WWW::Mechanize::TreeBuilder;
    require HTML::TreeBuilder::XPath;

    my $mech = Test::WWW::Mechanize::Catalyst->new;

    WWW::Mechanize::TreeBuilder->meta->apply(
        $mech,
        tree_class => 'HTML::TreeBuilder::XPath',
    );

    return $mech;
}

=head2 context

Returns a $c object for tests.

=cut

sub context {
    my ($self) = @_;

    require Catalyst::Test;
    Catalyst::Test->import('CiderCMS');
    my ($res, $c) = ctx_request('/system/create');
    delete $c->stash->{$_} foreach keys %{ $c->stash };

    return $c;
}

=head2 setup_instance($instance, $c, $model)

=cut

sub setup_instance {
    my ($self, $instance, $c, $model) = @_;

    $model->create_instance($c, {id => $instance, title => 'test instance'});

    return;
}

=head2 setup_test_environment(%params)

%params may contain mechanize => 1 for optionally initializing $mech

=cut

sub setup_test_environment {
    my ($self, %params) = @_;

    $ENV{ CIDERCMS_CONFIG_LOCAL_SUFFIX } = 'test';

    my $instance = 'test' . int(10 + rand() * 99989) . '.example';

    my $mech;
    $mech = $self->init_mechanize if $params{mechanize};

    my $c     = $self->context;
    my $model = $c->model('DB');

    $self->setup_instance($instance, $c, $model);

    return ($instance, $c, $model, $mech);
}

=head2 populate_types(%types)

=cut

sub populate_types {
    my ($self, $types) = @_;

    while (my ($type, $data) = each %$types) {
        $model->create_type(
            $c,
            {
                id           => $type,
                name         => $data->{name} // $type,
                page_element => $data->{page_element} // 0,
            }
        );

        my $i = 0;
        foreach my $attr (@{ $data->{attributes} }) {
            $model->create_attribute($c, {
                type          => $type,
                id            => $attr->{id},
                name          => $data->{name} // ucfirst($attr->{id}),
                sort_id       => $i++,
                data_type     => $attr->{data_type} // ucfirst($attr->{id}),
                repetitive    => $attr->{repetitive} // 0,
                mandatory     => $attr->{mandatory}  // 0,
                default_value => $attr->{default_value},
            });
        }

        if ($data->{template}) {
            copy
                "$Bin/test.example/templates/types/$data->{template}",
                "$Bin/../root/instances/$instance/templates/types/$type.zpt"
                or die "could not copy template $data->{template}";
        }
    }
}

=head3 std_folder_type

=cut

sub std_folder_type {
    return folder => {
        name       => 'Folder',
        attributes => [
            {
                id            => 'title',
                data_type     => 'Title',
                mandatory     => 1,
            },
            {
                id            => 'children',
                data_type     => 'Object',
                mandatory     => 0,
                repetitive    => 1,
            },
        ],
    };
}

=head3 std_textfield_type

=cut

sub std_textfield_type {
    return textfield => {
        name         => 'Textfield',
        page_element => 1,
        attributes => [
            {
                id            => 'text',
                data_type     => 'Text',
                mandatory     => 1,
            },
        ],
    };
}

sub write_template {
    my ($self, $file, $contents) = @_;

    write_file("$Bin/../root/instances/$instance/templates/types/$file.zpt", $contents);
}

=head2 END

On process exit, the test instance will be cleaned up again.

=cut

END {
    if ($instance and $model) {
        $model->dbh->do(q{set client_min_messages='warning'});
        $model->dbh->do(qq{drop schema if exists "$instance" cascade});
        $model->dbh->do(q{set client_min_messages='notice'});
        remove_tree("$Bin/../root/instances/$instance");
    }
    undef $mech;
}

1;
