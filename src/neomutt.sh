#!/usr/bin/env dash

__config() {
    local _conf_neomutt="\$my_conf_neomutt"
    local _mail_raw_relative="\$my_mail_raw_relative_path"
    local _mail_raw_absolute="\$my_mail_raw_absolute_path"

    __commit_box() {
        {
            cat -
            cat <<STOP

# vim: filetype=neomuttrc foldmethod=marker
STOP
        } >"${HOME}/dot/dot/d_mail/raw/.config/neomutt/box/specific/${1}/specific.conf"
    }

    __box_base() {
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
# box {{{
set folder = "${_mail_raw_absolute}/${_account}"
set record = "${_dir_send_copy}"
# }}}

macro index sb "\\
sm\\
<enter-command>set wait_key=no<Return>\\
<shell-escape>\$my_conf_dmail/mbsync.sh test -- ${_account}<Return>\\
<enter-command>set wait_key=yes<Return>\\
ss\\
" "push to remote"

macro index /b "\\
<enter-command>\\
exec vfolder-from-query<Return>\\
folder:/${_mail_raw_relative}\\\/${_account}/ and \\
" "query box"

STOP
    }

    __box_send() {
        local _addr _account
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
            esac
        done

        cat <<STOP
# compose {{{
source "${_conf_neomutt}/box/common/compose.conf"

set from = "${_addr}"
my_hdr Reply-To: "${_addr}"

set sendmail = "\$my_conf_dmail/msmtp.sh --account ${_account}"
# }}}
STOP
    }

    case "${1}" in
        "box-base")
            shift
            __box_base "${@}"
            ;;
        "box-send")
            shift
            __box_send "${@}"
            ;;
        "commit-box")
            shift
            __commit_box "${@}"
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
