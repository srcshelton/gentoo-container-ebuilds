# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="A persistent caching system, key-value and data structures database"
HOMEPAGE="https://redis.io"
#SRC_URI="http://download.redis.io/releases/${P}.tar.gz"

LICENSE="BSD"
KEYWORDS="amd64 arm ~arm64 ~hppa ~ppc ~ppc64 sparc x86 ~amd64-linux ~x86-linux ~x86-solaris"
#IUSE="+jemalloc ssl systemd tcmalloc test +tmpfiles"
#RESTRICT="!test? ( test )"
SLOT="0"

COMMON_DEPEND="
	|| ( app-emulation/podman app-emulation/docker )
	app-emulation/container-init-scripts
"

RDEPEND="
	${COMMON_DEPEND}
	acct-group/redis
	acct-user/redis
	!dev-db/redis
"

S="${WORKDIR}"

src_prepare() {
	local f

	for f in redis.initd-6_common redis-sentinel.initd-r1_common; do
		sed \
			-e "s#@PVR@#${PVR}#" \
			"${FILESDIR}/${f}" > "${T}/${f%.in}" || die
	done

	default
}

src_install() {
	insinto /etc/redis
	newins "${FILESDIR}/redis.conf-6.0.12" redis.conf
	newins "${FILESDIR}/sentinel.conf-6.0.9" sentinel.conf

	newconfd "${FILESDIR}/redis.confd-r2" redis
	newinitd "${T}/redis.initd-6_common" redis

	newconfd "${FILESDIR}/redis-sentinel.confd-r1" redis-sentinel
	newinitd "${T}/redis-sentinel.initd-r1_common" redis-sentinel

	insinto /etc/logrotate.d/
	newins "${FILESDIR}/${PN}.logrotate" "${PN}"

	diropts -o redis -g redis
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

# vi: set diffopt=iwhite,filler:
