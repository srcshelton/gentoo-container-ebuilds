# Copyright 2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="Common containers init script for OpenRC"
HOMEPAGE="https://github.com/srcshelton/gentoo-container-ebuilds"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="amd64 arm arm64 x86"

S="${WORKDIR}"

src_install() {
	newinitd "${FILESDIR}"/containers.initd containers
	newinitd "${FILESDIR}"/common.initd _containers_common
	fperms 0644 /etc/init.d/_containers_common
}
