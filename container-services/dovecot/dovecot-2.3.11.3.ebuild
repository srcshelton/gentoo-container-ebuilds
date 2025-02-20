# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

# do not add a ssl USE flag.  ssl is mandatory
SSL_DEPS_SKIP=1
inherit ssl-cert

MY_P="${P/_/.}"
#MY_S="${PN}-ce-${PV}"
major_minor="$(ver_cut 1-2)"
sieve_version="0.5.11"
if [[ ${PV} == *_rc* ]] ; then
	rc_dir="rc/"
else
	rc_dir=""
fi
#SRC_URI="https://dovecot.org/releases/${major_minor}/${rc_dir}${MY_P}.tar.gz
#	sieve? (
#	https://pigeonhole.dovecot.org/releases/${major_minor}/${rc_dir}${PN}-${major_minor}-pigeonhole-${sieve_version}.tar.gz
#	)
#	managesieve? (
#	https://pigeonhole.dovecot.org/releases/${major_minor}/${rc_dir}${PN}-${major_minor}-pigeonhole-${sieve_version}.tar.gz
#	) "
DESCRIPTION="An IMAP and POP3 server written with security primarily in mind"
HOMEPAGE="https://www.dovecot.org/"

SLOT="0"
LICENSE="LGPL-2.1 MIT"
KEYWORDS="~alpha amd64 ~arm ~hppa ~ia64 ~mips ppc ppc64 ~s390 ~sparc x86"

#IUSE_DOVECOT_AUTH="kerberos ldap lua mysql pam postgres sqlite vpopmail"
#IUSE_DOVECOT_COMPRESS="bzip2 lzma lz4 zlib"
#IUSE_DOVECOT_OTHER="argon2 caps doc ipv6 libressl lucene managesieve selinux sieve solr static-libs suid tcpd textcat unwind"
#
#IUSE="${IUSE_DOVECOT_AUTH} ${IUSE_DOVECOT_COMPRESS} ${IUSE_DOVECOT_OTHER} systemd"
IUSE="ipv6 ldap managesieve mysql pam postgres sieve vpopmail"

RDEPEND="
	|| ( app-containers/podman app-containers/docker )
	acct-group/dovecot
	acct-group/dovenull
	acct-group/mail
	acct-user/dovecot
	acct-user/dovenull"

S="${WORKDIR}"

src_prepare() {
	for f in dovecot.init-r6; do
		sed \
			-e "s#@PVR@#${PVR}#" \
			"${FILESDIR}/${f}" > "${T}/${f%.in}" || die
	done

	default
}

src_install() {
	newinitd "${T}"/dovecot.init-r6 dovecot
	newconfd "${FILESDIR}"/dovecot.confd dovecot

	# Create the dovecot.conf file from the dovecot-example.conf file that
	# the dovecot folks nicely left for us....
	local conf="${ED}/etc/dovecot/dovecot.conf"
	local confd="${ED}/etc/dovecot/conf.d"

	insinto /etc/dovecot
	doins "${FILESDIR}/example-config-${PV}"/*.{conf,ext}	# !!!
	insinto /etc/dovecot/conf.d
	doins "${FILESDIR}/example-config-${PV}/conf.d"/*.{conf,ext}	# !!!
	fperms 0600 /etc/dovecot/dovecot-{ldap,sql}.conf.ext

	# logrotate
	insinto /etc/logrotate.d
	newins "${FILESDIR}"/dovecot.logrotate dovecot

	# .maildir is the Gentoo default
	local mail_location="maildir:~/.maildir"
	sed -i -e \
		"s|#mail_location =|mail_location = ${mail_location}|" \
		"${confd}/10-mail.conf" \
		|| die "failed to update mail location settings in 10-mail.conf"

	# We're using pam files (imap and pop3) provided by mailbase
	if use pam; then
		sed -i -e '/driver = pam/,/^[ \t]*}/ s|#args = dovecot|args = "\*"|' \
			"${confd}/auth-system.conf.ext" \
			|| die "failed to update PAM settings in auth-system.conf.ext"
		# mailbase does not provide a sieve pam file
		sed -i -e \
			's/#!include auth-system.conf.ext/!include auth-system.conf.ext/' \
			"${confd}/10-auth.conf" \
			|| die "failed to update PAM settings in 10-auth.conf"
	fi

	# Disable ipv6 if necessary
	if ! use ipv6; then
		sed -i -e 's/^#listen = \*, ::/listen = \*/g' "${conf}" \
			|| die "failed to update listen settings in dovecot.conf"
	fi

	# Update ssl cert locations
	sed -i -e 's:^#ssl = yes:ssl = yes:' "${confd}/10-ssl.conf" \
		|| die "ssl conf failed"
	sed -i -e 's:^ssl_cert =.*:ssl_cert = </etc/ssl/dovecot/server.pem:' \
		-e 's:^ssl_key =.*:ssl_key = </etc/ssl/dovecot/server.key:' \
		"${confd}/10-ssl.conf" || die "failed to update SSL settings in 10-ssl.conf"

	# Install SQL configuration
	if use mysql || use postgres; then
		sed -i -e \
			's/#!include auth-sql.conf.ext/!include auth-sql.conf.ext/' \
			"${confd}/10-auth.conf" || die "failed to update SQL settings in \
			10-auth.conf"
	fi

	# Install LDAP configuration
	if use ldap; then
		sed -i -e \
			's/#!include auth-ldap.conf.ext/!include auth-ldap.conf.ext/' \
			"${confd}/10-auth.conf" \
			|| die "failed to update ldap settings in 10-auth.conf"
	fi

	if use vpopmail; then
		sed -i -e \
			's/#!include auth-vpopmail.conf.ext/!include auth-vpopmail.conf.ext/' \
			"${confd}/10-auth.conf" \
			|| die "failed to update vpopmail settings in 10-auth.conf"
	fi

	if use sieve || use managesieve ; then
		sed -i -e \
			's/^[[:space:]]*#mail_plugins = $mail_plugins/mail_plugins = sieve/' "${confd}/15-lda.conf" \
			|| die "failed to update sieve settings in 15-lda.conf"
		insinto /etc/dovecot/conf.d
		doins "${FILESDIR}/dovecot-${major_minor}-pigeonhole-${sieve_version}/conf.d"/90-sieve{,-extprograms}.conf
		use managesieve && doins "${FILESDIR}/dovecot-${major_minor}-pigeonhole-${sieve_version}/conf.d"/20-managesieve.conf
	fi
}

pkg_postinst() {
	# Let's not make a new certificate if we already have one
	if ! [[ -e "${ROOT}"/etc/ssl/dovecot/server.pem && \
		-e "${ROOT}"/etc/ssl/dovecot/server.key ]];	then
		einfo "Creating SSL	certificate"
		SSL_ORGANIZATION="${SSL_ORGANIZATION:-Dovecot IMAP Server}"
		install_cert /etc/ssl/dovecot/server
	fi

	elog "Please read https://doc.dovecot.org/installation_guide/upgrading/ for upgrade notes."

	einfo "The following container mounts are required for ${PN}:"
	einfo
	einfo "    /etc/${PN}"
	einfo "    /etc/ssl/${PN}"
	einfo "    /var/lib/${PN}"
	einfo "    /var/log/${PN}"
	einfo "    /var/run/${PN}"
	einfo
	einfo "Please ensure that these directories are mounted when starting the ${PN} container"
}
