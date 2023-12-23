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
        cd "./.local/share/mail/" || exit 3

        for d in "eth" "gmail" "outlook"; do
            __f "./raw/${d}"
        done

        for d in "xyz/.INBOX" "xyz/.Sent"; do
            __f --maildir "./raw/${d}"
        done
        for d in "draft" "hold" "trash" "x"; do
            __f --maildir "./all/.${d}"
        done
    )

    unset -f __f
}

__fdm_conf() {
    chmod 600 "./.config/fdm/config"
}

__sync_all() {
    mbsync --all
}

__notmuch() {
    local dump_file="notmuch.dump"
    case "${1}" in
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
    __create_box
    __fdm_conf
    __stow

    unset SCRIPT_PATH
    unset -f __create_box __fdm_conf __sync_all __notmuch __stow
}
main
unset -f main
