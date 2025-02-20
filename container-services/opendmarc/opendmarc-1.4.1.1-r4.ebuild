# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="Open source DMARC implementation"
HOMEPAGE="http://www.trusteddomain.org/opendmarc/"
#SRC_URI="https://github.com/trusteddomainproject/OpenDMARC/archive/rel-${PN}-${PV//./-}.tar.gz -> ${P}.tar.gz"

LICENSE="BSD"
KEYWORDS="~alpha amd64 arm ~arm64 hppa ~ia64 ppc ppc64 sparc x86"
#IUSE="spf +reports static-libs systemd"
SLOT="0"

RDEPEND="
	|| ( app-containers/podman app-containers/docker )
	app-containers/container-init-scripts
	acct-group/milter
	acct-user/milter
	!mail-filter/opendmarc"

S="${WORKDIR}"

src_prepare() {
	local f

	for f in opendmarc.initd_common; do
		sed \
			-e "s#@PVR@#${PVR}#" \
			"${FILESDIR}/${f}" > "${T}/${f%.in}" || die
	done

	default
}

src_install() {
	default

	newinitd "${T}"/opendmarc.initd_common opendmarc
	newconfd "${FILESDIR}"/opendmarc.confd opendmarc

	insinto /etc/opendmarc

	# create config file
	doins "${FILESDIR}"/opendmarc.conf

	exeinto /etc/cron.daily
	doexe "${FILESDIR}"/update-opendmarc-suffix-list

	touch "${ED}"/etc/opendmarc/ignore.hosts
}

pkg_postinst() {
	einfo "The following container mounts are required for ${PN}:"
	einfo
	einfo "    /etc/${PN}"
	einfo "    /var/run/${PN}"
	einfo
	einfo "Please ensure that these directories are mounted when starting the ${PN} container"
}
