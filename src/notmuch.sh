#!/usr/bin/env dash

. "${HOME}/.local/lib/util.sh"

SCRIPT_PATH="$(realpath "$(dirname "${0}")")"

DIR_NOTMUCH="$("${SCRIPT_PATH}/const.sh" DIR_NOTMUCH)"
DIR_DUMP="${DIR_NOTMUCH}/default"

__update() {
    printf "post> notmuch\n"

    notmuch new 2>&1 |
        grep -v "^Note: Ignoring non-mail file: .*/\.mbsyncstate" |
        grep -v "Note: Ignoring non-mail file: .*/\.uidvalidity"
}

__export() {
    local _dump
    _dump="${DIR_DUMP}/notmuch-$(date -u --iso-8601=seconds).dump"

    printf "notmuch> dumping to [%s]\n" "${_dump}"
    notmuch dump --output "${_dump}"
}

__import() {
    local _n_mails
    _n_mails="$(notmuch count)"
    if [ "${_n_mails}" -ne 0 ]; then
        printf "notmuch> db already exists with [%s] mails, " "${_n_mails}"
        printf "what now?\n"

        case "$(__fzf_opts "quit" "proceed (dangerous!)")" in
            "quit")
                printf "notmuch> try deleting db [%s/xapian]\n" "${DIR_DUMP}"
                printf "       > then try again; exiting for now\n"
                exit
                ;;
            "proceed")
                printf "notmuch> continuing on, overwriting current db\n"
                ;;
        esac
    fi

    if [ "${1}" = "--" ]; then shift; fi
    local _dump
    if [ "${#}" -eq 0 ]; then
        _dump="${DIR_DUMP}/$(
            find "${DIR_DUMP}" -mindepth 1 -maxdepth 1 -type f -printf "%P\n" | __fzf
        )"
    else
        _dump="${1}"
        if [ ! -e "${_dump}" ]; then
            _dump="${DIR_DUMP}/${1}"
            if [ ! -e "${_dump}" ]; then
                printf "notmuch> restore file non-existent, exiting [%s]\n" "${1}"
                exit 3
            fi
        fi
    fi

    notmuch restore --input "${_dump}"
}

if [ "${#}" -eq 0 ]; then return; fi
case "${1}" in
    "update")
        __update
        ;;
    "export")
        __export
        ;;
    "import")
        shift
        __import "${@}"
        ;;
esac
