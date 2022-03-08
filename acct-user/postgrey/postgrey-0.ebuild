# Copyright 2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit acct-user

DESCRIPTION="user for postgrey daemon"

ACCT_USER_ID=360
ACCT_USER_HOME="/var/spool/postfix/postgrey"
ACCT_USER_HOME_OWNER="postgrey:postgrey"
ACCT_USER_HOME_PERMS='0770'
ACCT_USER_GROUPS=( postgrey )

acct-user_add_deps
