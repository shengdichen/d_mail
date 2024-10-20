#!/usr/bin/env dash

FDM_CONFIG="${HOME}/.config/fdm/config"

__config() {
    __match_from() {
        local _addr_only
        while [ "${#}" -gt 0 ]; do
            case "${1}" in
                "--addr-only")
                    _addr_only="yes"
                    shift
                    ;;
                "--")
                    shift && break
                    ;;
            esac
        done

        __literal_dot() {
            sed "s/\(\.[^*]\)/\\\\\1/g"
        }

        local _addr
        for _addr in "${@}"; do
            if [ "${_addr_only}" ]; then
                _addr="$(printf "%s" "${_addr}" | __literal_dot)"
                printf "    \"^From:.*[\\\\\\s<]%s\" in headers or" "${_addr}"
            else
                _addr="$(printf "%s" "${_addr}" | sed "s/.*@//" | __literal_dot)"
                printf "    \"^From:.*@%s\" in headers or" "${_addr}"
            fi

            printf "\n"
        done
    }
    case "${1}" in
        "match-from")
            shift
            __match_from "${@}"
            ;;
        *)
            exit 3
            ;;
    esac
}

__main() {
    local _output="${FDM_CONFIG}_new"

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

# the undesirables {{{
# move to trash {{{
match
STOP

            __config match-from --addr-only -- "paypal@mail.paypal.de"
            __config match-from --addr-only -- "ubs_switzerland@mailing.ubs.com"
            __config match-from --addr-only -- "hello@mail.plex.tv"
            __config match-from --addr-only -- "no-reply@swissid.ch"
            __config match-from --addr-only -- "support@nordvpn.com"
            __config match-from --addr-only -- "no-reply@.*.proton.me"
            __config match-from --addr-only -- "contact@protonmail.com"
            __config match-from -- "ipvanish.com"
            __config match-from -- "ifttt.com"

            __blank

            __config match-from --addr-only -- \
                "noreply-dmarc-support@google.com" \
                "no-reply@accounts.google.com" \
                "cloud-noreply@google.com"
            __config match-from --addr-only -- \
                "notification@facebookmail.com" \
                "friendupdates@facebookmail.com" \
                "reminders@facebookmail.com" \
                "friendsuggestion@facebookmail.com"
            __config match-from -- "priority.facebookmail.com"

            __config match-from --addr-only -- "hilfe@tutti.ch"
            __config match-from --addr-only -- "kuiper.sina@bcg.com"
            __config match-from --addr-only -- \
                "ims@schlosstorgelow.de" "kirstenschreibt@schlosstorgelow.de"
            __config match-from --addr-only -- "noreply@discord.com"
            __config match-from --addr-only -- "mozilla@email.mozilla.org"
            __config match-from -- "comm.tutti.ch"
            __config match-from -- "mail.blinkist.com"
            __config match-from -- ".*.instagram..*"

            __blank

            __config match-from --addr-only -- "email.campaign@sg.booking.com"
            __config match-from --addr-only -- \
                "mail@e.milesandmore.com" \
                "mail@mailing.milesandmore.com" \
                "newsletter@mailing.milesandmore.com" \
                "newsletter@your.lufthansa-group.com"
            __config match-from --addr-only -- "notice@info.aliexpress.com"
            __config match-from -- "newsletter.swarovski.com"
            __config match-from -- "news.coop.ch"

            __blank

            __config match-from --addr-only -- \
                "no-reply@business.amazon.com" \
                "store-news@amazon.com" \
                "vfe-campaign-response@amazon.com" \
                "customer-reviews-messages@amazon.com" \
                "marketplace-messages@amazon.com"

            __blank

            __config match-from --addr-only -- \
                "noreply@productnews.galaxus.ch" \
                "noreply@notifications.galaxus.ch" \
                "galaxus@community.galaxus.ch" \
                "productnews@galaxus.ch" \
                "resale@galaxus.ch" \
                "resale@notifications.galaxus.ch" \
                "ux@digitecgalaxus.ch"

            __blank

            __config match-from --addr-only -- "no-reply@piazza.com"
            __config match-from --addr-only -- "outgoing@office.iaeste.ch"
            __config match-from --addr-only -- "careercenter@news.ethz.ch"
            __config match-from -- "btools.ch" "projektneptun.ch"
            __config match-from -- "sprachen.uzh.ch" "soziologie.uzh.ch"

            __blank

            __config match-from --addr-only -- \
                "noreply@moodle-app2.let.ethz.ch" \
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
                "compicampus@id.ethz.ch"
            __config match-from -- \
                "hk.ethz.ch" "library.ethz.ch" "sts.ethz.ch" "sl.ethz.ch"

            __blank

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

# direct deletion {{{
# spam
match
STOP
            printf '    # 1. (bad domain, all accounts)\n'

            __config match-from -- \
                ".*indiaplays.com.*" \
                ".*kraftangan.gov.my.*" \
                ".*kollect.ai.*" \
                ".*transfiriendo.com.*" \
                ".*fibrasil.com.*" \
                ".*norton.com.*" \
                ".*novaorion.com.*" \
                ".*apparelsite.net.*" \
                ".*farmleap.com.*" \
                ".*yfhuorwa.com.*" \
                ".*moneypeny.fr.*" \
                ".*ronquilloassociates.com.*" \
                ".*preapp1003.com.*" \
                ".*magnusmonitors.com.*" \
                ".*oasdehe.com.*" \
                ".*sion.ais.ne.jp.*" \
                ".*didareshop.com.*" \
                ".*catpro.io.*" \
                ".*mozart.livingopera.org.*" \
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
                "campaign.eventbrite.com"

            printf '    # 2. (bad subdomain, all accounts)\n'
            __config match-from -- "email.wolfram.com"
            __config match-from -- "go.mathworks.com"

            printf '    # 3. (good domain, bad account)\n'
            __config match-from --addr-only -- "okabzne@hotmail.com"
            __config match-from --addr-only -- "diversity@ethz.ch"
            __config match-from --addr-only -- "gastro@news.ethz.ch"
            __config match-from --addr-only -- "no-reply@flipboard.com"
            __config match-from --addr-only -- "support@help.instapaper.com"
            __config match-from --addr-only -- "nhatnguyen31101993@gmail.com"
            __config match-from --addr-only -- "LYRIS-e.m-2023.10.05-06.16.06@shadovn.com"
            __config match-from --addr-only -- "postmaster@smtp.assessment.gr"
            __config match-from --addr-only -- "support@affiligate.com"
            __config match-from --addr-only -- "dw-1298858contact@insistglobal.com"
            __config match-from --addr-only -- "info@montagnes-sciences.fr"
            __config match-from --addr-only -- "BDiduxHIFF@yellowdig.net"
            __config match-from --addr-only -- "ecotto@kenzahn.com"
            __config match-from --addr-only -- "Ashish.Biswas@icar.gov.in"
            __config match-from --addr-only -- "davidcostapro@gmail.com"
            __config match-from --addr-only -- "ngoctran071113@gmail.com"
            __config match-from --addr-only -- "FreegsmfsdsFDFDmehdii49@gmx.de"
            __blank

            cat <<STOP
    "^From:.*[\\\\s<]Fehler bei der Lieferadresse" in headers
    #
    actions {
        "delete"
    }
# }}}
# }}}

match
    accounts {
        "acc_hold"
        "acc_raw_inbox"
        "acc_raw_sent"
        "acc_raw_misc"
    }
    actions {
        "keep"
    }

# vim: filetype=conf foldmethod=marker foldlevel=1
STOP
        } >"${_output}"
    }
    __make

    nvim -d "${_output}" "${FDM_CONFIG}"
    rm "${_output}"
}
__main
