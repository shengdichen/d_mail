#!/usr/bin/env bash

. "${HOME}/.local/lib/util.sh"

SCRIPT_PATH="$(realpath "$(dirname "${0}")")"
FILE_CONST="$(realpath "${SCRIPT_PATH}/..")/const.sh"
DIR_MAIL_REMOTE="$("${FILE_CONST}" DIR_MAIL_REMOTE)"

ACCOUNTS=()
__discover_accounts() {
    local _account
    while read -r _account; do
        ACCOUNTS+=("${_account}")
    done < <(
        find "${DIR_MAIL_REMOTE}" -mindepth 1 -maxdepth 1 -type d -printf "%P\n"
    )
}
__discover_accounts

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
        local _prompt="|"
        while [ "${#}" -gt 0 ]; do
            case "${1}" in
                "--prompt")
                    _prompt="${2}"
                    shift 2
                    ;;
                "--")
                    shift && break
                    ;;
            esac
        done
        printf -- "%s %s" "${_prompt}" "${1}"
    }

    __box_as_string() {
        local _box
        _box="$(printf "%s" "${1}" | sed "s/^\.//")" # truncate leading |.| of maildir
        printf "  /%s" "${_box}"
    }

    __notmuch_atom_folder() {
        # REF:
        #   https://notmuch.readthedocs.io/en/latest/man7/notmuch-search-terms.html
        # NOTE:
        #   $ notmuch count 'folder:"/<REGEX>/"'
        #   $ notmuch count 'folder:"<EXACT_PATH_ENDING_WITH_/>"'
        # 1. NOT box-level (leaf) -> REGEX
        #   $ notmuch count 'folder:"/.*/"'
        #   $ notmuch count 'folder:"/raw/.*/"'
        #   $ notmuch count 'folder:"/raw/.*/\..*/"'
        #   $ notmuch count 'folder:"/raw/xyz/\..*/"'
        # 2. box-level (leaf) -> REGEX OR EXACT
        #   $ notmuch count 'folder:"raw/xyz/.INBOX/"'
        #   $ notmuch count 'folder:"/raw/xyz/\.INBOX/"'

        local _mode="account"
        while [ "${#}" -gt 0 ]; do
            case "${1}" in
                "--mode")
                    _mode="${2}"
                    shift 2
                    ;;
                "--")
                    shift && break
                    ;;
            esac
        done

        local _query="${1}" _use_regex="yes"
        case "${_mode}" in
            "root")
                _query="${1}/.*"
                ;;
            "account")
                _query="${1}/\\\\..*"
                ;;
            "box")
                _query="${1}/"
                _use_regex=""
                ;;
        esac
        if [ "${_use_regex}" ]; then
            printf "folder:\\\\\"/%s/\\\\\"" "${_query}"
            return
        fi
        printf "folder:\\\\\"%s\\\\\"" "${_query}"
    }

    __notmuch_query() {
        __quote --single "notmuch://?query=${1}"
    }

    __notmuch_query_folder() {
        __quote --single "notmuch://?query=$(__notmuch_atom_folder "${1}")"
    }

    __notmuch_show() {
        printf "virtual-mailboxes " && LINECONT

        while [ "${#}" -gt 0 ]; do
            __quote "${1}" && printf " %s " "${2}" && LINECONT
            shift 2
        done
    }

    __notmuch_hide() {
        printf "unvirtual-mailboxes " && LINECONT

        local _url
        for _url in "${@}"; do
            printf "%s " "${_url}" && LINECONT
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
        local _account _inbox=".INBOX" _sent=".Sent" _archive=".x"
        while [ "${#}" -gt 0 ]; do
            case "${1}" in
                "--account")
                    _account="${2}"
                    shift 2
                    ;;
                "--inbox")
                    _inbox="${2}"
                    shift 2
                    ;;
                "--sent")
                    _inbox="${2}"
                    shift 2
                    ;;
                "--archive")
                    _archive="${2}"
                    shift 2
                    ;;
            esac
        done

        cat <<STOP
set folder = "${_mail_raw_absolute}/${_account}"

STOP

        local _boxes_str=() _boxes=()
        __box() {
            if [ "${1}" = "--alias" ]; then
                _boxes_str+=("$(__box_as_string "${2}")")
                shift 2
            else
                _boxes_str+=("$(__box_as_string "${1}")")
            fi
            _boxes_str+=("${_mail_raw_relative}/${_account}/\\${1}.*")
            _boxes+=("${_mail_raw_relative}/${_account}/\\${1}.*")
        }
        [ "${_inbox}" ] && __box --alias "INBOX" "${_inbox}"
        [ "${_sent}" ] && __box --alias "SENT" "${_sent}"
        [ "${_archive}" ] && __box --alias "ARCHIVE" "${_archive}"
        local _box
        while read -r _box; do
            __box "${_box}"
        done < <(
            find "${DIR_MAIL_REMOTE}/${_account}" -mindepth 1 -maxdepth 1 -type d -printf "%P\n" |
                grep -v "${_inbox}" | grep -v "${_sent}" | grep -v "${_archive}" |
                sort -n
        )

        local _accounts_else=() _account_else
        for _account_else in "${ACCOUNTS[@]}"; do
            if [ "${_account_else}" != "${_account}" ]; then
                _accounts_else+=("${_mail_raw_relative}/${_account_else}/\\..*")
            fi
        done

        local _account_this="${_mail_raw_relative}/${_account}/\\..*"

        {
            __run --exec "exec vfolder-from-query" && LINECONT
            __notmuch_atom_folder "${_mail_raw_relative}/${_account}.*" && printf " and" && LINECONT
        } | __bind --key "/b" --mode "index" --description "notmuch> folder:[${_account}]"

        printf "\n"

        {
            __notmuch_show "$(__account_as_string --prompt ">" -- "${_account}")" "${_account_this}" | __run --exec && LINECONT
            __notmuch_hide "${_accounts_else[@]}" | __run --exec && LINECONT
            __notmuch_show "${_boxes_str[@]}" | __run --exec && LINECONT
            __run "check-stats" && LINECONT
        } | __bind --key "cb" --mode "index" --description "notmuch> folder:[${_account}]/*"

        printf "\n"

        {
            __notmuch_hide "${_boxes[@]}" | __run --exec && LINECONT
            # HACK:
            #   first hide all accounts, then use key-bind |ca| to re-show
            #   ->  order of accounts guaranteed
            __notmuch_hide "${_account_this}" | __run --exec && LINECONT
            printf "ca" && LINECONT
        } | __bind --key "cB" --mode "index" --description "notmuch> folder:[${_account}]/*"
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

        local _names_urls=() _urls=()
        local _account _url
        for _account in "${@}"; do
            _url="$(__notmuch_query "$(__notmuch_atom_folder -- "${_mail_raw_relative}/${_account}")")"
            _names_urls+=("$(__account_as_string -- "${_account}")")
            _names_urls+=("${_url}")
            _urls+=("${_url}")
        done
        {
            {
                __notmuch_show "${_names_urls[@]}" | __run --exec && LINECONT
                __run "check-stats" && LINECONT
            } | __bind --key "ca" --mode "index" --description "notmuch> show all"

            printf "\n"

            {
                __notmuch_hide "${_urls[@]}" | __run --exec && LINECONT
                __run "check-stats" && LINECONT
            } | __bind --key "cA" --mode "index" --description "notmuch> hide all"

            printf "\n"

            local _conf
            for _account in "${@}"; do
                _conf="$(__quote "\$my_conf_neomutt/box/specific/${_account}.conf")"
                printf "folder-hook -noregex \"%s/%s\" \"source %s\"\n" "${_mail_raw_relative}" "${_account}" "${_conf}"
                printf "folder-hook -noregex \"%s\" \"source %s\"\n" "$(__account_as_string -- "${_account}")" "${_conf}"
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
