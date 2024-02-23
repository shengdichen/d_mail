#!/usr/bin/env dash

SCRIPT_PATH="$(realpath "$(dirname "${0}")")"
cd "${SCRIPT_PATH}" || exit 3

__create_boxes_local() {
    local _mail_path="./.local/share/mail/"
    mkdir -p "${_mail_path}"

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
        cd "${_mail_path}" || exit 3

        for d in "draft" "hold" "trash" "x"; do
            __f --maildir "./all/.${d}"
        done
        # account-specific folders are auto-created with mbsync
    )

    unset -f __f
}

__mbsync() {
    # HACK:
    #   use mbsync to implicitly auto-create account-specific folders

    # try a few times to cater for random sync failures
    for __ in $(seq 3); do
        mbsync -c "./.config/mbsync/config" --all
    done
}

__fdm() {
    chmod 600 "./.config/fdm/config"

    case "${1}" in
        "update")
            fdm -f "./.config/fdm/config" fetch
            ;;
    esac
}

__notmuch() {
    local _notmuch_path="./.local/share/notmuch/default/"
    mkdir -p "${_notmuch_path}"

    local _dump_file="notmuch.dump"
    case "${1}" in
        "update")
            notmuch new
            ;;
        "export")
            notmuch dump --output="${_notmuch_path}/${_dump_file}"
            ;;
        "import")
            notmuch new
            notmuch restore --input="${_notmuch_path}/${_dump_file}"
            ;;
    esac
}

__stow() {
    (
        cd .. && stow -R "$(basename "${SCRIPT_PATH}")"
    )
}

__update() {
    __mbsync
    __fdm update
    __notmuch update
}

__setup() {
    __create_boxes_local
    __fdm
    __notmuch

    __stow

    __update
}

main() {
    case "${1}" in
        "update")
            __update
            ;;
        "notmuch")
            shift
            __notmuch "${@}"
            ;;
        *)
            __setup
            ;;
    esac

    unset SCRIPT_PATH
    unset -f __create_boxes_local __mbysnc __fdm __notmuch __stow __update __setup
}
main "${@}"
unset -f main
