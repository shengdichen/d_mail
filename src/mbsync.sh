#!/usr/bin/env dash

. "${HOME}/.local/lib/util.sh"

DIR_MBSYNC_CONFIG="${HOME}/.config/mbsync"
MBSYNC_CONFIG_DEFAULT="${DIR_MBSYNC_CONFIG}/config"

CHANNEL_INBOX="C_INBOX"
CHANNEL_ELSE="C_ELSE"
GROUP_ALL="G_ALL"

__config() {
    local _ACCOUNT="ACCOUNT"

    local _PATH_REMOTE="REMOTE"
    local _PATH_LOCAL_INBOX="LOCAL_INBOX" _PATH_LOCAL_ELSE="LOCAL_ELSE"

    __commit() {
        local _config
        if [ "${#}" -eq 0 ]; then
            _config="${MBSYNC_CONFIG_DEFAULT}"
        else
            _config="${DIR_MBSYNC_CONFIG}/${1}"
            true >"${_config}"
        fi

        cat - >>"${_config}"
        chmod 600 -- "${_config}"
    }

    __base() {
        cat <<STOP
SyncState *
Create Both
Remove Both
Expunge Both

STOP
    }

    __remote() {
        printf "IMAPAccount %s\n" "${_ACCOUNT}"

        cat -
        printf "\n"

        printf "IMAPStore %s\n" "${_PATH_REMOTE}"
        printf "Account %s\n" "${_ACCOUNT}"
    }

    __channels() {
        local _dir_mail='~'"/.local/share/mail/raw/${1}"
        shift

        local _inbox="INBOX"

        cat <<STOP
MaildirStore ${_PATH_LOCAL_INBOX}
SubFolders Maildir++
Inbox ${_dir_mail}/.${_inbox}

Channel ${CHANNEL_INBOX}
Far :${_PATH_REMOTE}:
Near :${_PATH_LOCAL_INBOX}:
Patterns "${_inbox}"
STOP

        printf "\n"

        cat <<STOP
MaildirStore ${_PATH_LOCAL_ELSE}
SubFolders Maildir++
Inbox ${_dir_mail}

Channel ${CHANNEL_ELSE}
Far :${_PATH_REMOTE}:
Near :${_PATH_LOCAL_ELSE}:
STOP

        printf "Patterns * !\"%s\"" "${_inbox}"
        local _ignore
        for _ignore in "${@}"; do
            printf " !\"%s\"" "${_ignore}"
        done
        printf "\n"
    }

    __passcmd() {
        case "${1}" in
            "oauth")
                shift
                printf "PassCmd \"python ~/dot/dot/d_mail/src/oauth2/mutt_oauth2.py ~/.password-store/Dox/mail/%s.tokens.gpg\"" "${1}"
                ;;
            "pass")
                shift
                printf "PassCmd \"pass Dox/mail/%s | head -n 1\"" "${1}"
                ;;
        esac
        printf "\n"
    }

    __final() {
        cat <<STOP
Group ${GROUP_ALL}
Channel ${CHANNEL_INBOX}
Channel ${CHANNEL_ELSE}
STOP
    }

    case "${1}" in
        "base")
            shift
            __base "${@}"
            ;;
        "remote")
            __remote
            ;;
        "channels")
            shift
            __channels "${@}"
            ;;
        "pass")
            shift
            __passcmd "${@}"
            ;;
        "final")
            __final
            ;;
        "commit")
            shift
            __commit "${@}"
            ;;
    esac
}

__find_accounts() {
    find "${DIR_MBSYNC_CONFIG}/" -mindepth 1 -maxdepth 1 -printf "%P\n" | grep -v "config" | sort -n
}

__config_clear() {
    __find_boxes() {
        find -L "${DIR_MAIL_RAW}/${1}/" -mindepth 1 -maxdepth 1 -printf "%P\n" | sort -n
    }

    __f() {
        local _file_mbsync _file_uid
        _file_mbsync="${1}/.mbsyncstate"
        if [ -e "${_file_mbsync}" ]; then
            printf "inbox> rm [%s]\n" "${_file_mbsync}"
        fi
        _file_uid="${1}/.uidvalidity"
        if [ -e "${_file_uid}" ]; then
            printf "inbox> rm [%s]\n" "${_file_uid}"
        fi
    }

    local _account _box
    __find_accounts | __fzf --multi | while read -r _account; do
        __find_boxes "${_account}" | __fzf --multi | while read -r _box; do
            __f "${DIR_MAIL_RAW}/${_account}/${_box}"
        done
    done
}

__mbsync() {
    local _verbose=""
    while [ "${#}" -gt 0 ]; do
        case "${1}" in
            "--verbose")
                _verbose="yes"
                shift
                ;;
            "--")
                shift && break
                ;;
        esac
    done

    local _config="${DIR_MBSYNC_CONFIG}/${1}"
    if [ -e "${_config}" ]; then
        if [ "${_verbose}" ]; then
            printf "mbsync> %s/inbox\n" "${1}" &&
                mbsync -v -c "${_config}" "${CHANNEL_INBOX}" &&
                printf "\n" &&
                printf "mbsync> %s/else\n" "${1}" &&
                mbsync -v -c "${_config}" "${CHANNEL_ELSE}"
            return
        fi

        mbsync -c "${_config}" "${GROUP_ALL}" 2>&1 |
            grep -v "^Maildir warning: ignoring INBOX in " |
            grep -v "^Processed .* box(es) in .* channel(s),$"
        return
    fi

    if [ "${_verbose}" ]; then
        printf "mbsync> %s/inbox\n" "${1}" &&
            mbsync -v -c "${MBSYNC_CONFIG_DEFAULT}" "${1}_INBOX" &&
            printf "\n" &&
            printf "mbsync> %s/else\n" "${1}" &&
            mbsync -v -c "${MBSYNC_CONFIG_DEFAULT}" "${1}_ELSE"
        return
    fi
    mbsync -c "${MBSYNC_CONFIG_DEFAULT}" "${1}" 2>&1 |
        grep -v "^Maildir warning: ignoring INBOX in " |
        grep -v "^Processed .* box(es) in .* channel(s),$"
}

__test() {
    if [ "${1}" = "--" ]; then shift; fi

    __f() {
        local _attempt=0
        while true; do
            if [ "${_attempt}" -eq 0 ]; then
                printf "mbsync> %s\n" "${1}"
            else
                printf "mbsync> %s [retry: %s]\n" "${1}" "${_attempt}"
            fi

            if __mbsync -- "${1}"; then
                break
            fi

            _attempt=$((_attempt + 1))
            printf "\n"
        done
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
    "clear")
        shift
        __config_clear
        ;;
    "test")
        shift
        __test "${@}"
        ;;
    *)
        __mbsync "${@}"
        ;;
esac
