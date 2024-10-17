#!/usr/bin/env dash

SCRIPT_PATH="$(realpath "$(dirname "${0}")")"
SRC_PATH="${SCRIPT_PATH}/src"

DIR_MAIL="$("${SCRIPT_PATH}/const.sh" DIR_MAIL)"
DIR_MAIL_BACKUP="$("${SCRIPT_PATH}/const.sh" DIR_MAIL_BACKUP)"
DIR_MAIL_LOCAL="$("${SCRIPT_PATH}/const.sh" DIR_MAIL_LOCAL)"

DIR_NOTMUCH="$("${SCRIPT_PATH}/const.sh" DIR_NOTMUCH)"

__make_config() {
    mkdir -p "${HOME}/.cache/neomutt/"

    local _dir_config="${HOME}/.config"
    mkdir -p "${_dir_config}/mbsync"
    mkdir -p "${_dir_config}/msmtp"
    mkdir -p "${_dir_config}/neomutt"

    (cd .. && stow -R "$(basename "${SCRIPT_PATH}")")

    "${SRC_PATH}/account.sh" config
}

__mkdir_mail() {
    mkdir -p "${DIR_MAIL}"
    mkdir -p "${DIR_MAIL_BACKUP}"

    # NOTE:
    #   no need to manually create remote maildirs; run mbsync instead

    local _d _d_mail
    for _d in "draft" "hold" "trash" "x"; do
        _d="${DIR_MAIL_LOCAL}/.${_d}"
        mkdir -p "${_d}"
        chmod 700 "${_d}"
        for _d_mail in "cur" "new" "tmp"; do
            local _d_mail="${_d}/${_d_mail}"
            mkdir -p "${_d_mail}"
            chmod 700 "${_d_mail}"
        done
    done
}

__mkdir_notmuch() {
    mkdir -p "${DIR_NOTMUCH}"
}

__make_config
__mkdir_mail
__mkdir_notmuch
