# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="Open source DMARC implementation"
HOMEPAGE="http://www.trusteddomain.org/opendmarc/"
#SRC_URI="https://github.com/trusteddomainproject/OpenDMARC/archive/rel-${PN}-${PV//./-}.tar.gz -> ${P}.tar.gz"

LICENSE="BSD"
SLOT="0/3"  # 1.4 has API breakage with 1.3, yet uses same soname
KEYWORDS="~alpha amd64 arm ~arm64 ~hppa ~ia64 ppc ppc64 sparc x86"
#IUSE="milter +reports spf systemd"
IUSE="milter"

RDEPEND="
	!milter? ( acct-user/opendmarc )
	milter? ( acct-user/milter )
	|| ( app-containers/podman app-containers/docker )
	app-containers/container-init-scripts
	!mail-filter/opendmarc"

S="${WORKDIR}"

src_prepare() {
	local f=''
	local config_user=''

	config_user="$( usex milter 'milter' 'opendmarc' )"

	for f in opendmarc.initd_common opendmarc.conf opendmarc.confd; do
		sed \
			-e "s#@PVR@#${PVR}#" \
			-e "/command_user/s/milter/${config_user}/" \
			-e "/UserID/s/milter/${config_user}/" \
			-e "/OPENDMARC_/s/milter/${config_user}/" \
			"${FILESDIR}/${f}" > "${T}/${f%.in}" || die
	done

	default
}

src_install() {
	local config_user=''

	config_user="$( usex milter 'milter' 'opendmarc' )"

	default

	newinitd "${T}"/opendmarc.initd_common opendmarc
	newconfd "${T}"/opendmarc.confd opendmarc

	insinto /etc/opendmarc

	#config_user="$( usex milter 'milter' 'opendmarc' )"
	# create config file
	doins "${T}"/opendmarc.conf

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
