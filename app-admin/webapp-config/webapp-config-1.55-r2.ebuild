# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DISTUTILS_USE_SETUPTOOLS=no
PYTHON_COMPAT=( python3_{9..11} )

inherit distutils-r1 prefix

SRC_URI="https://dev.gentoo.org/~blueness/${PN}/${P}.tar.bz2"
KEYWORDS="~alpha amd64 arm arm64 ~hppa ~ia64 ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86"

DESCRIPTION="Gentoo's installer for web-based applications"
HOMEPAGE="https://sourceforge.net/projects/webapp-config/"

LICENSE="GPL-2"
SLOT="0"
IUSE="aolserver apache cherokee gatling html lighttpd nginx +portage tracd uwsgi"
REQUIRED_USE="^^ ( aolserver apache cherokee gatling lighttpd nginx tracd uwsgi )"

DEPEND="app-text/xmlto
	sys-apps/gentoo-functions"
RDEPEND="
	portage? ( sys-apps/portage[${PYTHON_USEDEP}] )"

python_prepare_all() {
	distutils-r1_python_prepare_all
	eprefixify WebappConfig/eprefix.py config/webapp-config
}

python_compile_all() {
	emake -C doc/
}

python_test() {
	PYTHONPATH="." "${EPYTHON}" WebappConfig/tests/external.py -v ||
		die "Testing failed with ${EPYTHON}"
}

python_install() {
	# According to this discussion:
	# http://mail.python.org/pipermail/distutils-sig/2004-February/003713.html
	# distutils does not provide for specifying two different script install
	# locations. Since we only install one script here the following should
	# be ok
	distutils-r1_python_install --install-scripts="${EPREFIX}/usr/sbin"
}

python_install_all() {
	distutils-r1_python_install_all

	insinto /etc/vhosts
	doins config/webapp-config

	local server=''
	if use aolserver; then
		server='aolserver'
	elif use cherokee; then
		server='cherokee'
	elif use gatling; then
		server='gatling'
	elif use lighttpd; then
		server='lighttpd'
	elif use nginx; then
		server='nginx'
	elif use tracd; then
		server='tracd'
	elif use uwsgi; then
		server='uwsgi'
	fi
	if [[ -n "${server:-}" ]]; then
		sed -i \
			-e "/vhost_server/s/^.*$/vhost_server=\"${server}\"/" \
			"${ED%/}"/etc/vhosts/webapp-config || die
	fi

	keepdir /usr/share/webapps
	keepdir /var/db/webapps

	dodoc AUTHORS
	doman doc/*.[58]
	if use html; then
		docinto html
		dodoc doc/*.[58].html
	fi
}

pkg_postinst() {
	elog "This build of webapp-config pre-selects a specified webserver in"
	elog "/etc/vhosts/webapp-config, but it is still highly recommended to"
	elog "review and update this file before you emerge any packages which"
	elog "make use of webapp-config"
}
