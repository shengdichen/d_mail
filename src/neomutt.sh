#!/usr/bin/env dash

__config() {
    local _conf_neomutt="\$my_conf_neomutt"
    local _mail_raw_relative="\$my_mail_raw_relative_path"
    local _mail_raw_absolute="\$my_mail_raw_absolute_path"

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

macro index /b "\\
<enter-command>\\
exec vfolder-from-query<Return>\\
folder:/${_mail_raw_relative}\\\/${_account}/ and \\
" "notmuch folder:[${_account}]"
STOP
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

        cat <<STOP
macro index sb "\\
sm\\
<enter-command>set wait_key=no<Return>\\
<shell-escape>\$my_conf_dmail/mbsync.sh test -- ${_account}<Return>\\
<enter-command>set wait_key=yes<Return>\\
ss\\
" "mbsync [${_account}]"
STOP
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

        __quote() {
            printf "\\\\\""
            if [ "${#}" -eq 0 ]; then
                cat -
            else
                printf "%s" "${1}"
            fi

            printf "\\\\\""
        }

        __account_as_string() {
            printf "| %s" "${_account}"
        }

        local _account
        {
            cat <<STOP
macro index ca "\\
<enter-command>\\
virtual-mailboxes \\
STOP
            for _account in "${@}"; do
                __quote "$(__account_as_string "${_account}")"
                printf " "
                __quote "notmuch://?query=folder:/${_mail_raw_relative}/${_account}/\\\\..*/"
                printf " \\\\\n"
            done
            cat <<STOP
<Return>\\
<check-stats>\\
" "notmuch> show all"
STOP

            printf "\n"

            cat <<STOP
macro index cA "\\
<enter-command>\\
unvirtual-mailboxes \\
STOP

            for _account in "${@}"; do
                __quote "notmuch://?query=folder:/${_mail_raw_relative}/${_account}/\\\\..*/"
                printf " \\\\\n"
            done
            cat <<STOP
<Return>\\
<check-stats>\\
" "notmuch> hide all"
STOP

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
