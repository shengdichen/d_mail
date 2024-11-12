#!/usr/bin/env dash

. "${HOME}/.local/lib/util.sh"

SCRIPT_PATH="$(realpath "$(dirname "${0}")")"

DIR_NOTMUCH="$("$(realpath "${SCRIPT_PATH}/..")/const.sh" DIR_NOTMUCH)"
DIR_DUMP="${DIR_NOTMUCH}/default"

__update() {
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

__list_tags() {
    notmuch search --output tags "*"
}

__taggedness() {
    local _query_local="folder:\"/all/.*/\""
    local _query_remote="folder:\"/raw/.*/\""
    local _TAG_LOCAL="_LOCAL"
    local _TAG_REMOTE="_REMOTE"
    local _TAG_LOCAL_UNTAGGED="_UNTAGGED"
    local _TAG_LOCAL_TAGGED="_TAGGED"

    __local() {
        local _query="${_query_local}"
        printf "notmuch/tag> local...\n"
        eval notmuch tag \
            "+${_TAG_LOCAL}" \
            "-${_TAG_REMOTE}" \
            "${_query}"
        printf "notmuch/tag> done! (#local := [%s])\n" "$(eval notmuch count "${_query}")"
    }

    __remote() {
        local _query="${_query_remote}"
        printf "notmuch/tag> remote...\n"
        eval notmuch tag \
            "+${_TAG_REMOTE}" \
            "-${_TAG_LOCAL}" \
            "${_query}"
        printf "notmuch/tag> done! (#remote := [%s])\n" "$(eval notmuch count "${_query}")"
    }

    __untagged() {
        __list_tags | {
            local _query="${_query_local}"

            local _tag
            while read -r _tag; do
                if [ ! "$(printf "%s" "${_tag}" | head -c "+1")" = "_" ]; then
                    _query="${_query} and not tag:${_tag}"
                fi
            done

            printf "notmuch/local> marking UNtagged...\n"
            eval notmuch tag \
                "+${_TAG_LOCAL_UNTAGGED}" \
                "-${_TAG_LOCAL_TAGGED}" \
                "${_query}"
            printf "notmuch/local> done! (#UNtagged := [%s])\n" "$(eval notmuch count "${_query}")"
        }
    }

    __tagged() {
        local _query="${_query_local} and not tag:${_TAG_LOCAL_UNTAGGED}"
        printf "notmuch/local> #tagged := [%s]\n" "$(notmuch count "${_query}")"
        printf "notmuch/local> marking tagged...\n"
        eval notmuch tag \
            "+${_TAG_LOCAL_TAGGED}" \
            "-${_TAG_LOCAL_UNTAGGED}" \
            "${_query}"
        printf "notmuch/local> done! (#UNtagged := [%s])\n" "$(eval notmuch count "${_query}")"
    }

    __local
    __remote
    __untagged
    __tagged
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
    "tag")
        __taggedness
        ;;
esac
