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
        # account-specific folders are auto-created with mbsync
    )

    unset -f __f
}

__fdm_conf() {
    chmod 600 "./.config/fdm/config"

    case "${1}" in
        "update")
            fdm -f "./.config/fdm/config" fetch
            ;;
    esac
}

__mbsync() {
    # NOTE:
    #   use mbsync to auto-create account-specific folders
    mbsync -c "./.config/mbsync/config" --all
}

__notmuch() {
    mkdir -p "./.local/share/notmuch/default"

    local dump_file="notmuch.dump"
    case "${1}" in
        "export")
            notmuch dump --output="${dump_file}"
            ;;
        "import")
            notmuch new
            notmuch restore --input="${dump_file}"
            ;;
        "update")
            notmuch new
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
            __mbsync
            ;;
        "notmuch")
            shift
            __notmuch "${@}"
            ;;
        *)
            __create_box && __fdm_conf && __notmuch
            __stow
            # try a few times to cater for random sync failures
            for __ in $(seq 3); do __mbsync; done
            __fdm_conf update
            __notmuch update
            ;;
    esac

    unset SCRIPT_PATH
    unset -f __create_box __fdm_conf __mbsync __notmuch __stow
}
main "${@}"
unset -f main
