#!/usr/bin/env dash

SCRIPT_PATH="$(realpath "$(dirname "${0}")")"

__xyz() {
    local _account="xyz"

    __mbsync_config() {
        {
            "${SCRIPT_PATH}/mbsync.sh" config base

            {
                cat <<STOP
Host 127.0.0.1
Port 1143
TLSType STARTTLS
CertificateFile "~/.cert/protonmail/cert.pem"
User me@shengdichen.xyz
STOP
                "${SCRIPT_PATH}/mbsync.sh" config pass pass "protonbridge"
            } | "${SCRIPT_PATH}/mbsync.sh" config remote
            printf "\n"

            "${SCRIPT_PATH}/mbsync.sh" config channels "${_account}" "All Mail"
            printf "\n"

            "${SCRIPT_PATH}/mbsync.sh" config final
        } | "${SCRIPT_PATH}/mbsync.sh" config commit "${_account}"
    }

    __msmtp_config() {
        {
            cat <<STOP
host 127.0.0.1
port 1025
auth login
STOP
            printf "\n"

            cat <<STOP
user me@shengdichen.xyz
from me@shengdichen.xyz
STOP
            "${SCRIPT_PATH}/msmtp.sh" config pass pass "protonbridge"
        } | "${SCRIPT_PATH}/msmtp.sh" config commit "${_account}"
    }

    case "${1}" in
        "config")
            __mbsync_config
            __msmtp_config
            ;;
        "test")
            __mbsync_config
            "${SCRIPT_PATH}/mbsync.sh" test -- "${_account}"
            __msmtp_config
            "${SCRIPT_PATH}/msmtp.sh" test -- "${_account}"
            ;;
        *)
            __mbsync_config
            "${SCRIPT_PATH}/mbsync.sh" test -- "${_account}"
            __msmtp_config
            ;;
    esac
}

__outlook() {
    local _account="outlook"

    __mbsync_config() {
        {
            "${SCRIPT_PATH}/mbsync.sh" config base

            {
                cat <<STOP
Host outlook.office365.com
Port 993
AuthMechs XOAUTH2
TLSType IMAPS
User shengdi@outlook.de
STOP
                "${SCRIPT_PATH}/mbsync.sh" config pass oauth "shengdi@outlook.de"
            } | "${SCRIPT_PATH}/mbsync.sh" config remote
            printf "\n"

            "${SCRIPT_PATH}/mbsync.sh" config channels "${_account}"
            printf "\n"

            "${SCRIPT_PATH}/mbsync.sh" config final
        } | "${SCRIPT_PATH}/mbsync.sh" config commit "${_account}"
    }

    __msmtp_config() {
        {
            cat <<STOP
host smtp-mail.outlook.com
port 587
tls on
auth xoauth2
STOP
            printf "\n"

            cat <<STOP
user shengdi@outlook.de
from shengdi@outlook.de
STOP

            "${SCRIPT_PATH}/msmtp.sh" config pass oauth "shengdi@outlook.de"
        } | "${SCRIPT_PATH}/msmtp.sh" config commit "${_account}"
    }

    case "${1}" in
        "config")
            __mbsync_config
            __msmtp_config
            ;;
        "test")
            __mbsync_config
            "${SCRIPT_PATH}/mbsync.sh" test -- "${_account}"
            __msmtp_config
            "${SCRIPT_PATH}/msmtp.sh" test -- "${_account}"
            ;;
        *)
            __mbsync_config
            "${SCRIPT_PATH}/mbsync.sh" test -- "${_account}"
            __msmtp_config
            ;;
    esac
}

__eth() {
    local _account="eth"

    __mbsync_config() {
        {
            "${SCRIPT_PATH}/mbsync.sh" config base

            {
                cat <<STOP
Host outlook.office365.com
Port 993
AuthMechs XOAUTH2
TLSType IMAPS
User shenchen@ethz.ch
STOP
                "${SCRIPT_PATH}/mbsync.sh" config pass oauth "shenchen@ethz.ch"
            } | "${SCRIPT_PATH}/mbsync.sh" config remote
            printf "\n"

            "${SCRIPT_PATH}/mbsync.sh" config channels "${_account}" "Calendar/United States holidays"
            printf "\n"

            "${SCRIPT_PATH}/mbsync.sh" config final
        } | "${SCRIPT_PATH}/mbsync.sh" config commit "${_account}"
    }

    __msmtp_config() {
        {
            cat <<STOP
host smtp.office365.com
port 587
tls on
auth xoauth2
STOP
            printf "\n"

            cat <<STOP
user shenchen@ethz.ch
from shenchen@ethz.ch
STOP
            "${SCRIPT_PATH}/msmtp.sh" config pass oauth "shenchen@ethz.ch"
        } | "${SCRIPT_PATH}/msmtp.sh" config commit "${_account}"
    }

    case "${1}" in
        "config")
            __mbsync_config
            __msmtp_config
            ;;
        "test")
            __mbsync_config
            "${SCRIPT_PATH}/mbsync.sh" test -- "${_account}"
            __msmtp_config
            "${SCRIPT_PATH}/msmtp.sh" test -- "${_account}"
            ;;
        *)
            __mbsync_config
            "${SCRIPT_PATH}/mbsync.sh" test -- "${_account}"
            __msmtp_config
            ;;
    esac
}

__gmail() {
    local _account="gmail"

    __mbsync_config() {
        {
            "${SCRIPT_PATH}/mbsync.sh" config base

            {
                cat <<STOP
Host imap.gmail.com
Port 993
TLSType IMAPS
User shengdishcchen@gmail.com
STOP
                "${SCRIPT_PATH}/mbsync.sh" config pass pass "gmail_shengdishcchen_app"
            } | "${SCRIPT_PATH}/mbsync.sh" config remote
            printf "\n"

            "${SCRIPT_PATH}/mbsync.sh" config channels "${_account}"
            printf "\n"

            "${SCRIPT_PATH}/mbsync.sh" config final
        } | "${SCRIPT_PATH}/mbsync.sh" config commit "${_account}"
    }

    __msmtp_config() {
        {
            cat <<STOP
host smtp.gmail.com
port 587
tls on
auth on
STOP
            printf "\n"

            cat <<STOP
user shengdishcchen
from shengdishcchen@gmail.com
STOP
            "${SCRIPT_PATH}/msmtp.sh" config pass pass "gmail_shengdishcchen_app"
        } | "${SCRIPT_PATH}/msmtp.sh" config commit "${_account}"
    }

    case "${1}" in
        "config")
            __mbsync_config
            __msmtp_config
            ;;
        "test")
            __mbsync_config
            "${SCRIPT_PATH}/mbsync.sh" test -- "${_account}"
            __msmtp_config
            "${SCRIPT_PATH}/msmtp.sh" test -- "${_account}"
            ;;
        *)
            __mbsync_config
            "${SCRIPT_PATH}/mbsync.sh" test -- "${_account}"
            __msmtp_config
            ;;
    esac
}

__main() {
    local _account
    case "${1}" in
        "config")
            for _account in "xyz" "outlook" "eth" "gmail"; do
                "__${_account}" config
            done
            ;;
        "xyz" | "outlook" | "eth" | "gmail")
            _account="${1}"
            shift
            "__${_account}" "${@}"
            ;;
    esac
}
__main "${@}"
