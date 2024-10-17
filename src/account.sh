#!/usr/bin/env dash

SCRIPT_PATH="$(realpath "$(dirname "${0}")")"

__xyz() {
    local _account="xyz"
    local _addr="me@shengdichen.xyz"

    __mbsync_config() {
        {
            "${SCRIPT_PATH}/mbsync.sh" config base

            {
                cat <<STOP
Host 127.0.0.1
Port 1143
TLSType STARTTLS
CertificateFile "~/.cert/protonmail/${_addr}.cert.pem"
User ${_addr}
STOP
                "${SCRIPT_PATH}/mbsync.sh" config pass pass "${_addr}.bridge"
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
user ${_addr}
from ${_addr}
STOP
            "${SCRIPT_PATH}/msmtp.sh" config pass pass "${_addr}.bridge"
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
    local _addr="shengdi@outlook.de"

    __mbsync_config() {
        {
            "${SCRIPT_PATH}/mbsync.sh" config base

            {
                cat <<STOP
Host outlook.office365.com
Port 993
AuthMechs XOAUTH2
TLSType IMAPS
User ${_addr}
STOP
                "${SCRIPT_PATH}/mbsync.sh" config pass oauth "${_addr}"
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
user ${_addr}
from ${_addr}
STOP

            "${SCRIPT_PATH}/msmtp.sh" config pass oauth "${_addr}"
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
    local _addr="shenchen@ethz.ch"

    __mbsync_config() {
        {
            "${SCRIPT_PATH}/mbsync.sh" config base

            {
                cat <<STOP
Host outlook.office365.com
Port 993
AuthMechs XOAUTH2
TLSType IMAPS
User ${_addr}
STOP
                "${SCRIPT_PATH}/mbsync.sh" config pass oauth "${_addr}"
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
user ${_addr}
from ${_addr}
STOP
            "${SCRIPT_PATH}/msmtp.sh" config pass oauth "${_addr}"
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
    local _addr="shengdishcchen@gmail.com"

    __mbsync_config() {
        {
            "${SCRIPT_PATH}/mbsync.sh" config base

            {
                cat <<STOP
Host imap.gmail.com
Port 993
TLSType IMAPS
User ${_addr}
STOP
                "${SCRIPT_PATH}/mbsync.sh" config pass pass "${_addr}.app"
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
user ${_addr}
from ${_addr}
STOP
            "${SCRIPT_PATH}/msmtp.sh" config pass pass "${_addr}.app"
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
