#!/usr/bin/env dash

FDM_CONFIG="${HOME}/.config/fdm/config"

__tab() {
    local _n="${1-"1"}"
    for _ in $(seq "${_n}"); do
        printf "    "
    done
}

__config() {
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
        __blank() {
            printf "    #\n"
        }

        {
            cat <<STOP
# do NOT add any |Received| tag
set no-received

# setup {{{
\$base_dir = "%h/.local/share/mail"
\$all_dir = "\${base_dir}/all"
\$trash_dir = "\${all_dir}/.trash"
\$hold_dir = "\${all_dir}/.hold"

# account {{{
account "acc_hold"
    maildirs {
        "\${hold_dir}"
    }

\$raw_dir = "\${base_dir}/raw"
\$path_xyz = "\${raw_dir}/xyz"
\$path_eth = "\${raw_dir}/eth"
\$path_outlook = "\${raw_dir}/outlook"
\$path_gmail = "\${raw_dir}/gmail"
account "acc_raw_inbox"
    maildirs {
        "\${path_xyz}/.INBOX"
        "\${path_eth}/.INBOX"
        "\${path_outlook}/.INBOX"
        "\${path_gmail}/.INBOX"
    }
account "acc_raw_sent"
    maildirs {
        "\${path_xyz}/.Sent"
        "\${path_eth}/.Sent Items"
        "\${path_outlook}/.Sent"
        "\${path_gmail}/.[Gmail].E-mails enviados"
    }
# other folders that we would like fdm to monitor
account "acc_raw_misc"
    maildirs {
        "\${path_xyz}/.Spam"
        "\${path_xyz}/.Trash"
        "\${path_outlook}/.Junk"
        "\${path_outlook}/.Deleted"
        "\${path_gmail}/.[Gmail].Spam"
    }
# }}}

# action {{{
# in descending order of animosity
action "delete"
    drop

action "trash"
    maildir "\${trash_dir}"

action "hold"
    maildir "\${hold_dir}"

action "keep"
    keep

action "print"
    stdout
# }}}
# }}}
STOP

            cat <<STOP
# the undesirables {{{
# move to trash {{{
match
STOP

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

            cat <<STOP
    "^From:.*DPD-Paket" in headers
    #
    actions {
        "trash"
    }

match
    "^Subject:.*Test Mail.*" in headers
    actions {
        "trash"
    }
# }}}
STOP

            # direct deletion {{{
            {
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
                    \
                    "no-reply@flipboard.com" \
                    "support@help.instapaper.com" \
                    \
                    "email.wolfram.com" \
                    "go.mathworks.com" \
                    \
                    "diversity@ethz.ch" \
                    "gastro@news.ethz.ch"

                __config header-from -- \
                    "okabzne@hotmail.com" \
                    "davidcostapro@gmail.com" \
                    "ngoctran071113@gmail.com" \
                    "nhatnguyen31101993@gmail.com" \
                    "FreegsmfsdsFDFDmehdii49@gmx.de" \
                    "Ashish.Biswas@icar.gov.in"

                cat <<STOP
    "^From:.*[\\\\s<]Fehler bei der Lieferadresse" in headers
STOP
            } | __config act-delete

            cat <<STOP
# }}}
# }}}
STOP
            # }}}

            __config accounts "acc_hold" "acc_raw_inbox" "acc_raw_sent" "acc_raw_misc" | __config act-keep

            cat <<STOP

# vim: filetype=conf foldmethod=marker foldlevel=1
STOP
        } >"${FDM_CONFIG}"
    }
    __make
}
__main
