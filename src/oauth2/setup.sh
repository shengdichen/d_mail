#!/usr/bin/env dash

SCRIPT_PATH="$(realpath "$(dirname "${0}")")"

PYTHON_SCRIPT="mutt_oauth2.py"
PATH_TOKEN="${HOME}/.password-store/Dox/mail"

CMD_ENCRYPT="gpg --encrypt --recipient sh@c"

__run() {
    python "${SCRIPT_PATH}/${PYTHON_SCRIPT}" "${@}"
}

__download() {
    if [ ! -e "${PYTHON_SCRIPT}" ]; then
        wget "https://raw.githubusercontent.com/neomutt/neomutt/refs/heads/main/contrib/oauth2/mutt_oauth2.py"
    fi
}

__token_file() {
    local _f="${PATH_TOKEN}/${1}.oauth.gpg"
    if [ -e "${_f}" ]; then
        chmod 600 -- "${_f}"
    fi

    printf "%s" "${_f}"
}

__auth_microsoft() {
    # REF:
    #   https://www.dcs.gla.ac.uk/~jacobd/posts/2022/03/configure-mutt-to-work-with-oauth-20/
    #   https://simondobson.org/2024/02/03/getting-email/
    #   http://blog.onodera.asia/2020/06/how-to-use-google-g-suite-oauth2-with.html
    #   https://github.com/UvA-FNWI/M365-IMAP
    #   https://github.com/neomutt/neomutt/tree/main/contrib/oauth2

    local _config="azure" _auth _email
    while [ "${#}" -gt 0 ]; do
        case "${1}" in
            "--config")
                _config="${2}"
                shift 2
                ;;
            "--auth")
                # localhostauthcode := complicated URL + auto
                # authcode := complicated URL + paste-back
                # devicecode := simple URL + paste-in + auto
                _auth="${2}"
                shift 2
                ;;
            "--")
                _email="${2}"
                shift 2
                break
                ;;
        esac
    done

    local _provider _client_id _client_secret=""
    case "${_config}" in
        "azure")
            _provider="microsoft"
            _client_id="23d45424-04ad-4dcc-bd0c-0c1e9139962f"
            _auth="${auth:-localhostauthcode}"
            ;;
        "mozilla")
            # REF:
            #   https://hg.mozilla.org/comm-central/file/tip/mailnews/base/src/OAuth2Providers.sys.mjs
            #   https://support.mozilla.org/en-US/kb/microsoft-oauth-authentication-and-thunderbird-202
            # NOTE:
            #   redirectUri = "https://localhost"
            _provider="microsoft-mozilla"
            _client_id="9e5f94bc-e8a4-4e73-b8be-63364c29d753"
            _auth="devicecode" # only auth that works
            ;;
        "thunderbird")
            # REF:
            #   https://github.com/thunderbird/thunderbird-android/blob/main/app-thunderbird/src/release/kotlin/net/thunderbird/android/auth/TbOAuthConfigurationFactory.kt
            # NOTE:
            #   redirectUri = "msauth://net.thunderbird.android/S9nqeF27sTJcEfaInpC%2BDHzHuCY%3D",
            _provider="microsoft-thunderbird"
            _client_id="e6f8716e-299d-4ed9-bbf3-453f192f44e5"
            _auth="${_auth:-authcode}"
            ;;
        "k9")
            # REF:
            #   https://github.com/thunderbird/thunderbird-android/blob/main/app-k9mail/src/release/kotlin/app/k9mail/auth/K9OAuthConfigurationFactory.kt
            # NOTE:
            #   redirectUri = "msauth://com.fsck.k9/Dx8yUsuhyU3dYYba1aA16Wxu5eM%3D",
            _provider="microsoft-k9"
            _client_id="e647013a-ada4-4114-b419-e43d250f99c5"
            _auth="${_auth:-authcode}"
            ;;
        *)
            exit 3
            ;;
    esac

    local _token_file
    _token_file="$(__token_file "${_email}")"
    if [ -e "${_token_file}" ]; then
        rm "${_token_file}"
    fi

    __run --verbose --authorize \
        --provider "${_provider}" \
        --client-id "${_client_id}" \
        --client-secret "${_client_secret}" \
        \
        --encryption-pipe "${CMD_ENCRYPT}" \
        --authflow "${_auth}" \
        \
        --email "${_email}" \
        "${_token_file}"
}

__test() {
    if [ "${1}" = "--" ]; then shift; fi
    __run --verbose --test \
        --encryption-pipe "${CMD_ENCRYPT}" \
        "$(__token_file "${1}")"
}

__get() {
    if [ "${1}" = "--" ]; then shift; fi
    __run \
        --encryption-pipe "${CMD_ENCRYPT}" \
        "$(__token_file "${1}")"
}

__main() {
    case "${1}" in
        "make")
            __auth_microsoft --config "mozilla" -- "shengdi@outlook.de"
            __auth_microsoft --config "mozilla" -- "shenchen@ethz.ch"
            ;;
        "test")
            __test -- "shengdi@outlook.de"
            __test -- "shenchen@ethz.ch"
            ;;
        "get")
            shift
            __get "${@}"
            ;;
    esac
}
__main "${@}"
