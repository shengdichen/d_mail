#!/usr/bin/env bash

. "${HOME}/.local/lib/util.sh"

INBOXES=() SENTS=() REMOTE_ARCHIVES=()

SCRIPT_PATH="$(realpath "$(dirname "${0}")")"
FILE_CONST="$(realpath "${SCRIPT_PATH}/..")/const.sh"
DIR_MAIL_HOLD="$("${FILE_CONST}" DIR_MAIL_HOLD)"
DIR_MAIL_REMOTE="$("${FILE_CONST}" DIR_MAIL_REMOTE)"
unset FILE_CONST

INBOXES+=("${DIR_MAIL_REMOTE}/xyz/.INBOX")
SENTS+=("${DIR_MAIL_REMOTE}/xyz/.Sent")
REMOTE_ARCHIVES+=("${DIR_MAIL_REMOTE}/xyz/.Folders.x")
__xyz() {
    local _account="xyz"
    local _addr="me@shengdichen.xyz"

    __mbsync_config() {
        {
            "${SCRIPT_PATH}/mbsync.sh" config base

            {
                cat <<STOP
Host 127.0.0.1
Port 1143
TLSType STARTTLS
CertificateFile "~/.cert/protonmail/${_addr}.cert.pem"
User ${_addr}
STOP
                "${SCRIPT_PATH}/mbsync.sh" config pass pass "${_addr}.bridge"
            } | "${SCRIPT_PATH}/mbsync.sh" config remote
            printf "\n"

            "${SCRIPT_PATH}/mbsync.sh" config channels "${_account}" "All Mail"
            printf "\n"

            "${SCRIPT_PATH}/mbsync.sh" config final
        } | "${SCRIPT_PATH}/mbsync.sh" config commit "${_account}"
    }

    __msmtp_config() {
        {
            cat <<STOP
host 127.0.0.1
port 1025
auth login
STOP
            printf "\n"

            cat <<STOP
user ${_addr}
from ${_addr}
STOP
            "${SCRIPT_PATH}/msmtp.sh" config pass pass "${_addr}.bridge"
        } | "${SCRIPT_PATH}/msmtp.sh" config commit "${_account}"
    }

    case "${1}" in
        "config")
            __mbsync_config
            __msmtp_config
            ;;
        "test")
            __mbsync_config
            "${SCRIPT_PATH}/mbsync.sh" test -- "${_account}"
            __msmtp_config
            "${SCRIPT_PATH}/msmtp.sh" test -- "${_account}"
            ;;
        *)
            __mbsync_config
            "${SCRIPT_PATH}/mbsync.sh" test -- "${_account}"
            __msmtp_config
            ;;
    esac
}

INBOXES+=("${DIR_MAIL_REMOTE}/outlook/.INBOX")
SENTS+=("${DIR_MAIL_REMOTE}/outlook/.Sent")
REMOTE_ARCHIVES+=("${DIR_MAIL_REMOTE}/outlook/.x")
__outlook() {
    local _account="outlook"
    local _addr="shengdi@outlook.de"

    __mbsync_config() {
        {
            "${SCRIPT_PATH}/mbsync.sh" config base

            {
                cat <<STOP
Host outlook.office365.com
Port 993
AuthMechs XOAUTH2
TLSType IMAPS
User ${_addr}
STOP
                "${SCRIPT_PATH}/mbsync.sh" config pass oauth "${_addr}"
            } | "${SCRIPT_PATH}/mbsync.sh" config remote
            printf "\n"

            "${SCRIPT_PATH}/mbsync.sh" config channels "${_account}"
            printf "\n"

            "${SCRIPT_PATH}/mbsync.sh" config final
        } | "${SCRIPT_PATH}/mbsync.sh" config commit "${_account}"
    }

    __msmtp_config() {
        {
            cat <<STOP
host smtp-mail.outlook.com
port 587
tls on
auth xoauth2
STOP
            printf "\n"

            cat <<STOP
user ${_addr}
from ${_addr}
STOP

            "${SCRIPT_PATH}/msmtp.sh" config pass oauth "${_addr}"
        } | "${SCRIPT_PATH}/msmtp.sh" config commit "${_account}"
    }

    case "${1}" in
        "config")
            __mbsync_config
            __msmtp_config
            ;;
        "test")
            __mbsync_config
            "${SCRIPT_PATH}/mbsync.sh" test -- "${_account}"
            __msmtp_config
            "${SCRIPT_PATH}/msmtp.sh" test -- "${_account}"
            ;;
        *)
            __mbsync_config
            "${SCRIPT_PATH}/mbsync.sh" test -- "${_account}"
            __msmtp_config
            ;;
    esac
}

INBOXES+=("${DIR_MAIL_REMOTE}/eth/.INBOX")
SENTS+=("${DIR_MAIL_REMOTE}/eth/.Sent Items")
REMOTE_ARCHIVES+=("${DIR_MAIL_REMOTE}/eth/.x")
__eth() {
    local _account="eth"
    local _addr="shenchen@ethz.ch"

    __mbsync_config() {
        {
            "${SCRIPT_PATH}/mbsync.sh" config base

            {
                cat <<STOP
Host outlook.office365.com
Port 993
AuthMechs XOAUTH2
TLSType IMAPS
User ${_addr}
STOP
                "${SCRIPT_PATH}/mbsync.sh" config pass oauth "${_addr}"
            } | "${SCRIPT_PATH}/mbsync.sh" config remote
            printf "\n"

            "${SCRIPT_PATH}/mbsync.sh" config channels "${_account}" "Calendar/United States holidays"
            printf "\n"

            "${SCRIPT_PATH}/mbsync.sh" config final
        } | "${SCRIPT_PATH}/mbsync.sh" config commit "${_account}"
    }

    __msmtp_config() {
        {
            cat <<STOP
host smtp.office365.com
port 587
tls on
auth xoauth2
STOP
            printf "\n"

            cat <<STOP
user ${_addr}
from ${_addr}
STOP
            "${SCRIPT_PATH}/msmtp.sh" config pass oauth "${_addr}"
        } | "${SCRIPT_PATH}/msmtp.sh" config commit "${_account}"
    }

    case "${1}" in
        "config")
            __mbsync_config
            __msmtp_config
            ;;
        "test")
            __mbsync_config
            "${SCRIPT_PATH}/mbsync.sh" test -- "${_account}"
            __msmtp_config
            "${SCRIPT_PATH}/msmtp.sh" test -- "${_account}"
            ;;
        *)
            __mbsync_config
            "${SCRIPT_PATH}/mbsync.sh" test -- "${_account}"
            __msmtp_config
            ;;
    esac
}

INBOXES+=("${DIR_MAIL_REMOTE}/gmail/.INBOX")
SENTS+=("${DIR_MAIL_REMOTE}/gmail/.[Gmail].E-mails enviados")
__gmail() {
    local _account="gmail"
    local _addr="shengdishcchen@gmail.com"

    __mbsync_config() {
        {
            "${SCRIPT_PATH}/mbsync.sh" config base

            {
                cat <<STOP
Host imap.gmail.com
Port 993
TLSType IMAPS
User ${_addr}
STOP
                "${SCRIPT_PATH}/mbsync.sh" config pass pass "${_addr}.app"
            } | "${SCRIPT_PATH}/mbsync.sh" config remote
            printf "\n"

            "${SCRIPT_PATH}/mbsync.sh" config channels "${_account}"
            printf "\n"

            "${SCRIPT_PATH}/mbsync.sh" config final
        } | "${SCRIPT_PATH}/mbsync.sh" config commit "${_account}"
    }

    __msmtp_config() {
        {
            cat <<STOP
host smtp.gmail.com
port 587
tls on
auth on
STOP
            printf "\n"

            cat <<STOP
user ${_addr}
from ${_addr}
STOP
            "${SCRIPT_PATH}/msmtp.sh" config pass pass "${_addr}.app"
        } | "${SCRIPT_PATH}/msmtp.sh" config commit "${_account}"
    }

    case "${1}" in
        "config")
            __mbsync_config
            __msmtp_config
            ;;
        "test")
            __mbsync_config
            "${SCRIPT_PATH}/mbsync.sh" test -- "${_account}"
            __msmtp_config
            "${SCRIPT_PATH}/msmtp.sh" test -- "${_account}"
            ;;
        *)
            __mbsync_config
            "${SCRIPT_PATH}/mbsync.sh" test -- "${_account}"
            __msmtp_config
            ;;
    esac
}

__config_fdm() {
    local _account_hold="acc_hold"
    local _account_raw_inbox="acc_raw_inbox"
    local _account_raw_sent="acc_raw_sent"
    local _account_raw_misc="acc_raw_misc"

    __account() {
        "${SCRIPT_PATH}/fdm.sh" config define-account "${_account_hold}" "${DIR_MAIL_HOLD}"

        "${SCRIPT_PATH}/fdm.sh" config define-account "${_account_raw_inbox}" "${INBOXES[@]}"
        "${SCRIPT_PATH}/fdm.sh" config define-account "${_account_raw_sent}" "${SENTS[@]}"

        find "${DIR_MAIL_REMOTE}" -mindepth 2 -maxdepth 2 -type d | sort -n | {
            local _miscs=()
            local _box
            while read -r _box; do
                if ! __is_in "${_box}" "${INBOXES[@]}" "${SENTS[@]}" "${REMOTE_ARCHIVES[@]}"; then
                    _miscs+=("${_box}")
                fi
            done
            "${SCRIPT_PATH}/fdm.sh" config define-account "${_account_raw_misc}" "${_miscs[@]}"
        }
    }

    __hold() {
        {
            "${SCRIPT_PATH}/fdm.sh" config condition-accounts -- "${_account_hold}"
            "${SCRIPT_PATH}/fdm.sh" config condition-END
        } | "${SCRIPT_PATH}/fdm.sh" config do-keep
    }

    __trash() {
        local _addrs=(
            "paypal@mail.paypal.de"
            "ubs_switzerland@mailing.ubs.com"

            "email.campaign@sg.booking.com"
            "mail@e.milesandmore.com"
            "mail@mailing.milesandmore.com"
            "newsletter@mailing.milesandmore.com"
            "newsletter@your.lufthansa-group.com"

            "no-reply@business.amazon.com"
            "store-news@amazon.com"
            "vfe-campaign-response@amazon.com"
            "customer-reviews-messages@amazon.com"
            "marketplace-messages@amazon.com"

            "noreply@productnews.galaxus.ch"
            "noreply@productnews.digitec.ch"
            "noreply@notifications.galaxus.ch"
            "galaxus@community.galaxus.ch"
            "productnews@galaxus.ch"
            "resale@galaxus.ch"
            "resale@notifications.galaxus.ch"
            "ux@digitecgalaxus.ch"

            "hilfe@tutti.ch"
            "@comm.tutti.ch"
            "notice@info.aliexpress.com"
            "@newsletter.swarovski.com"
            "@news.coop.ch"

            "hello@mail.plex.tv"
            "@ifttt.com"
            "@mail.blinkist.com"

            "no-reply@swissid.ch"
            "info@logistics.post.ch"

            "support@nordvpn.com"
            "@ipvanish.com"

            "no-reply@.*.proton.me"
            "contact@protonmail.com"

            "noreply-dmarc-support@google.com"
            "no-reply@accounts.google.com"
            "cloud-noreply@google.com"

            "notification@facebookmail.com"
            "friendupdates@facebookmail.com"
            "reminders@facebookmail.com"
            "friendsuggestion@facebookmail.com"
            "@priority.facebookmail.com"

            "noreply@discord.com"

            "@.*.instagram..*"

            "kuiper.sina@bcg.com"

            "ims@schlosstorgelow.de"
            "kirstenschreibt@schlosstorgelow.de"

            "mozilla@email.mozilla.org"

            "no-reply@piazza.com"
            "noreply@moodle-app2.let.ethz.ch"

            "outgoing@office.iaeste.ch"
            "@btools.ch"
            "@projektneptun.ch"
            "@sprachen.uzh.ch"
            "@soziologie.uzh.ch"

            "careercenter@news.ethz.ch"
            "treffpunkt@news.ethz.ch"
            "MicrosoftExchange329e71ec88ae4615bbc36ab6ce41109e@intern.ethz.ch"
            "descil@ethz.ch"
            "mathbib@math.ethz.ch"
            "evasys@let.ethz.ch"
            "exchange@ethz.ch"
            "president@ethz.ch"
            "sgu_training@ethz.ch"
            "didaktischeausbildung@ethz.ch"
            "entrepreneurship@ethz.ch"
            "nikola.kovacevic@inf.ethz.ch"
            "compicampus@id.ethz.ch"
            "@hk.ethz.ch"
            "@library.ethz.ch"
            "@sts.ethz.ch"
            "@sl.ethz.ch"
        )
        local _names=(
            "DPD-Paket"
        )
        local _subjects=(
            "Test Mail"
        )

        {
            "${SCRIPT_PATH}/fdm.sh" config condition-accounts -- \
                "${_account_raw_inbox}" "${_account_raw_sent}" "${_account_raw_misc}"
            "${SCRIPT_PATH}/fdm.sh" config condition-AND

            "${SCRIPT_PATH}/fdm.sh" config condition-regex-header -- \
                "${_addrs[@]}"
            "${SCRIPT_PATH}/fdm.sh" config condition-OR
            "${SCRIPT_PATH}/fdm.sh" config condition-regex-header -- \
                "${_names[@]}"
            "${SCRIPT_PATH}/fdm.sh" config condition-OR
            "${SCRIPT_PATH}/fdm.sh" config condition-regex-header \
                --header subject \
                -- "${_subjects[@]}"

            "${SCRIPT_PATH}/fdm.sh" config condition-END
        } | "${SCRIPT_PATH}/fdm.sh" config do-trash
    }

    __delete() {
        local _addrs=(
            "@indiaplays.com"
            "@kraftangan.gov.my"
            "@kollect.ai"
            "@transfiriendo.com"
            "@fibrasil.com"
            "@norton.com"
            "@novaorion.com"
            "@apparelsite.net"
            "@farmleap.com"
            "@yfhuorwa.com"
            "@moneypeny.fr"
            "@ronquilloassociates.com"
            "@preapp1003.com"
            "@magnusmonitors.com"
            "@oasdehe.com"
            "@sion.ais.ne.jp"
            "@didareshop.com"
            "@catpro.io"
            "@mozart.livingopera.org"
            "@fr.redoutes.com"
            "@vr7uallms.com"
            "@caboardroom.com.sg"
            "@esrtech.io"
            "@watts.com"
            "@myfolio.im"
            "@wettbewerbeundgewinnspiele.ch"
            "@domenca.raviko.com"
            "@ukrainianbeauty.com"
            "@try2ascend.com"
            "@glsthewinners4you.com"
            "@neugiab.com"
            "@ac-creteil.fr"
            "@getaventura.com"
            "@cootel.com.ni"
            "@smart.com.ro"
            "@itlgt.com"
            "@binafna.huawei.uk.net"
            "@darecky.pl"
            "@montenegromade.com"
            "@divaniesofa.ro"
            "@easytrott.fr"
            "@kiswel.com"
            "@vmiconic.co.tz"
            "@citizenpath.com"
            "@doctorgenius.com"
            "@upscheckoutrotator.com"
            "@gc-dienstleistungen.de"
            "@degoldengeniecasinochrismas.com"
            "@uporalbseriesdmdrogeriemarkt.com"
            "@complicesdelsonidoradio.com.ar"
            "@veracity-trading.com"
            "@deupscheckoutrotator.com"
            "@deendurancerhctc.com"
            "@defitsmartdiet.com"
            "@vqfit.com"
            "@otyavaf.co.uk"
            "@fl0ppfy.co.uk"
            "@irup5nr.co.uk"
            "@ss-exports.in"
            "@devigamanver2foryou.com"
            "@ecomproesurveys.com"
            "@ukhermesebookiasts.com"
            "@smokacevipangebote.net"
            "@ecaprivatedelivery.com"
            "@server.cedarhallclinic.uk"
            "@delidlgiftcard.com"
            "@destanleytoolsetkaufland.com"
            "@ukbootsjomaloneadventcalendar.com"
            "@solidsunenergie.cz"
            "@deupsblackpageverdelivery.com"
            "@server.light-review.com"
            "@cc-aglyfenouilledes.fr"
            "@renovatio.uk.com"
            "@cliqtechno.com"
            "@stnicholasprimaryschool.org"
            "@sense28.com"
            "@ueh.edu.vn"
            "@piecedrillset.de"
            "@usekilo.com"
            "@hadiethshop.nl"
            "@connect.liveapps.store"
            "@impactinglife.co.uk"
            "@wgo.com.br"
            "@host.bkauk.org.uk"
            "@londontrucks.co.uk"
            "@asb-hamburg.de"
            "@dfc.discovery.co.za"
            "@riseinformatics.com"
            "@ntf.com"
            "@clikr.com.br"
            "@rplexelectrical.in"
            "@mondrian-it.io"
            "@capacityproviders.com"
            "@davulga.bel.tr"
            "@myhoppophop.fr"
            "@lv09.katyjenkins.shop"
            "@k4UBCPR8.fr"
            "@vydehischool.com"
            "@steibel.be"
            "@tisknise.cz"
            "@campaign.eventbrite.com"
            "@insistglobal.com"
            "@montagnes-sciences.fr"
            "@kenzahn.com"
            "@insistglobal.com"
            "@affiligate.com"
            "@yellowdig.net"
            "@smtp.assessment.gr"
            "@shadovn.com"
            "@send.sw.ofbrand.live"
            "@client.whitehousenannies.com"
            "@send.sw.taipanonline.com"
            "@icar.gov.in"
            "@lv04.ggoopp.shop"
            "@deXtremeBio.com"

            "no-reply@flipboard.com"
            "support@help.instapaper.com"
            "no-reply@instapaper.com"

            "@email.wolfram.com"
            "@go.mathworks.com"

            "diversity@ethz.ch"
            "gastro@news.ethz.ch"
            "phishing-simulation@id.ethz.ch"
            "@services.elhz.ch"

            "okabzne@hotmail.com"
            "davidcostapro@gmail.com"
            "ngoctran071113@gmail.com"
            "nhatnguyen31101993@gmail.com"
            "FreegsmfsdsFDFDmehdii49@gmx.de"

        )
        local _names=(
            "Fehler bei der Lieferadresse"
            "Paket zur Auslieferung bereit <<>>"
            "Ihre ALDI Vorteile <<>>"
            "Exklusiv für Amavita Mitglieder <<>>"
            "Starbucks Geschenke <<>>"
        )
        {
            "${SCRIPT_PATH}/fdm.sh" config condition-accounts -- \
                "${_account_raw_inbox}" "${_account_raw_sent}" "${_account_raw_misc}"
            "${SCRIPT_PATH}/fdm.sh" config condition-AND

            "${SCRIPT_PATH}/fdm.sh" config condition-regex-header -- "${_addrs[@]}"
            "${SCRIPT_PATH}/fdm.sh" config condition-OR
            "${SCRIPT_PATH}/fdm.sh" config condition-regex-header -- "${_names[@]}"

            "${SCRIPT_PATH}/fdm.sh" config condition-END
        } | "${SCRIPT_PATH}/fdm.sh" config do-delete
    }

    __keep() {
        {
            "${SCRIPT_PATH}/fdm.sh" config condition-all
            "${SCRIPT_PATH}/fdm.sh" config condition-END
        } | "${SCRIPT_PATH}/fdm.sh" config do-keep
    }

    {
        printf "# setup {{{\n"
        "${SCRIPT_PATH}/fdm.sh" config base
        printf "\n"
        printf "# account {{{\n"
        __account
        printf "# }}}\n"
        printf "\n"
        printf "# action {{{\n"
        "${SCRIPT_PATH}/fdm.sh" config define-actions-default
        printf "# }}}\n"
        printf "# }}}\n"

        printf "\n"

        __hold
        printf "\n"

        printf "# the undesirables {{{\n"
        printf "# trash {{{\n"
        __trash
        printf "# }}}\n"
        printf "\n"
        printf "# delete {{{\n"
        __delete
        printf "# }}}\n"
        printf "# }}}\n"

        printf "\n"

        __keep

        cat <<STOP

# vim: filetype=conf foldmethod=marker foldlevel=1
STOP
    } | "${SCRIPT_PATH}/fdm.sh" config commit
}

__neomutt() {
    local _conf_neomutt="\$my_conf_neomutt"
    local _mail_raw_relative="\$my_mail_raw_relative_path"
    local _accounts=("xyz" "outlook" "eth" "gmail") _account

    local _quote_esc="\\\\\""

    __quote() {
        printf "\\\\\""
        if [ "${#}" -eq 0 ]; then
            cat -
        else
            printf "%s" "${1}"
        fi

        printf "\\\\\""
    }

    __account_as_string() {
        printf "| %s" "${_account}"
    }

    {
        cat <<STOP
macro index ca "\\
<enter-command>\\
virtual-mailboxes \\
STOP
        for _account in "${_accounts[@]}"; do
            __quote "$(__account_as_string "${_account}")"
            printf " "
            __quote "notmuch://?query=folder:/${_mail_raw_relative}/${_account}/\\\\..*/"
            printf " \\\\\n"
        done
        cat <<STOP
<Return>\\
<check-stats>\\
" "box all"
STOP

        printf "\n"

        cat <<STOP
macro index cA "\\
<enter-command>\\
unvirtual-mailboxes \\
STOP

        for _account in "${_accounts[@]}"; do
            __quote "notmuch://?query=folder:/${_mail_raw_relative}/${_account}/\\\\..*/"
            printf " \\\\\n"
        done
        cat <<STOP
<Return>\\
<check-stats>\\
" "unbox all"
STOP

        printf "\n"

        local _conf
        for _account in "${_accounts[@]}"; do
            _conf="$(__quote "\$my_conf_neomutt/box/specific/${_account}/specific.conf")"
            printf "folder-hook -noregex \"%s/%s\" \"source %s\"\n" "${_mail_raw_relative}" "${_account}" "${_conf}"
            printf "folder-hook -noregex \"%s\" \"source %s\"\n" "$(__account_as_string "${_account}")" "${_conf}"
        done

        cat <<STOP

# vim: filetype=neomuttrc foldmethod=marker
STOP
    } >"${HOME}/dot/dot/d_mail/raw/.config/neomutt/box/multi.conf"
}

__main() {
    local _account
    case "${1}" in
        "config")
            for _account in "xyz" "outlook" "eth" "gmail"; do
                "__${_account}" config
            done
            ;;
        "fdm")
            __config_fdm
            ;;
        "neomutt")
            __neomutt
            ;;
        "xyz" | "outlook" | "eth" | "gmail")
            _account="${1}"
            shift
            "__${_account}" "${@}"
            ;;
    esac
}
__main "${@}"
