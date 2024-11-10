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

    case "${1}" in
        "define-account")
            shift
            __define_account "${@}"
            ;;
        "define-action")
            shift
            __define_action "${@}"
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
                {
                    __config condition-accounts -- "acc_hold"
                    __config condition-END
                } | __config do-keep
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
                    __config condition-accounts -- \
                        "acc_raw_inbox" "acc_raw_sent" "acc_raw_misc"
                    __config condition-AND

                    __config condition-regex-header -- \
                        "${_addrs[@]}"
                    __config condition-OR
                    __config condition-regex-header -- \
                        "${_names[@]}"
                    __config condition-OR
                    __config condition-regex-header \
                        --header subject \
                        -- "${_subjects[@]}"

                    __config condition-END
                } | __config do-trash
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
                    __config condition-accounts -- \
                        "acc_raw_inbox" "acc_raw_sent" "acc_raw_misc"
                    __config condition-AND

                    __config condition-regex-header -- "${_addrs[@]}"
                    __config condition-OR
                    __config condition-regex-header -- "${_names[@]}"

                    __config condition-END
                } | __config do-delete
            }

            __keep() {
                {
                    __config condition-accounts -- \
                        "acc_raw_inbox" "acc_raw_sent" "acc_raw_misc"
                    __config condition-END
                } | __config do-keep
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
            __delete
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
