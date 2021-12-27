# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

#MY_PV="${PV/_rc/-RC}"
#MY_SRC="${PN}-${MY_PV}"
#MY_URI="ftp://ftp.porcupine.org/mirrors/postfix-release/official"
RC_VER="2.7"

DESCRIPTION="A fast and secure drop-in replacement for sendmail"
HOMEPAGE="http://www.postfix.org/"
#SRC_URI="${MY_URI}/${MY_SRC}.tar.gz"

LICENSE="|| ( IBM EPL-2.0 )"
KEYWORDS="~alpha amd64 arm ~arm64 ~hppa ~ia64 ~mips ppc ppc64 ~s390 ~sparc x86"
#IUSE="+berkdb cdb dovecot-sasl +eai hardened ldap ldap-bind libressl lmdb memcached mbox mysql nis pam postgres sasl selinux sqlite ssl"
IUSE="mbox memcached mysql postgres sasl"
SLOT="0"

DEPEND="
	acct-group/postfix
	acct-group/postdrop
	acct-user/postfix"
BDEPEND="
	${DEPEND}"
RDEPEND="
	|| ( app-containers/podman app-containers/docker )
	${DEPEND}
	acct-group/dkimsocket"
	#memcached? ( net-misc/memcached )"

S="${WORKDIR}"

src_prepare() {
	local f

	for f in postfix.rc6.${RC_VER}; do
		sed \
			-e "s#@PVR@#${PVR}#" \
			"${FILESDIR}/${f}" > "${T}/${f%.in}" || die
	done

	default
}

src_install() {
	# Fix spool removal on upgrade
	keepdir /var/spool/postfix

	# Set proper permissions on required files/directories
	keepdir /var/lib/postfix
	fowners -R postfix:postfix /var/lib/postfix
	fperms 0750 /var/lib/postfix

	keepdir /etc/postfix
	keepdir /etc/postfix/postfix-files.d
	#if use mbox; then
	#	mypostconf="mail_spool_directory=/var/spool/mail"
	#else
	#	mypostconf="home_mailbox=.maildir/"
	#fi
	#LD_LIBRARY_PATH="${S}/lib" \
	#"${D}"/usr/sbin/postconf -c "${D}"/etc/postfix \
	#	-e ${mypostconf} || die "postconf failed"

	insinto /etc/postfix
	newins "${FILESDIR}"/smtp.pass saslpass
	fperms 600 /etc/postfix/saslpass

	newinitd "${T}"/postfix.rc6.${RC_VER} postfix
	newconfd "${FILESDIR}"/postfix.confd postfix
	# do not start mysql/postgres unnecessarily - bug #359913
	use mysql || sed -i -e "s/mysql //" "${D}/etc/init.d/postfix"
	use postgres || sed -i -e "s/postgresql //" "${D}/etc/init.d/postfix"

	if use sasl; then
		insinto /etc/sasl2
		newins "${FILESDIR}"/smtp.sasl smtpd.conf
	fi

	if has_version mail-mta/postfix; then
		# let the sysadmin decide when to change the compatibility_level
		sed -i -e /^compatibility_level/"s/^/#/" "${D}"/etc/postfix/main.cf || die
	fi
}

pkg_preinst() {
	if has_version '<mail-mta/postfix-3.4'; then
		elog
		elog "Postfix-3.4 introduces a new master.cf service 'postlog'"
		elog "with type 'unix-dgram' that is used by the new postlogd(8) daemon."
		elog "Before backing out to an older Postfix version, edit the master.cf"
		elog "file and remove the postlog entry."
		elog
	fi
}

pkg_postinst() {
	if [[ ! -e /etc/mail/aliases.db ]] ; then
		ewarn
		ewarn "You must edit /etc/mail/aliases to suit your needs"
		ewarn "and then run /usr/bin/newaliases. Postfix will not"
		ewarn "work correctly without it."
		ewarn
	fi

	einfo "The following container mounts are required for ${PN}:"
	einfo
	einfo "    /etc/${PN}"
	einfo "    /var/lib/${PN}"
	einfo "    /var/spool/${PN}"
	einfo
	einfo "Please ensure that these directories are mounted when starting the ${PN} container"
}
