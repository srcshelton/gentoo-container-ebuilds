# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

#[ "${PV##*_}" = "beta" ] &&
#	PRIVOXY_STATUS="beta" ||
#	PRIVOXY_STATUS="stable"

HOMEPAGE="https://www.privoxy.org https://sourceforge.net/projects/ijbswa/"
DESCRIPTION="A web proxy with advanced filtering capabilities for enhancing privacy"
#SRC_URI="mirror://sourceforge/ijbswa/${P%_*}-${PRIVOXY_STATUS}-src.tar.gz"

#IUSE="+acl brotli client-tags compression editor extended-host-patterns extended-statistics external-filters +fast-redirects +force fuzz graceful-termination +image-blocking ipv6 +jit lfs +mbedtls openssl png-images sanitize selinux ssl +stats +threads toggle tools whitelists +zlib"
SLOT="0"
KEYWORDS="~alpha amd64 arm ~arm64 ppc ppc64 ~riscv sparc x86"
LICENSE="GPL-2+"

BDEPEND="
	acct-group/privoxy
	acct-user/privoxy
"

RDEPEND="${BDEPEND}
	|| ( app-containers/podman app-containers/docker )
	app-containers/container-init-scripts
	!net-proxy/privoxy"

S="${WORKDIR}"

src_prepare() {
	for f in privoxy.initd-3_common; do
		sed \
			-e "s#@PVR@#${PVR}#" \
			"${FILESDIR}/${f}" > "${T}/${f%.in}" || die
	done

	default
}

src_install() {
	newinitd "${T}/privoxy.initd-3_common" privoxy
	newconfd "${FILESDIR}/privoxy.confd" privoxy

	insinto /etc/logrotate.d
	newins "${FILESDIR}/privoxy.logrotate" privoxy

	diropts -m 0750 -g privoxy -o privoxy
	keepdir /var/log/privoxy

	diropts -m 0755 -g root -o privoxy
	dodir /etc/privoxy
	fowners privoxy:root /etc/privoxy || die
}

pkg_postinst() {
	einfo "The following container mounts are required for ${PN}:"
	einfo
	einfo "    /etc/${PN}"
	einfo "    /var/log/${PN}"
	einfo "    /var/run/${PN}"
	einfo
	einfo "Please ensure that these directories are mounted when starting the ${PN} container"
}
