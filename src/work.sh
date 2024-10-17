#!/usr/bin/env dash

. "${HOME}/.local/lib/util.sh"

SCRIPT_PATH="$(realpath "$(dirname "${0}")")"

__post() {
    __fdm() {
        printf "post> fdm\n"

        local _config="${HOME}/.config/fdm/config"
        chmod 600 -- "${_config}"
        fdm -f "${_config}" "${@}"
    }

    __fdm fetch
    __separator
    "${SCRIPT_PATH}/notmuch.sh" update
    __separator
    printf "post> done! "
    read -r _
}

__main() {
    case "${1}" in
        "post")
            __post
            ;;
        "pipe")
            "${SCRIPT_PATH}/mbsync.sh" test -- "ALL"
            __separator --breaks-before 0 --breaks-after 0
            __post
            ;;
    esac
}
__main "${@}"
