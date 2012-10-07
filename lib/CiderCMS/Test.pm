package CiderCMS::Test;

use strict;
use warnings;
use utf8;

use Test::More;
use Exporter;
use FindBin qw($Bin);
use File::Path qw(remove_tree);

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

our ($instance, $c, $model, $mech);
our @EXPORT = qw($instance $c $model $mech);
sub import {
    my ($self, %params) = @_;

    if ($params{test_instance}) {
        ($instance, $c, $model, $mech) = $self->setup_test_environment(%params);
        __PACKAGE__->export_to_level(1, $self, @EXPORT);
    }
}

=head1 METHODS

=head2 init_mechanize()

=cut

sub init_mechanize {
    my ($self) = @_;

    eval "use Test::WWW::Mechanize::Catalyst 'CiderCMS'";
    plan skip_all => "Test::WWW::Mechanize::Catalyst required: $@" if $@;

    require WWW::Mechanize::TreeBuilder;
    require HTML::TreeBuilder::XPath;

    my $mech = Test::WWW::Mechanize::Catalyst->new;

    WWW::Mechanize::TreeBuilder->meta->apply(
        $mech,
        tree_class => 'HTML::TreeBuilder::XPath',
    );

    return $mech;
}

=head2 setup_instance($instance, $c, $model)

=cut

sub setup_instance {
    my ($self, $instance, $c, $model) = @_;

    $model->create_instance($c, {id => $instance, title => 'test instance'});
}

=head2 setup_test_environment(%params)

%params may contain mechanize => 1 for optionally initializing $mech

=cut

sub setup_test_environment {
    my ($self, %params) = @_;

    my $instance = 'test' . int(10 + rand() * 99989) . '.example';

    my $mech;
    $mech = $self->init_mechanize if $params{mechanize};

    my $c     = CiderCMS->new;
    my $model = $c->model('DB');

    $self->setup_instance($instance, $c, $model);

    return ($instance, $c, $model, $mech);
}

=head2 END

On process exit, the test instance will be cleaned up again.

=cut

END {
    if ($instance and $model) {
        $model->dbh->do("set client_min_messages='warning'");
        $model->dbh->do(qq{drop schema if exists "$instance" cascade});
        $model->dbh->do("set client_min_messages='notice'");
        remove_tree("$Bin/../root/instances/$instance");
    }
}

1;
