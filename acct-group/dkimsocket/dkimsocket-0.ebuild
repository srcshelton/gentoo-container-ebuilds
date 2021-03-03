# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit acct-group

# Now clashes with acct-group/chronograf :(
DEPEND="!acct-group/chronograf"
RDEPEND="${DEPEND}"

DESCRIPTION="Group used to share the OpenDKIM socket"
ACCT_GROUP_ID=344
