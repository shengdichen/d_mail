#!/usr/bin/env dash

SCRIPT_PATH="$(realpath "$(dirname "${0}")")"

FDM_CONFIG="${HOME}/.config/fdm/config"

FILE_CONST="$(realpath "${SCRIPT_PATH}/..")/const.sh"
DIR_MAIL_TRASH="$("${FILE_CONST}" DIR_MAIL_TRASH)"
DIR_MAIL_HOLD="$("${FILE_CONST}" DIR_MAIL_HOLD)"
unset FILE_CONST

ACTION_DELETE="delete"
ACTION_TRASH="trash"
ACTION_HOLD="hold"
ACTION_KEEP="keep"
ACTION_PRINT="print"

__tab() {
    local _n="${1-"1"}"
    for _ in $(seq "${_n}"); do
        printf "    "
    done
}

__fdm() {
    if [ "${#}" -eq 0 ]; then
        fdm -f "${FDM_CONFIG}" fetch
        return
    fi
    fdm -f "${FDM_CONFIG}" "${@}"
}

__config() {
    __define_account() {
        printf "account \"%s\"\n" "${1}"
        shift
        if [ "${1}" = "--" ]; then shift; fi

        __tab
        printf "maildirs {\n"

        local _item
        for _item in "${@}"; do
            __tab 2
            printf "\"%s\"\n" "${_item}"
        done

        __tab
        printf "}\n"
    }

    __define_action() {
        printf "action \"%s\" {\n" "${1}"
        shift
        if [ "${1}" = "--" ]; then shift; fi

        local _item
        for _item in "${@}"; do
            __tab && printf "%s\n" "${_item}"
        done
        printf "}\n"
    }

    __condition_regex_header() {
        local _header="From" _raw=""
        while [ "${#}" -gt 0 ]; do
            case "${1}" in
                "--header")
                    case "${2}" in
                        "from")
                            _header="From"
                            ;;
                        "to")
                            _header="To"
                            ;;
                        "subject")
                            _header="Subject"
                            ;;
                    esac
                    shift 2
                    ;;
                "--raw")
                    _raw="yes"
                    shift
                    ;;
                "--")
                    shift && break
                    ;;
            esac
        done

        __preserve_literal_dot() {
            # |.| not followed by |*|, i.e., literal dot -> |\.|
            printf "%s" "${1}" | sed "s/\(\.[^*]\)/\\\\\1/g"
        }

        __process_address() {
            if printf "%s" "${1}" | grep -q "^.\+@"; then # match by address
                printf "\"^%s:.*[\\\\\\s<]%s\" in headers" "${_header}" "${1}"
                return
            fi
            if printf "%s" "${1}" | grep -q "^@"; then # match by domain
                printf "\"^%s:.*%s\" in headers" "${_header}" "${1}"
                return
            fi
            # match by name
            printf "\"^%s:\\\\\\s*%s\" in headers" "${_header}" "${1}"
        }

        __process_subject() {
            printf "\"^%s:.*%s\" in headers" "${_header}" "${1}"
        }

        local _item _n_items="${#}" _i=0
        for _item in "${@}"; do
            _i=$((_i + 1))
            _item="$(__preserve_literal_dot "${_item}")"

            if [ "${_raw}" ]; then
                printf "\"^%s: %s$\" in headers" "${_header}" "${_item}"
            else
                case "${_header}" in
                    "From" | "To")
                        __process_address "${_item}"
                        ;;
                    "Subject")
                        __process_subject "${_item}"
                        ;;
                esac
            fi

            if [ "${_i}" -ne "${_n_items}" ]; then
                printf " or\n"
            fi
        done
    }

    __condition_accounts() {
        # NOTE:
        #   accounts {
        #       "<ACCOUNT_1>"
        #       "<ACCOUNT_2>"
        #       "..."
        #   }

        if [ "${1}" = "--" ]; then shift; fi

        printf "accounts {\n"
        local _account
        for _account in "${@}"; do
            __tab && printf "\"%s\"\n" "${_account}"
        done
        printf "}"
    }

    __actions() {
        if [ "${1}" = "--" ]; then shift; fi

        printf "actions {\n"
        local _action
        for _action in "${@}"; do
            __tab && printf "\"%s\"\n" "${_action}"
        done
        printf "}\n"
    }

    __do() {
        local _line

        printf "match\n"

        # condition(s)
        while IFS="" read -r _line; do
            [ "${_line}" ] && __tab
            printf "%s\n" "${_line}"
        done

        # action(s)
        __actions "${@}" | while IFS="" read -r _line; do
            [ "${_line}" ] && __tab
            printf "%s\n" "${_line}"
        done
    }

    __commit() {
        cat - >"${FDM_CONFIG}"
        chmod 600 -- "${FDM_CONFIG}"
    }

    case "${1}" in
        "base")
            cat <<STOP
# do NOT add any |Received| tag
set no-received
STOP
            ;;

        "define-account")
            shift
            __define_account "${@}"
            ;;
        "define-action")
            shift
            __define_action "${@}"
            ;;
        "define-actions-default")
            shift
            # in descending order of animosity
            __define_action "${ACTION_DELETE}" -- "drop"
            __define_action "${ACTION_TRASH}" -- "maildir \"${DIR_MAIL_TRASH}\""
            __define_action "${ACTION_HOLD}" -- "maildir \"${DIR_MAIL_HOLD}\""
            __define_action "${ACTION_KEEP}" -- "keep"
            __define_action "${ACTION_PRINT}" -- "stdout"
            ;;

        "condition-all")
            printf "all"
            ;;
        "condition-regex-header")
            shift
            __condition_regex_header "${@}"
            ;;
        "condition-accounts")
            shift
            __condition_accounts "${@}"
            ;;
        "condition-AND")
            printf " and\n\n"
            ;;
        "condition-OR")
            printf " or\n\n"
            ;;
        "condition-END")
            printf "\n\n"
            ;;

        "actions")
            shift
            __actions "${@}"
            ;;

        "do")
            shift
            __do "${@}"
            ;;
        "do-trash")
            __do "trash"
            ;;
        "do-delete")
            __do "delete"
            ;;
        "do-keep")
            __do "keep"
            ;;

        "commit")
            __commit
            ;;
    esac
}

case "${1}" in
    "config")
        shift
        __config "${@}"
        ;;

    *)
        __fdm "${@}"
        ;;
esac
