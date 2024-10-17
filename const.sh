#!/usr/bin/env dash

__main() {
    local _dir_mail="${HOME}/.local/share/mail"
    local _dir_mail_backup="${HOME}/.local/share/mailback"

    case "${1}" in
        "DIR_MAIL")
            printf "%s" "${_dir_mail}"
            ;;
        "DIR_MAIL_LOCAL")
            printf "%s" "${_dir_mail}/all"
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
    esac
}
__main "${1}"
