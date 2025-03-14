# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit autotools systemd

DESCRIPTION="A highly configurable replacement for syslogd/klogd"
HOMEPAGE="https://github.com/hvisage/metalog"
SRC_URI="https://github.com/hvisage/${PN}/archive/${P}.tar.gz"
S="${WORKDIR}"/${PN}-${P}

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 hppa ~ia64 ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86"
IUSE="systemd unicode"

RDEPEND="dev-libs/libpcre2"
DEPEND="${RDEPEND}"
BDEPEND="dev-build/autoconf-archive
	virtual/pkgconfig"

PATCHES=(
	"${FILESDIR}"/${PN}-0.9-metalog-conf.patch
	"${FILESDIR}"/${PN}-alternate-path-log.patch
)

src_prepare() {
	default

	eautoreconf
}

src_configure() {
	econf \
		$(use_with unicode) \
		--sysconfdir=/etc/metalog
}

src_install() {
	emake DESTDIR="${D}" install
	dodoc AUTHORS ChangeLog README NEWS metalog.conf

	into /
	newsbin "${FILESDIR}"/consolelog.sh-r1 consolelog.sh

	newinitd "${FILESDIR}"/metalog.initd-r1 metalog
	newconfd "${FILESDIR}"/metalog.confd metalog
	use systemd && systemd_newunit "${FILESDIR}/${PN}.service-r1" "${PN}.service"
}

pkg_preinst() {
	if [[ -e "${ROOT}"/etc/metalog.conf && ! -d "${ROOT}"/etc/metalog ]] ; then
		mkdir -p "${ROOT}"/etc/metalog
		mv -f "${ROOT}"/etc/metalog.conf "${ROOT}"/etc/metalog/metalog.conf
		export MOVED_METALOG_CONF=true
	else
		export MOVED_METALOG_CONF=false
	fi
}

pkg_postinst() {
	if ${MOVED_METALOG_CONF} ; then
		ewarn "The default metalog.conf file has been moved"
		ewarn "from just ${EROOT%/}/etc/metalog.conf to"
		ewarn "${EROOT%/}/etc/metalog/metalog.conf.  If you had a standard"
		ewarn "setup, the file has been moved for you."
	fi
}
