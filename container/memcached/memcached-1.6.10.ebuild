# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

#MY_PV="${PV/_rc/-rc}"
#MY_P="${PN}-${MY_PV}"

DESCRIPTION="High-performance, distributed memory object caching system"
HOMEPAGE="http://memcached.org/"
#SRC_URI="https://www.memcached.org/files/${MY_P}.tar.gz
#	https://www.memcached.org/files/old/${MY_P}.tar.gz"

LICENSE="BSD"
KEYWORDS="~alpha amd64 ~arm ~arm64 ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sparc x86 ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos"
#IUSE="debug sasl seccomp selinux slabs-reassign test" # hugetlbfs later
#RESTRICT="!test? ( test )"
SLOT="0"

RDEPEND="
	|| ( app-emulation/podman app-emulation/docker )
	app-emulation/container-init-scripts
	acct-group/memcached
	acct-user/memcached"

S="${WORKDIR}"

src_prepare() {
	local f

	for f in memcached.init2_common; do
		sed \
			-e "s#@PVR@#${PVR}#" \
			"${FILESDIR}/${f}" > "${T}/${f%.in}" || die
	done

	default
}

src_install() {
	newconfd "${FILESDIR}/memcached.confd" memcached
	newinitd "${T}/memcached.init2_common" memcached
}

pkg_postinst() {
	elog "With this version of Memcached Gentoo now supports multiple instances."
	elog "To enable this you should create a symlink in /etc/init.d/ for each instance"
	elog "to /etc/init.d/memcached and create the matching conf files in /etc/conf.d/"
	elog "Please see Gentoo bug #122246 for more info"

	einfo "The following container mounts are required for ${PN}:"
	einfo
	einfo "    /var/run/${PN}"
	einfo
	einfo "Please ensure that these directories are mounted when starting the ${PN} container"
}
