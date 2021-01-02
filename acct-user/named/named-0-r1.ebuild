# Copyright 2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit acct-user

DESCRIPTION="user for Berkeley Internet Name Daemon"

ACCT_USER_ID=40
ACCT_USER_HOME=/etc/bind
ACCT_USER_HOME_OWNER=root:named
ACCT_USER_HOME_PERMS='0750'
ACCT_USER_GROUPS=( named )

acct-user_add_deps
