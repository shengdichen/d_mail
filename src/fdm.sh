#!/usr/bin/env bash

SCRIPT_PATH="$(realpath "$(dirname "${0}")")"

FDM_CONFIG="${HOME}/.config/fdm/config"

FILE_CONST="$(realpath "${SCRIPT_PATH}/..")/const.sh"
# DIR_MAIL="$("${FILE_CONST}" DIR_MAIL)"
# DIR_MAIL_LOCAL="$("${FILE_CONST}" DIR_MAIL_LOCAL)"
DIR_MAIL_TRASH="$("${FILE_CONST}" DIR_MAIL_TRASH)"
DIR_MAIL_HOLD="$("${FILE_CONST}" DIR_MAIL_HOLD)"
DIR_MAIL_REMOTE="$("${FILE_CONST}" DIR_MAIL_REMOTE)"
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

__is_in() {
    local _target="${1}"
    shift

    local _candidate
    for _candidate in "${@}"; do
        if [ "${_candidate}" = "${_target}" ]; then
            return
        fi
    done
    return 1
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
            __tab
            printf "%s\n" "${_item}"
        done
        printf "}\n"
    }

    __header_from() {
        if [ "${1}" = "--" ]; then shift; fi

        __literal_dot() {
            sed "s/\(\.[^*]\)/\\\\\1/g"
        }

        local _addr _addr_escaped
        for _addr in "${@}"; do
            __tab

            _addr_escaped="$(printf "%s" "${_addr}" | __literal_dot)"
            if printf "%s" "${_addr}" | grep -q "^.\+@"; then
                printf "\"^From:.*[\\\\\\s<]%s\" in headers or" "${_addr_escaped}"
            else
                printf "\"^From:.*@%s\" in headers or" "${_addr_escaped}"
            fi

            printf "\n"
        done
    }

    __match() {
        printf "match\n"
        cat -
    }

    __accounts() {
        # NOTE:
        #   accounts {
        #       "<ACCOUNT_1>"
        #       "<ACCOUNT_2>"
        #       "..."
        #   }

        if [ "${1}" = "--" ]; then shift; fi

        __tab && printf "accounts {\n"
        local _account
        for _account in "${@}"; do
            __tab 2
            printf "\"%s\"\n" "${_account}"
        done
        __tab && printf "}\n"
    }

    __actions() {
        if [ "${1}" = "--" ]; then shift; fi

        __tab && printf "actions {\n"
        local _action
        for _action in "${@}"; do
            __tab 2
            printf "\"%s\"\n" "${_action}"
        done
        __tab && printf "}\n"
    }

    __act() {
        {
            cat -
            printf "\n"
            __actions "${@}"
        } | __match
    }

    case "${1}" in
        "define-account")
            shift
            __define_account "${@}"
            ;;
        "define-action")
            shift
            __define_action "${@}"
            ;;
        "header-from")
            shift
            __header_from "${@}"
            ;;
        "accounts")
            shift
            __accounts "${@}"
            ;;
        "actions")
            shift
            __actions "${@}"
            ;;
        "act")
            shift
            __act "${@}"
            ;;
        "act-trash")
            __act "trash"
            ;;
        "act-delete")
            __act "delete"
            ;;
        "act-keep")
            __act "keep"
            ;;
        *)
            exit 3
            ;;
    esac
}

__main() {
    __make() {
        {
            __base() {
                cat <<STOP
# do NOT add any |Received| tag
set no-received
STOP
            }

            __account() {
                __config define-account "acc_hold" "${DIR_MAIL_HOLD}"

                local _inboxes=(
                    "${DIR_MAIL_REMOTE}/xyz/.INBOX"
                    "${DIR_MAIL_REMOTE}/eth/.INBOX"
                    "${DIR_MAIL_REMOTE}/outlook/.INBOX"
                    "${DIR_MAIL_REMOTE}/gmail/.INBOX"
                )
                __config define-account "acc_raw_inbox" "${_inboxes[@]}"

                local _sents=(
                    "${DIR_MAIL_REMOTE}/xyz/.Sent"
                    "${DIR_MAIL_REMOTE}/eth/.Sent Items"
                    "${DIR_MAIL_REMOTE}/outlook/.Sent"
                    "${DIR_MAIL_REMOTE}/gmail/.[Gmail].E-mails enviados"
                )
                __config define-account "acc_raw_sent" "${_sents[@]}"

                local _ignores=(
                    "${DIR_MAIL_REMOTE}/xyz/.Folders.x"
                    "${DIR_MAIL_REMOTE}/eth/.x"
                    "${DIR_MAIL_REMOTE}/outlook/.x"
                )
                find "${DIR_MAIL_REMOTE}" -mindepth 2 -maxdepth 2 -type d | sort -n |
                    {
                        local _miscs=()
                        local _box
                        while read -r _box; do
                            if ! __is_in "${_box}" "${_inboxes[@]}" "${_sents[@]}" "${_ignores[@]}"; then
                                _miscs+=("${_box}")
                            fi
                        done
                        __config define-account "acc_raw_misc" "${_miscs[@]}"
                    }
            }

            __action() {
                # in descending order of animosity
                __config define-action "${ACTION_DELETE}" -- "drop"
                __config define-action "${ACTION_TRASH}" -- "maildir \"${DIR_MAIL_TRASH}\""
                __config define-action "${ACTION_HOLD}" -- "maildir \"${DIR_MAIL_HOLD}\""
                __config define-action "${ACTION_KEEP}" -- "keep"
                __config define-action "${ACTION_PRINT}" -- "stdout"
            }

            __hold() {
                __config condition-accounts "acc_hold" | __config act-keep
            }

            __trash() {
                {
                    __config header-from -- \
                        "paypal@mail.paypal.de" \
                        "ubs_switzerland@mailing.ubs.com" \
                        \
                        "email.campaign@sg.booking.com" \
                        "mail@e.milesandmore.com" \
                        "mail@mailing.milesandmore.com" \
                        "newsletter@mailing.milesandmore.com" \
                        "newsletter@your.lufthansa-group.com" \
                        \
                        "no-reply@business.amazon.com" \
                        "store-news@amazon.com" \
                        "vfe-campaign-response@amazon.com" \
                        "customer-reviews-messages@amazon.com" \
                        "marketplace-messages@amazon.com" \
                        \
                        "noreply@productnews.galaxus.ch" \
                        "noreply@productnews.digitec.ch" \
                        "noreply@notifications.galaxus.ch" \
                        "galaxus@community.galaxus.ch" \
                        "productnews@galaxus.ch" \
                        "resale@galaxus.ch" \
                        "resale@notifications.galaxus.ch" \
                        "ux@digitecgalaxus.ch" \
                        \
                        "hilfe@tutti.ch" \
                        "comm.tutti.ch" \
                        "notice@info.aliexpress.com" \
                        "newsletter.swarovski.com" \
                        "news.coop.ch" \
                        \
                        "hello@mail.plex.tv" \
                        "ifttt.com" \
                        "mail.blinkist.com" \
                        \
                        "no-reply@swissid.ch" \
                        "info@logistics.post.ch" \
                        \
                        "support@nordvpn.com" \
                        "ipvanish.com" \
                        \
                        "no-reply@.*.proton.me" \
                        "contact@protonmail.com" \
                        \
                        "noreply-dmarc-support@google.com" \
                        "no-reply@accounts.google.com" \
                        "cloud-noreply@google.com" \
                        \
                        "notification@facebookmail.com" \
                        "friendupdates@facebookmail.com" \
                        "reminders@facebookmail.com" \
                        "friendsuggestion@facebookmail.com" \
                        "priority.facebookmail.com" \
                        \
                        "noreply@discord.com" \
                        \
                        ".*.instagram..*" \
                        \
                        "kuiper.sina@bcg.com" \
                        \
                        "ims@schlosstorgelow.de" \
                        "kirstenschreibt@schlosstorgelow.de" \
                        \
                        "mozilla@email.mozilla.org" \
                        \
                        "no-reply@piazza.com" \
                        "noreply@moodle-app2.let.ethz.ch" \
                        \
                        "outgoing@office.iaeste.ch" \
                        "btools.ch" \
                        "projektneptun.ch" \
                        "sprachen.uzh.ch" \
                        "soziologie.uzh.ch" \
                        \
                        "careercenter@news.ethz.ch" \
                        "treffpunkt@news.ethz.ch" \
                        "MicrosoftExchange329e71ec88ae4615bbc36ab6ce41109e@intern.ethz.ch" \
                        "descil@ethz.ch" \
                        "mathbib@math.ethz.ch" \
                        "evasys@let.ethz.ch" \
                        "exchange@ethz.ch" \
                        "president@ethz.ch" \
                        "sgu_training@ethz.ch" \
                        "didaktischeausbildung@ethz.ch" \
                        "entrepreneurship@ethz.ch" \
                        "nikola.kovacevic@inf.ethz.ch" \
                        "compicampus@id.ethz.ch" \
                        "hk.ethz.ch" \
                        "library.ethz.ch" \
                        "sts.ethz.ch" \
                        "sl.ethz.ch"

                    printf "\n"

                    printf "    \"^From:.*DPD-Paket\" in headers\n"
                } | __config act trash

                printf "\n"

                printf "    \"^Subject:.*Test Mail.*\" in headers\n" | __config act trash
            }

            __delete() {
                __config header-from -- \
                    "indiaplays.com" \
                    "kraftangan.gov.my" \
                    "kollect.ai" \
                    "transfiriendo.com" \
                    "fibrasil.com" \
                    "norton.com" \
                    "novaorion.com" \
                    "apparelsite.net" \
                    "farmleap.com" \
                    "yfhuorwa.com" \
                    "moneypeny.fr" \
                    "ronquilloassociates.com" \
                    "preapp1003.com" \
                    "magnusmonitors.com" \
                    "oasdehe.com" \
                    "sion.ais.ne.jp" \
                    "didareshop.com" \
                    "catpro.io" \
                    "mozart.livingopera.org" \
                    "fr.redoutes.com" \
                    "vr7uallms.com" \
                    "caboardroom.com.sg" \
                    "esrtech.io" \
                    "watts.com" \
                    "myfolio.im" \
                    "wettbewerbeundgewinnspiele.ch" \
                    "domenca.raviko.com" \
                    "ukrainianbeauty.com" \
                    "try2ascend.com" \
                    "glsthewinners4you.com" \
                    "neugiab.com" \
                    "ac-creteil.fr" \
                    "getaventura.com" \
                    "cootel.com.ni" \
                    "smart.com.ro" \
                    "itlgt.com" \
                    "binafna.huawei.uk.net" \
                    "darecky.pl" \
                    "montenegromade.com" \
                    "divaniesofa.ro" \
                    "easytrott.fr" \
                    "kiswel.com" \
                    "vmiconic.co.tz" \
                    "citizenpath.com" \
                    "doctorgenius.com" \
                    "upscheckoutrotator.com" \
                    "gc-dienstleistungen.de" \
                    "degoldengeniecasinochrismas.com" \
                    "uporalbseriesdmdrogeriemarkt.com" \
                    "complicesdelsonidoradio.com.ar" \
                    "veracity-trading.com" \
                    "deupscheckoutrotator.com" \
                    "deendurancerhctc.com" \
                    "defitsmartdiet.com" \
                    "vqfit.com" \
                    "otyavaf.co.uk" \
                    "fl0ppfy.co.uk" \
                    "irup5nr.co.uk" \
                    "ss-exports.in" \
                    "devigamanver2foryou.com" \
                    "ecomproesurveys.com" \
                    "ukhermesebookiasts.com" \
                    "smokacevipangebote.net" \
                    "ecaprivatedelivery.com" \
                    "server.cedarhallclinic.uk" \
                    "delidlgiftcard.com" \
                    "destanleytoolsetkaufland.com" \
                    "ukbootsjomaloneadventcalendar.com" \
                    "solidsunenergie.cz" \
                    "deupsblackpageverdelivery.com" \
                    "server.light-review.com" \
                    "cc-aglyfenouilledes.fr" \
                    "renovatio.uk.com" \
                    "cliqtechno.com" \
                    "stnicholasprimaryschool.org" \
                    "sense28.com" \
                    "ueh.edu.vn" \
                    "piecedrillset.de" \
                    "usekilo.com" \
                    "hadiethshop.nl" \
                    "connect.liveapps.store" \
                    "impactinglife.co.uk" \
                    "wgo.com.br" \
                    "host.bkauk.org.uk" \
                    "londontrucks.co.uk" \
                    "asb-hamburg.de" \
                    "dfc.discovery.co.za" \
                    "riseinformatics.com" \
                    "ntf.com" \
                    "clikr.com.br" \
                    "rplexelectrical.in" \
                    "mondrian-it.io" \
                    "capacityproviders.com" \
                    "davulga.bel.tr" \
                    "myhoppophop.fr" \
                    "lv09.katyjenkins.shop" \
                    "k4UBCPR8.fr" \
                    "vydehischool.com" \
                    "steibel.be" \
                    "tisknise.cz" \
                    "campaign.eventbrite.com" \
                    "insistglobal.com" \
                    "montagnes-sciences.fr" \
                    "kenzahn.com" \
                    "insistglobal.com" \
                    "affiligate.com" \
                    "yellowdig.net" \
                    "smtp.assessment.gr" \
                    "shadovn.com" \
                    "send.sw.ofbrand.live" \
                    "client.whitehousenannies.com" \
                    "send.sw.taipanonline.com" \
                    "icar.gov.in" \
                    \
                    "no-reply@flipboard.com" \
                    "support@help.instapaper.com" \
                    "no-reply@instapaper.com" \
                    \
                    "email.wolfram.com" \
                    "go.mathworks.com" \
                    \
                    "diversity@ethz.ch" \
                    "gastro@news.ethz.ch" \
                    "phishing-simulation@id.ethz.ch" \
                    "services.elhz.ch" \
                    \
                    "okabzne@hotmail.com" \
                    "davidcostapro@gmail.com" \
                    "ngoctran071113@gmail.com" \
                    "nhatnguyen31101993@gmail.com" \
                    "FreegsmfsdsFDFDmehdii49@gmx.de"

                printf "    \"^From:.*[\\\\\\s<]Fehler bei der Lieferadresse\" in headers\n"
            }

            __keep() {
                __config accounts "acc_raw_inbox" "acc_raw_sent" "acc_raw_misc" | __config act-keep
            }

            printf "# setup {{{\n"
            __base
            printf "\n"
            printf "# account {{{\n"
            __account
            printf "# }}}\n"
            printf "\n"
            printf "# action {{{\n"
            __action
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
            __delete | __config act-delete
            printf "# }}}\n"
            printf "# }}}\n"

            printf "\n"

            __keep

            cat <<STOP

# vim: filetype=conf foldmethod=marker foldlevel=1
STOP
        } >"${FDM_CONFIG}"
    }
    __make
}
__main
