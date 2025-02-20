# Copyright 2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

#MY_HASH=''
#MY_PV="${PV/_rc}${MY_HASH:+-${MY_HASH}}"

DESCRIPTION="Ubiquiti UniFi Controller"
HOMEPAGE="https://www.ubnt.com/download/unifi/"
#SRC_URI="
#	http://dl.ubnt.com/unifi/${MY_PV}/unifi_sysvinit_all.deb -> unifi-${MY_PV}_sysvinit_all.deb
#	tools? (
#		https://dl.ubnt.com/unifi/${MY_PV}/unifi_sh_api -> unifi-${MY_PV}_api.sh
#	)"
#	#doc? (
#	#	https://community.ui.com/ubnt/attachments/ubnt/Blog_UniFi/${MY_DOC}/UniFi-changelog-5.10.x.txt -> unifi-${MY_PV}_changelog.txt
#	#)

LICENSE="GPL-3 UBNT"
KEYWORDS="aarch64 amd64 arm x86"
#IUSE="nls rpi1 systemd +tools" # doc
#UNIFI_LINGUAS=( ca cs da de_DE el en es_ES fr ja nl pl pt_PT ru sv tr zh_CN zh_TW )
#IUSE+=" ${UNIFI_LINGUAS[@]/#/linguas_}"
RESTRICT="mirror"
SLOT="0"

RDEPEND="
	|| ( app-containers/podman app-containers/docker )
	app-containers/container-init-scripts
	acct-group/unifi
	acct-user/unifi
"

S="${WORKDIR}"

src_prepare () {
	local f

	for f in unifi.initd_common; do
		sed \
			-e "s#@PVR@#${PVR}#" \
			"${FILESDIR}/${f}" > "${T}/${f%.in}" || die
	done

	echo "CONFIG_PROTECT=\"${EPREFIX%/}/var/lib/unifi/data\"" > "${T}/90${PN}"

	default
}

src_install () {
	#keepdir /var/lib/unifi/backup # data/backup?
	#keepdir /var/lib/unifi/conf # ?
	keepdir /var/lib/unifi/data
	#keepdir /var/lib/unifi/db # data/db?
	keepdir /var/lib/unifi/webapp/work # /var/run/unifi/work?
	keepdir /var/log/unifi

	diropts -m0770
	keepdir /var/lib/unifi/certs
	diropts -m0755

	insinto /var/lib/unifi/data
	doins "${FILESDIR}"/system.properties

	fowners -R unifi:unifi \
		/var/lib/unifi \
		/var/log/unifi

	newinitd "${T}"/unifi.initd_common unifi ||
		die "Could not create init script"
	newconfd "${FILESDIR}"/unifi.confd unifi ||
		die "Could not create conf file"
	sed -i -e "s|%INST_DIR%|/opt/${P}|g" \
		"${ED%/}"/etc/{init,conf}.d/unifi \
	|| die "Could not customise init scripts"

	doenvd "${T}/90${PN}" || die "Could not configure environment"
}

pkg_postinst() {
	elog "By default, ${P} uses the following ports:"
	elog
	elog "    Web Interface:         8080"
	elog "    API:                   8443"
	elog "    Portal HTTP redirect:  8880"
	elog "    Portal HTTPS redirect: 8843"
	elog "    STUN:                  3478"
	elog
	elog "... and will attempt to connect to mongodb on localhost:27117"
	elog
	elog "Additionally, ports 8881 and 8882 are reserved, and 6789 is used"
	elog "for determining throughput."
	elog
	elog "From release 5.9.x onwards, port 8883/tcp must allow outbound traffic"
	elog
	elog "All of these ports may be customised by editing"
	elog
	elog "    /opt/${P}/data/system.properties"
	elog
	elog "... but please note that the file will be re-written on each"
	elog "startup/shutdown, and any changes to the comments will be lost."
	elog
	elog "These settings cannot be passed as '-D' parameters to Java,"
	elog "${P} only uses values from the properties file."
	elog
	elog "If the Web Interface/Inform port is changed from the default of"
	elog "8080, then all managed devices must be updated via debug console"
	elog "with the command:"
	elog
	elog "    set-inform http://<controller IP>:<new port>/inform"
	elog
	elog "... before they will be able to reconnect."

	elog
	ewarn "From ${PN}-5.6.20, the default behaviour is to immediately"
	ewarn "attempt to allocate 1GB of memory on startup.  If running on a"
	ewarn "memory-constrained system, please edit:"
	ewarn
	ewarn "    /opt/${P}/data/system.properties"
	ewarn
	ewarn "... in order to set appropriate Java XMS and XMX (minimum and"
	ewarn "maximum memory constraints) values"
	elog
	ewarn "UniFi Controller 5.10+ requires at least firmware 4.0.9 for"
	ewarn "UAP/USW and at least firmware 4.4.34 for USG"

	elog
	einfo "The following container mounts are required for ${PN}:"
	einfo
	einfo "    /var/lib/unifi"
	einfo "    /var/log/unifi"
	einfo "    /var/run/unifi"
	einfo
	einfo "Please ensure that these directories are mounted when starting the ${PN} container"
}
