#!/usr/bin/env dash

. "${HOME}/.local/lib/util.sh"

SCRIPT_PATH="$(realpath "$(dirname "${0}")")"

__post() {
    printf "post> fdm\n"
    "${SCRIPT_PATH}/fdm.sh"

    __separator

    printf "post> notmuch\n"
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
