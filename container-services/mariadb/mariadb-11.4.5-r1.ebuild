# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

#### The data in the files/ subdirectory of this ebuild are a combination ####
#### of those from dev-db/mariadb and dev-db/mysql-init-scripts           ####

EAPI=8
SUBSLOT="18"

inherit eapi9-ver prefix

DESCRIPTION="An enhanced, drop-in replacement for MySQL"
HOMEPAGE="https://mariadb.org/"
#SRC_URI="
#	mirror://mariadb/${P}/source/${P}.tar.gz
#	https://dev.gentoo.org/~arkamar/distfiles/${P}-patches-01.tar.xz
#"
# Shorten the path because the socket path length must be shorter than 107 chars
# and we will run a mysql server during test phase
S="${WORKDIR}"

LICENSE="GPL-2 LGPL-2.1+"
SLOT="$(ver_cut 1-2)/${SUBSLOT:-0}"
KEYWORDS="~amd64 ~arm ~arm64 ~hppa ~loong ~ppc ~ppc64 ~riscv ~s390 ~x86"
#IUSE="+backup bindist columnstore cracklib debug extraengine galera -hashicorp innodb-bzip2 innodb-lz4 innodb-lzma innodb-lzo innodb-snappy jdbc jemalloc kerberos latin1 mroonga numa odbc oqgraph pam +perl profiling rocksdb s3 selinux +server sphinx sst-mariabackup sst-rsync static systemd systemtap tcmalloc test xml yassl"
IUSE="+client galera latin1 pam +server"

#RESTRICT="!bindist? ( bindist ) !test? ( test )"

#REQUIRED_USE="jdbc? ( extraengine server !static )
#	?? ( tcmalloc jemalloc )
#	static? ( yassl !pam )
#	test? ( extraengine )"

RDEPEND="
	|| ( app-containers/podman app-containers/docker )
	app-containers/container-init-scripts
	acct-group/mysql
	acct-user/mysql
	dev-db/mysql-connector-c
	client? ( dev-db/mariadb[-server] )
	!dev-db/mariadb[server]"

mysql_init_vars() {
	MY_SHAREDSTATEDIR=${MY_SHAREDSTATEDIR="${EPREFIX}/usr/share/mariadb"}
	MY_SYSCONFDIR=${MY_SYSCONFDIR="${EPREFIX}/etc/mysql"}
	MY_LOCALSTATEDIR=${MY_LOCALSTATEDIR="${EPREFIX}/var/lib/mysql"}
	MY_LOGDIR=${MY_LOGDIR="${EPREFIX}/var/log/mysql"}

	if [[ -z "${MY_DATADIR}" ]] ; then
		MY_DATADIR=""
		if [[ -f "${MY_SYSCONFDIR}/my.cnf" ]] ; then
			MY_DATADIR=$(my_print_defaults mysqld 2>/dev/null \
				| sed -ne '/datadir/s|^--datadir=||p' \
				| tail -n1)
			if [[ -z "${MY_DATADIR}" ]] ; then
				MY_DATADIR=$(grep ^datadir "${MY_SYSCONFDIR}/my.cnf" \
				| sed -e 's/.*=\s*//' \
				| tail -n1)
			fi
		fi
		if [[ -z "${MY_DATADIR}" ]] ; then
			MY_DATADIR="${MY_LOCALSTATEDIR}"
			einfo "Using default MY_DATADIR"
		fi
		elog "MySQL MY_DATADIR is ${MY_DATADIR}"

		if [[ -z "${PREVIOUS_DATADIR}" ]] ; then
			if [[ -e "${MY_DATADIR}" ]] ; then
				# If you get this and you're wondering about it, see bug #207636
				elog "MySQL datadir found in ${MY_DATADIR}"
				elog "A new one will not be created."
				PREVIOUS_DATADIR="yes"
			else
				PREVIOUS_DATADIR="no"
			fi
			export PREVIOUS_DATADIR
		fi
	else
		if [[ ${EBUILD_PHASE} == "config" ]]; then
			local new_MY_DATADIR
			new_MY_DATADIR=$(my_print_defaults mysqld 2>/dev/null \
				| sed -ne '/datadir/s|^--datadir=||p' \
				| tail -n1)

			if [[ ( -n "${new_MY_DATADIR}" ) && ( "${new_MY_DATADIR}" != "${MY_DATADIR}" ) ]]; then
				ewarn "MySQL MY_DATADIR has changed"
				ewarn "from ${MY_DATADIR}"
				ewarn "to ${new_MY_DATADIR}"
				MY_DATADIR="${new_MY_DATADIR}"
			fi
		fi
	fi

	export MY_SHAREDSTATEDIR MY_SYSCONFDIR
	export MY_LOCALSTATEDIR MY_LOGDIR
	export MY_DATADIR
}

src_prepare() {
	local f

	for f in init.d-2.3-r1_common; do
		sed \
			-e "s#@PVR@#${PVR}#" \
			"${FILESDIR}/${f}" > "${T}/${f%.in}" || die
	done

	default
}

src_install() {
	# From dev-db/mysql-init-scripts
	#

	newconfd "${FILESDIR}/conf.d-2.0" "mysql"
	newinitd "${T}/init.d-2.3-r1_common" "mysql"

	insinto /etc/logrotate.d
	newins "${FILESDIR}/logrotate.mysql-2.3" "mysql"

	# From dev-db/mariadb
	#

	# Make sure the vars are correctly initialized
	mysql_init_vars

	# Configuration stuff
	einfo "Building default configuration ..."
	insinto "${MY_SYSCONFDIR#${EPREFIX}}"
	doins "${FILESDIR}"/mysqlaccess.conf
	cp "${FILESDIR}/my.cnf-10.2" "${TMPDIR}/my.cnf" || die
	eprefixify "${TMPDIR}/my.cnf"
	doins "${TMPDIR}/my.cnf"
	insinto "${MY_SYSCONFDIR#${EPREFIX}}/mariadb.d"
	cp "${FILESDIR}/my.cnf.distro-client" "${TMPDIR}/50-distro-client.cnf" || die
	eprefixify "${TMPDIR}/50-distro-client.cnf"
	doins "${TMPDIR}/50-distro-client.cnf"

	if use server ; then
		mycnf_src="my.cnf.distro-server"
		sed -e "s!@DATADIR@!${MY_DATADIR}!g" \
			"${FILESDIR}/${mycnf_src}" \
			> "${TMPDIR}/my.cnf.ok" || die
		if use prefix ; then
			sed -i -r -e '/^user[[:space:]]*=[[:space:]]*mysql$/d' \
				"${TMPDIR}/my.cnf.ok" || die
		fi
		if use latin1 ; then
			sed -i \
				-e "/character-set/s|utf8|latin1|g" \
				"${TMPDIR}/my.cnf.ok" || die
		fi
		eprefixify "${TMPDIR}/my.cnf.ok"
		newins "${TMPDIR}/my.cnf.ok" 50-distro-server.cnf
	fi
}

pkg_postinst() {
	if use server ; then
		if use pam; then
			einfo
			elog "This install includes the PAM authentication plugin."
			elog "To activate and configure the PAM plugin, please read:"
			elog "https://mariadb.com/kb/en/mariadb/pam-authentication-plugin/"
			einfo
		fi

		if [[ -z "${REPLACING_VERSIONS}" ]] ; then
			einfo
			elog "You might want to run:"
			elog "\"emerge --config =${CATEGORY}/${PF}\""
			elog "if this is a new install."
			elog
			elog "If you are switching server implentations, you should run the"
			elog "mysql_upgrade tool."
			einfo
		else
			einfo
			elog "If you are upgrading major versions, you should run the"
			elog "mysql_upgrade tool."
			einfo
		fi

		if use galera ; then
			einfo
			elog "Be sure to edit the my.cnf file to activate your cluster settings."
			elog "This should be done after running \"emerge --config =${CATEGORY}/${PF}\""
			elog "The first time the cluster is activated, you should add"
			elog "--wsrep-new-cluster to the options in /etc/conf.d/mysql for one node."
			elog "This option should then be removed for subsequent starts."
			einfo
			if ver_replacing -lt "10.4.0" ; then
				ewarn "Upgrading galera from a previous version requires admin restart of the entire cluster."
				ewarn "Please refer to https://mariadb.com/kb/en/library/changes-improvements-in-mariadb-104/#galera-4"
				ewarn "for more information"
			fi
		fi
	fi

	# Note about configuration change
	einfo
	elog "This version of mariadb reorganizes the configuration from a single my.cnf"
	elog "to several files in /etc/mysql/${PN}.d."
	elog "Please backup any changes you made to /etc/mysql/my.cnf"
	elog "and add them as a new file under /etc/mysql/${PN}.d with a .cnf extension."
	elog "You may have as many files as needed and they are read alphabetically."
	elog "Be sure the options have the appropriate section headers, i.e. [mysqld]."
	einfo

	einfo "The following container mounts are required for ${PN}:"
	einfo
	einfo "    /etc/${PN}"
	einfo "    /var/lib/${PN}"
	einfo "    /var/log/${PN}"
	einfo "    /var/run/${PN}"
	einfo
	einfo "Please ensure that these directories are mounted when starting the ${PN} container"
}
