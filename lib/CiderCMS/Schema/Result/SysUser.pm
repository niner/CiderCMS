package CiderCMS::Schema::Result::SysUser;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("sys_users");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "serial",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "password",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("sys_user_pkey", ["id"]);

1;
