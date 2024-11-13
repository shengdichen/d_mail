#!/usr/bin/env dash

. "${HOME}/.local/lib/util.sh"

SCRIPT_PATH="$(realpath "$(dirname "${0}")")"

FILE_CONST="$(realpath "${SCRIPT_PATH}/..")/const.sh"
DIR_NOTMUCH="$("${FILE_CONST}" DIR_NOTMUCH)"
DIR_DUMP="${DIR_NOTMUCH}/default"

__report_count() {
    printf "notmuch> #%s\n" "$(notmuch count -- "*")"
}

__update() {
    notmuch new 2>&1 |
        grep -v "^Note: Ignoring non-mail file: .*/\.mbsyncstate$" |
        grep -v "^Note: Ignoring non-mail file: .*/\.uidvalidity$" |
        grep -v "^No new mail.$" # not exactly useful information
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

__tag() {
    local _query_all="mid:\"/.*/\""
    local _query_local="folder:\"/all/.*/\""
    local _query_remote="folder:\"/raw/.*/\""
    local _TAG_LOCAL="_LOCAL"
    local _TAG_REMOTE="_REMOTE"
    local _TAG_LOCAL_UNTAGGED="_UNTAGGED"
    local _TAG_LOCAL_TAGGED="_TAGGED"
    local _TAG_ARCHIVE="_ARCHIVE"

    __tag_copy() {
        notmuch tag +"${2}" -- tag:"${1}"
        notmuch tag -"${2}" -- not tag:"${1}"
    }

    __tag_rename() {
        notmuch tag +"${2}" -"${1}" -- tag:"${1}"
        notmuch tag -"${2}" -- not tag:"${1}"
    }

    __tag_delete() {
        notmuch tag -"${1}" -- tag:"${1}"
    }

    __builtin() {
        local _tag

        for _tag in "attachment" "signed" "encrypted"; do
            __tag_rename "${_tag}" "__$(__to_upper "${_tag}")"
        done

        for _tag in "inbox" "draft"; do
            __tag_delete "${_tag}"
        done

        for _tag in "unread" "flagged" "replied" "passed"; do
            __tag_copy "${_tag}" "__$(__to_upper "${_tag}")"
        done
    }

    __local_remote() {
        local _query_local="${_query_local}"
        printf "notmuch/tag> [local--remote]..."

        notmuch tag \
            "+${_TAG_LOCAL}" \
            "-${_TAG_REMOTE}" \
            -- "${_query_local}"
        local _query_remote="${_query_remote}"
        notmuch tag \
            "+${_TAG_REMOTE}" \
            "-${_TAG_LOCAL}" \
            -- "${_query_remote}"

        printf "; done! (%s--%s)\n" \
            "$(notmuch count -- "${_query_local}")" \
            "$(notmuch count -- "${_query_remote}")"
    }

    __taggedness() {
        local _query_tagged="${_query_all}"

        __list_tags | {
            local _query_untagged="${_query_all}"

            local _tag
            while read -r _tag; do
                if [ "$(printf "%s" "${_tag}" | head -c "+1")" = "_" ]; then
                    continue
                fi
                if __is_in "${_tag}" "MAIN" "unread" "replied" "flagged" "passed"; then
                    continue
                fi
                _query_untagged="${_query_untagged} and not tag:${_tag}"
                # NOTE:
                #   exploit implicit OR joining between (same) query-terms
                # REF:
                #   https://notmuch.readthedocs.io/en/latest/man7/notmuch-search-terms.html#operators
                _query_tagged="${_query_tagged} tag:${_tag}"
            done

            printf "notmuch/tag> [tagged'ness]..."
            notmuch tag \
                "+${_TAG_LOCAL_UNTAGGED}" \
                "-${_TAG_LOCAL_TAGGED}" \
                -- "${_query_untagged}"
            notmuch tag \
                "+${_TAG_LOCAL_TAGGED}" \
                "-${_TAG_LOCAL_UNTAGGED}" \
                -- "${_query_tagged}"
            printf "; done! (%s tagged, %s untagged)\n" \
                "$(notmuch count -- "${_query_tagged}")" \
                "$(notmuch count -- "${_query_untagged}")"
        }
    }

    __archive() {
        local _query="${_query_local} and folder:\"all/.x/\""
        local _query_negative="${_query_local} and not folder:\"all/.x/\""
        printf "notmuch/tag> [archive]..."
        notmuch tag \
            "+${_TAG_ARCHIVE}" \
            -- "${_query}"
        notmuch tag \
            "-${_TAG_ARCHIVE}" \
            -- "${_query_local} and not folder:\"all/.x/\""
        printf "; done! (%s)\n" "$(notmuch count -- "${_query}")"
    }

    __draft() {
        notmuch tag +"_DRAFT" -- folder:"\"all/.draft/\""
        notmuch tag -"_DRAFT" -- not folder:"\"all/.draft/\""
    }

    __config_tag_sent() {
        if [ "${1}" = "--" ]; then shift; fi

        local _from
        for _from in "${@}"; do
            printf "+_SENT -- from:%s\n" "${_from}"
        done
    }

    __config_tag_archive() {
        if [ "${1}" = "--" ]; then shift; fi

        local _base="+${_TAG_ARCHIVE} -- ${_query_remote}"
        local _archive
        for _archive in "${@}"; do
            printf "%s and folder:\"raw/%s/\"\n" "${_base}" "${_archive}"
        done

        printf "\n"

        printf "%s -- %s" "-${_TAG_ARCHIVE}" "${_query_remote}"
        for _archive in "${@}"; do
            printf " and not folder:\"raw/%s/\"" "${_archive}"
        done
    }

    case "${1}" in
        "config-tag-sent")
            shift
            __config_tag_sent "${@}"
            ;;
        "config-tag-archive")
            shift
            __config_tag_archive "${@}"
            ;;
        *)
            printf "\n"
            __report_count
            __builtin
            __local_remote
            __taggedness
            __archive
            __draft
            ;;
    esac
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
        shift
        __tag "${@}"
        ;;
esac
