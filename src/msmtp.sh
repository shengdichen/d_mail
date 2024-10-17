#!/usr/bin/env dash

. "${HOME}/.local/lib/util.sh"

DIR_MSMTP_CONFIG="${HOME}/.config/msmtp"

__config() {
    __commit() {
        local _config="${DIR_MSMTP_CONFIG}/${1:-config}"
        if [ "${#}" -eq 0 ]; then
            _config="${DIR_MSMTP_CONFIG}/config"
        else
            _config="${DIR_MSMTP_CONFIG}/${1}"
            true >"${_config}"
        fi

        cat - >>"${_config}"
        chmod 600 -- "${_config}"
    }

    __passcmd() {
        case "${1}" in
            "oauth")
                shift
                printf "passwordeval ~/dot/dot/d_mail/src/oauth2/setup.sh get -- %s" "${1}"
                ;;
            "pass")
                shift
                printf "passwordeval pass Dox/mail/%s | head -n 1" "${1}"
                ;;
        esac
        printf "\n"
    }

    case "${1}" in
        "pass")
            shift
            __passcmd "${@}"
            ;;
        "commit")
            shift
            __commit "${@}"
            ;;
    esac
}

__msmtp() {
    local _account
    while [ "${#}" -gt 0 ]; do
        case "${1}" in
            "--account")
                _account="${2}"
                shift 2
                ;;
            "--")
                shift && break
                ;;
        esac
    done

    if [ ! "${_account}" ]; then
        printf "send> using default config\n"
        msmtp -- "${@}"
        return
    fi

    local _config="${DIR_MSMTP_CONFIG}/${_account}"
    if [ ! -e "${_config}" ]; then
        printf "send> using default config as account [%s]\n" "${_account}"
        msmtp --account "${_account}" -- "${@}"
        return
    fi

    printf "send> using config [%s]\n" "${_config}"
    msmtp --file "${_config}" -- "${@}"
}

__find_accounts() {
    find "${DIR_MSMTP_CONFIG}/" -mindepth 1 -maxdepth 1 -printf "%P\n" | grep -v "config" | sort -n
}

__make_test_mail() {
    printf "Subject: Test Email [%s] \n" "$(date)"

    printf "\n"

    __separator --breaks-before 0 --breaks-after 0
    printf "Test Message by %s\n" "$(whoami)"
    printf "Sent from Linux %s\n" "$(uname -r)"
    __separator --breaks-before 0 --breaks-after 0
}

__send_test_mail() {
    local _mail_to="shengdishcchen@gmail.com"
    local _account
    for _account in "${@}"; do
        printf "send> %s -> %s\n" "${_account}" "${_mail_to}"
        __make_test_mail | __msmtp --account "${_account}" -- "${_mail_to}"
        __separator
    done
}

__test() {
    if [ "${1}" = "--" ]; then shift; fi

    __f() {
        local _mail_to="shengdishcchen@gmail.com"
        printf "send> %s -> %s\n" "${1}" "${_mail_to}"
        __make_test_mail | __msmtp --account "${1}" -- "${_mail_to}"
        __separator
    }

    local _account
    if [ "${#}" -eq 0 ]; then
        __find_accounts | __fzf --multi | while read -r _account; do
            __f "${_account}"
        done
        return
    fi
    if [ "${1}" = "ALL" ]; then
        __find_accounts | while read -r _account; do
            __f "${_account}"
        done
        return
    fi
    for _account in "${@}"; do
        __f "${_account}"
    done
}

if [ "${#}" -eq 0 ]; then return; fi
case "${1}" in
    "config")
        shift
        __config "${@}"
        ;;
    "test")
        shift
        __test "${@}"
        ;;
    *)
        __msmtp "${@}"
        ;;
esac
