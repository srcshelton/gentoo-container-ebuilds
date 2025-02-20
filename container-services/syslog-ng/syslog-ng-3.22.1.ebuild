# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

MY_PV_MM=$(ver_cut 1-2)
DESCRIPTION="syslog replacement with advanced filtering features"
HOMEPAGE="https://syslog-ng.com/open-source-log-management"
#SRC_URI="https://github.com/balabit/syslog-ng/releases/download/${P}/${P}.tar.gz"

LICENSE="GPL-2+ LGPL-2.1+"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 hppa ~ia64 ~mips ppc ppc64 ~riscv ~s390 sparc x86"
#IUSE="amqp caps dbi geoip geoip2 http ipv6 json kafka libressl mongodb pacct python redis smtp snmp spoof-source systemd tcpd"
#REQUIRED_USE="python? ( ${PYTHON_REQUIRED_USE} )"
# unit tests require https://github.com/Snaipe/Criterion with additional deps
#RESTRICT="test"

RDEPEND="
	|| ( app-containers/podman app-containers/docker )"

S="${WORKDIR}"

src_prepare() {
	local f

	for f in syslog-ng.logrotate.in; do
		sed \
			-e "s#@GENTOO_RESTART@#/etc/init.d/syslog-ng reload#g" \
			"${FILESDIR}/${f}" > "${T}/${f%.in}" || die
	done

	for f in syslog-ng.conf.gentoo.in; do
		sed -e "s/@SYSLOGNG_VERSION@/${MY_PV_MM}/g" "${FILESDIR}/${f}" > "${T}/${f%.in}" || die
	done

	default
}

src_install() {
	insinto /etc/syslog-ng
	newins "${T}/syslog-ng.conf.gentoo" syslog-ng.conf

	insinto /etc/logrotate.d
	newins "${T}/syslog-ng.logrotate" syslog-ng

	newinitd "${FILESDIR}/${P}.rc" syslog-ng
	newconfd "${FILESDIR}/syslog-ng.confd" syslog-ng

	keepdir /etc/syslog-ng/patterndb.d /var/lib/syslog-ng
}

pkg_postinst() {
	# bug #355257
	if ! has_version app-admin/logrotate ; then
		elog "It is highly recommended that app-admin/logrotate be emerged to"
		elog "manage the log files.  ${PN} installs a file in /etc/logrotate.d"
		elog "for logrotate to use."
	fi

	einfo "The following container mounts are required for ${PN}:"
	einfo
	einfo "    /etc/${PN}"
	einfo "    /var/lib/${PN}"
	einfo "    /var/log"
	einfo "    /var/run/${PN}"
	einfo
	einfo "Please ensure that these directories are mounted when starting the ${PN} container"
}
