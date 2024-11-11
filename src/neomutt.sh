#!/usr/bin/env bash

SCRIPT_PATH="$(realpath "$(dirname "${0}")")"
FILE_CONST="$(realpath "${SCRIPT_PATH}/..")/const.sh"
DIR_MAIL_REMOTE="$("${FILE_CONST}" DIR_MAIL_REMOTE)"

LINECONT() {
    printf "\\\\\n"
}

__config() {
    local _conf_neomutt="\$my_conf_neomutt"
    local _mail_raw_relative="\$my_mail_raw_relative_path"
    local _mail_raw_absolute="\$my_mail_raw_absolute_path"

    __quote() {
        local _single
        if [ "${1}" = "--single" ]; then
            _single="yes"
            shift
        fi

        if [ "${_single}" ]; then
            printf "'"
        else
            printf "\\\\\""
        fi

        if [ "${#}" -eq 0 ]; then
            cat -
        else
            printf "%s" "${1}"
        fi

        if [ "${_single}" ]; then
            printf "'"
        else
            printf "\\\\\""
        fi
    }

    __account_as_string() {
        printf "| %s" "${1}"
    }

    __notmuch_atom_folder() {
        # REF:
        #   https://notmuch.readthedocs.io/en/latest/man7/notmuch-search-terms.html#quoting
        # folder:\"/<${1}>/\"
        printf "folder:\\\\\"/%s/\\\\\"" "${1}"
    }

    __notmuch_query_folder() {
        __quote --single "notmuch://?query=$(__notmuch_atom_folder "${1}")"
    }

    __notmuch_show() {
        printf "virtual-mailboxes " && LINECONT

        while [ "${#}" -gt 0 ]; do
            __quote "${1}" && printf " " &&
                __notmuch_query_folder "${2}" && printf " " &&
                LINECONT
            shift 2
        done
    }

    __notmuch_hide() {
        printf "unvirtual-mailboxes " && LINECONT

        local _account
        for _account in "${@}"; do
            __notmuch_query_folder "${_account}" && printf " " &&
                LINECONT
        done
    }

    __run() {
        local _line
        if [ "${1}" = "--exec" ]; then
            shift
            printf "<enter-command>"
            if [ "${#}" -eq 0 ]; then
                cat -
            else
                printf "%s" "${1}"
            fi
        else
            if [ "${#}" -eq 0 ]; then
                while read -r _line; do
                    printf "<"
                    printf "%s" "${_line}"
                    printf ">"
                done
            else
                for _line in "${@}"; do
                    printf "<"
                    printf "%s" "${_line}"
                    printf ">"
                done
            fi
        fi
        printf "<Return>"
    }

    __run_script() {
        __run --exec "set wait_key=no" && LINECONT

        printf "<shell-escape>%s" "${1}"
        shift
        for _arg in "${@}"; do
            printf " %s" "${_arg}"
        done
        printf "<Return>"
        LINECONT

        __run --exec "set wait_key=yes" && LINECONT
    }

    __bind() {
        local _key _mode _description
        while [ "${#}" -gt 0 ]; do
            case "${1}" in
                "--key")
                    _key="${2}"
                    shift 2
                    ;;
                "--mode")
                    _mode="${2}"
                    shift 2
                    ;;
                "--description")
                    _description="${2}"
                    shift 2
                    ;;
                "--")
                    shift && break
                    ;;
            esac
        done

        printf "macro %s %s \"" "${_mode}" "${_key}" && LINECONT
        cat -
        printf "\" \"%s\"\n" "${_description}"
    }

    __box_base() {
        local _account
        while [ "${#}" -gt 0 ]; do
            case "${1}" in
                "--account")
                    _account="${2}"
                    shift 2
                    ;;
            esac
        done

        cat <<STOP
set folder = "${_mail_raw_absolute}/${_account}"

STOP
        {
            __run --exec "exec vfolder-from-query" && LINECONT
            __notmuch_atom_folder "${_mail_raw_relative}/${_account}.*" && printf " and" && LINECONT
        } | __bind --key "/b" --mode "index" --description "notmuch> folder:[${_account}]"
    }

    __box_sync() {
        local _account
        while [ "${#}" -gt 0 ]; do
            case "${1}" in
                "--account")
                    _account="${2}"
                    shift 2
                    ;;
            esac
        done

        {
            printf "sm" && LINECONT
            __run_script "\$my_conf_dmail/mbsync.sh" "test" "--" "${_account}"
            printf "ss" && LINECONT
        } |
            __bind --key "sb" --mode "index" --description "mbsync> ${_account}"
    }

    __box_send() {
        local _addr _account _dir_send_copy
        while [ "${#}" -gt 0 ]; do
            case "${1}" in
                "--addr")
                    _addr="${2}"
                    shift 2
                    ;;
                "--account")
                    _account="${2}"
                    shift 2
                    ;;
                "--dir-send-copy")
                    _dir_send_copy="${2}"
                    shift 2
                    ;;
            esac
        done

        cat <<STOP
# send {{{
source "${_conf_neomutt}/box/common/compose.conf"

set record = "${_dir_send_copy}"
set from = "${_addr}"
my_hdr Reply-To: "${_addr}"

set sendmail = "\$my_conf_dmail/msmtp.sh --account ${_account}"
# }}}
STOP
    }

    __commit_box() {
        {
            cat -
            cat <<STOP

# vim: filetype=neomuttrc foldmethod=marker
STOP
        } >"${HOME}/dot/dot/d_mail/raw/.config/neomutt/box/specific/${1}.conf"
    }

    __multi() {
        if [ "${1}" = "--" ]; then shift; fi

        local _account
        {
            {
                {
                    local _args=()
                    for _account in "${@}"; do
                        _args+=("$(__account_as_string "${_account}")")
                        _args+=("${_mail_raw_relative}/${_account}/\\..*")
                    done
                    __notmuch_show "${_args[@]}"
                } | __run --exec && LINECONT
                __run "check-stats" && LINECONT
            } | __bind --key "ca" --mode "index" --description "notmuch> show all"

            printf "\n"

            {
                {
                    local _accounts=()
                    for _account in "${@}"; do
                        _accounts+=("${_mail_raw_relative}/${_account}/\\..*")
                    done
                    __notmuch_hide "${_accounts[@]}"
                } | __run --exec && LINECONT
                __run "check-stats" && LINECONT
            } | __bind --key "cA" --mode "index" --description "notmuch> hide all"

            printf "\n"

            local _conf
            for _account in "${@}"; do
                _conf="$(__quote "\$my_conf_neomutt/box/specific/${_account}.conf")"
                printf "folder-hook -noregex \"%s/%s\" \"source %s\"\n" "${_mail_raw_relative}" "${_account}" "${_conf}"
                printf "folder-hook -noregex \"%s\" \"source %s\"\n" "$(__account_as_string "${_account}")" "${_conf}"
            done

            cat <<STOP

# vim: filetype=neomuttrc
STOP
        } >"${HOME}/dot/dot/d_mail/raw/.config/neomutt/box/multi.conf"
    }

    case "${1}" in
        "box-base")
            shift
            __box_base "${@}"
            ;;
        "box-sync")
            shift
            __box_sync "${@}"
            ;;
        "box-send")
            shift
            __box_send "${@}"
            ;;
        "commit-box")
            shift
            __commit_box "${@}"
            ;;
        "multi")
            shift
            __multi "${@}"
            ;;
    esac

}
case "${1}" in
    "config")
        shift
        __config "${@}"
        ;;
    *)
        exit 3
        ;;
esac
