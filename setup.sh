#!/usr/bin/env dash

SCRIPT_PATH="$(realpath "$(dirname "${0}")")"
cd "${SCRIPT_PATH}" || exit 3

__create_box() {
    __f() {
        local maildir=""
        if [ "${1}" = "--maildir" ]; then
            maildir="yes"
            shift
        fi
        local target="${1}"

        mkdir -p "${target}"
        chmod 700 "${target}"
        if [ "${maildir}" ]; then
            for maild in "cur" "new"; do
                mkdir -p "${target}/${maild}"
                chmod 700 "${target}/${maild}"
            done
        fi
    }

    (
        local _mail_path="./.local/share/mail/"
        mkdir -p "${_mail_path}"
        cd "${_mail_path}" || exit 3

        for d in "draft" "hold" "trash" "x"; do
            __f --maildir "./all/.${d}"
        done
        # account specific folders are auto-created with mbsync
    )

    unset -f __f
}

__fdm_conf() {
    chmod 600 "./.config/fdm/config"
}

__sync_all() {
    mbsync -c "./config/mbsync/config" --all
}

__notmuch() {
    local dump_file="notmuch.dump"
    case "${1}" in
        "setup")
            mkdir -p "./.local/share/notmuch/default"
            ;;
        "export")
            notmuch dump --output="${dump_file}"
            ;;
        "import")
            notmuch new
            notmuch restore --input="${dump_file}"
            ;;
        *)
            exit 3
            ;;
    esac
}

__stow() {
    (
        cd .. && stow -R "$(basename "${SCRIPT_PATH}")"
    )
}

main() {
    case "${1}" in
        "sync")
            __sync_all
            ;;
        "notmuch")
            shift
            __notmuch "${@}"
            ;;
        *)
            __create_box
            __fdm_conf
            __notmuch setup
            __stow
            ;;
    esac

    __create_box
    __fdm_conf
    __stow

    unset SCRIPT_PATH
    unset -f __create_box __fdm_conf __sync_all __notmuch __stow
}
main "${@}"
unset -f main
