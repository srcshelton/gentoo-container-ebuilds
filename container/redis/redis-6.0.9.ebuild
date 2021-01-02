# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="A persistent caching system, key-value and data structures database"
HOMEPAGE="https://redis.io"
#SRC_URI="http://download.redis.io/releases/${P}.tar.gz"

LICENSE="BSD"
KEYWORDS="amd64 arm arm64 ~hppa ~ppc ~ppc64 x86 ~amd64-linux ~x86-linux ~x86-macos ~x86-solaris"
#IUSE="+jemalloc luajit tcmalloc test"
#RESTRICT="!test? ( test )"
SLOT="0"

RDEPEND="
	|| ( app-emulation/podman app-emulation/docker )
	acct-group/redis
	acct-user/redis"

S="${WORKDIR}"

src_prepare() {
	local f

	for f in redis.initd-5 redis-sentinel.initd; do
		sed \
			-e "s#@PVR@#${PVR}#" \
			"${FILESDIR}/${f}" > "${T}/${f%.in}" || die
	done

	default
}

src_install() {
	insinto /etc/redis
	newins "${FILESDIR}/redis.conf-${PV}" redis.conf
	newins "${FILESDIR}/sentinel.conf-${PV}" sentinel.conf

	newconfd "${FILESDIR}/redis.confd-r1" redis
	newinitd "${T}/redis.initd-5" redis

	newconfd "${FILESDIR}/redis-sentinel.confd" redis-sentinel
	newinitd "${T}/redis-sentinel.initd" redis-sentinel

	insinto /etc/logrotate.d/
	newins "${FILESDIR}/${PN}.logrotate" "${PN}"

	keepdir /var/{log,lib}/redis
}

pkg_postinst() {
	einfo "The following container mounts are required for ${PN}:"
	einfo
	einfo "    /etc/${PN}"
	einfo "    /var/lib/${PN}"
	einfo "    /var/log/${PN}"
	einfo "    /var/run/${PN}"
	einfo
	einfo "Please ensure that these directories are mounted when starting the ${PN} container"
}
