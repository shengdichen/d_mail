#!/usr/bin/env dash

__main() {
    local _dir_mail_relative=".local/share/mail"
    local _dir_mail="${HOME}/${_dir_mail_relative}"

    local _dir_mail_local="${_dir_mail}/all"

    local _dir_mail_backup="${HOME}/.local/share/mailback"

    case "${1}" in
        "DIR_MAIL_RELATIVE")
            printf "%s" "${_dir_mail_relative}"
            ;;
        "DIR_MAIL")
            printf "%s" "${_dir_mail}"
            ;;
        "DIR_MAIL_LOCAL")
            printf "%s" "${_dir_mail_local}"
            ;;
        "DIR_MAIL_TRASH")
            printf "%s" "${_dir_mail_local}/.trash"
            ;;
        "DIR_MAIL_HOLD")
            printf "%s" "${_dir_mail_local}/.hold"
            ;;

        "DIR_MAIL_REMOTE")
            printf "%s" "${_dir_mail}/raw"
            ;;
        "DIR_MAIL_BACKUP")
            printf "%s" "${HOME}/.local/share/mailback"
            ;;

        "DIR_NOTMUCH")
            printf "%s" "${HOME}/.local/share/notmuch"
            ;;
        "DIR_NOTMUCH_CONFIG")
            printf "%s" "${HOME}/.config/notmuch/default"
            ;;
    esac
}
__main "${1}"
