#!/usr/bin/env bash
# This file is meant to be sourced into your bashrc & not ran standalone.

if [[ -n "$__FCOLOUR_LOADED" ]]; then
    return 0
fi
readonly __FCOLOUR_LOADED="__LOADED"

DIR=$(dirname -- "$BASH_SOURCE")

source "$DIR/colours.sh"

__colour_dir () (
    [[ -z "$*" ]] && return 2 
    
    local ffn="$1"
    local bfn="$2"
    
    local ls_dir_sub=("$ffn/"*)
    local ls_dir_sub_count=${#ls_dir_sub[@]}
    
    local coloured_dir="$_FLBLUE$bfn$_NOCOLOUR"
    [[ $ls_dir_sub_count -gt 0 ]] && local coloured_dir="$_FBLUE$bfn$_NOCOLOUR"
    if [[ -h "$ffn" ]]; then
        local coloured_dir="$_BLBLUE$bfn$_NOCOLOUR"
        [[ $ls_dir_sub_count -gt 0 ]] && local coloured_dir="$_BBLUE$_FWHITE$bfn$_NOCOLOUR"
    fi
    
    echo "$coloured_dir"
)

__colour_symlink () (
    [[ -z "$*" ]] && return 2
    
    local ffn="$1"
    local bfn="$2"
    
    echo "$_BRED$_FWHITE$bfn$_NOCOLOUR"
)

__colour_file () (
    [[ -z "$*" ]] && return 2 
    
    local ffn="$1"
    local bfn="$2"
    
    local ext="${bfn#*.}"
    local head="$(head -n 1 "$ffn" 2> /dev/null | tr -d '\0')"
    
    local coloured_file="$bfn"
    [[ -h "$ffn" ]] && local coloured_file="$_BWHITE$_FBLACK$bfn$_NOCOLOUR"
    if [[ -x "$ffn" ]]; then
        local coloured_file="$_FGREEN$bfn$_NOCOLOUR"
        [[ -h "$ffn" ]] && local coloured_file="$_BGREEN$_FWHITE$bfn$_NOCOLOUR"
    fi
    
    case "$head" in
        "#!/usr/bin/env python"* | \
        "#!/usr/bin/python"* | \
        "#!python"*) 
            local coloured_file="$_FYELLOW$bfn$_NOCOLOUR"
            [[ -h "$ffn" ]] && local coloured_file="$_BYELLOW$_FWHITE$bfn$_NOCOLOUR"
            echo "$coloured_file" && return 
            ;;
        "#!/usr/bin/env bash"* | \
        "#!/bin/bash"* | \
        "#!/bin/sh"* | \
        "#/usr/local/bin/bash"* )
            local coloured_file="$_FPGREEN$bfn$_NOCOLOUR"
            [[ -h "$ffn" ]] && local coloured_file="$_BPGREEN$_FWHITE$bfn$_NOCOLOUR"
            echo "$coloured_file" && return
            ;;
    esac
    
    case "$ext" in
        "py" | "pyc" | "pyo" | "pyd" )
            local coloured_file="$_FYELLOW$bfn$_NOCOLOUR"
            [[ -h "$ffn" ]] && local coloured_file="$_BYELLOW$_FWHITE$bfn$_NOCOLOUR"
            echo "$coloured_file" && return
            ;; 
        "sh" )
            local coloured_file="$_FPGREEN$bfn$_NOCOLOUR"
            [[ -h "$ffn" ]] && local coloured_file="$_BPGREEN$_FWHITE$bfn$_NOCOLOUR"
            echo "$coloured_file" && return
            ;;
        "521" | \
        "abs" | \
        "adb" | \
        "adba" | \
        "ae0" | \
        "ams" | \
        "api" | \
        "apm" | \
        "asgp" | \
        "autoconf" | \
        "avastconfig" | \
        "avgconfig" | \
        "axc" | \
        "bfd" | \
        "bgi" | \
        "bitcfg" | \
        "bitpim" | \
        "bochsrc" | \
        "bootstrap" | \
        "brg" | \
        "bsi" | \
        "bsl" | \
        "btf" | \
        "bus" | \
        "bwz" | \
        "bxrc" | \
        "c" | \
        "ccb" | \
        "ccf" | \
        "ccfg" | \
        "cch" | \
        "ccr" | \
        "cdd" | \
        "ced" | \
        "ceid" | \
        "cekey" | \
        "cezeokey" | \
        "cf" | \
        "cf3" | \
        "cfg" | \
        "cfs" | \
        "cgi" | \
        "ch" | \
        "cha" | \
        "chat" | \
        "chf" | \
        "cld" | \
        "cm" | \
        "cmate" | \
        "cnf" | \
        "cnn" | \
        "color" | \
        "con" | \
        "conf" | \
        "conf-auto" | \
        "config" | \
        "cos" | \
        "cq" | \
        "crp" | \
        "cscfg" | \
        "csd" | \
        "csr" | \
        "ctr" | \
        "cwc" | \
        "cwy" | \
        "dbc" | \
        "dcb" | \
        "dcc" | \
        "dcf" | \
        "dcfg" | \
        "ddt" | \
        "devicemetadata-ms" | \
        "dfc" | \
        "diagcfg" | \
        "dks" | \
        "dmc" | \
        "dno" | \
        "dockerignore" | \
        "drh" | \
        "dtpc" | \
        "dtsconfig" | \
        "dtsearch" | \
        "dvp" | \
        "dyc" | \
        "ecf" | \
        "ecu" | \
        "efc" | \
        "eg2" | \
        "ehi" | \
        "elc" | \
        "emv" | \
        "epf" | \
        "eqconfig" | \
        "esi" | \
        "esp" | \
        "evp" | \
        "ewc" | \
        "exe4j" | \
        "exprwdconfig" | \
        "ezc" | \
        "ezhex" | \
        "fbk" | \
        "fdp" | \
        "ffs_batch" | \
        "ffs_gui" | \
        "ffs_real" | \
        "fhx" | \
        "fig" | \
        "fpw" | \
        "fsi" | \
        "fst" | \
        "ftp" | \
        "ftpconfig" | \
        "fwt" | \
        "fxc" | \
        "g16" | \
        "gdm" | \
        "gdt" | \
        "gen" | \
        "geo" | \
        "ghi" | \
        "gitconfig" | \
        "gladinetsp" | \
        "global" | \
        "gml" | \
        "god" | \
        "grd" | \
        "gsd" | \
        "hcfg" | \
        "hcm" | \
        "hcr" | \
        "hcu" | \
        "helpcfg" | \
        "hexdwc" | \
        "hfc" | \
        "hfmx" | \
        "hid" | \
        "htaccess" | \
        "iaf" | \
        "ica" | \
        "icte" | \
        "ifb" | \
        "igd" | \
        "iip" | \
        "ini2" | \
        "inuse" | \
        "inz" | \
        "iok" | \
        "iom" | \
        "irafhosts" | \
        "isc" | \
        "iuux" | \
        "ivc" | \
        "jcf" | \
        "jic" | \
        "jkm" | \
        "joy" | \
        "jtg" | \
        "jvr" | \
        "kcf" | \
        "keyboard" | \
        "kgr" | \
        "ktw" | \
        "launch" | \
        "lcc" | \
        "lct" | \
        "ld" | \
        "leases" | \
        "les" | \
        "llp" | \
        "lnt" | \
        "lpd" | \
        "lvt" | \
        "magic" | \
        "mbc" | \
        "mcc" | \
        "mcd" | \
        "mcs" | \
        "mcserver" | \
        "mdrc" | \
        "me" | \
        "met" | \
        "mew" | \
        "mhc" | \
        "mky" | \
        "mm3" | \
        "mm4" | \
        "mmf" | \
        "mmrc" | \
        "mozconfig" | \
        "mpa" | \
        "mspl" | \
        "mxd" | \
        "mxu" | \
        "nba" | \
        "nbo" | \
        "ncc" | \
        "ncf" | \
        "ncfg" | \
        "nck" | \
        "ncm" | \
        "ne0" | \
        "net" | \
        "netsh" | \
        "nfg" | \
        "nns" | \
        "nsd" | \
        "nsu" | \
        "olsr" | \
        "opf" | \
        "opt" | \
        "options" | \
        "opts" | \
        "ora" | \
        "osd" | \
        "ovpn" | \
        "p9d" | \
        "par" | \
        "parm" | \
        "pat" | \
        "pb" | \
        "pb1" | \
        "pb2" | \
        "pc2" | \
        "pc3" | \
        "pcf" | \
        "pcp" | \
        "pdk" | \
        "perfmoncfg" | \
        "perlcriticrc" | \
        "pfg" | \
        "phl" | \
        "pln" | \
        "pltcfg" | \
        "pnagent" | \
        "pnc" | \
        "prb" | \
        "prm" | \
        "pro" | \
        "profiles" | \
        "properties" | \
        "proxy" | \
        "prp" | \
        "prt" | \
        "ps1xml" | \
        "psrc" | \
        "ptg" | \
        "pth" | \
        "pti" | \
        "pui" | \
        "pvx" | \
        "pwr" | \
        "pxc" | \
        "pxg" | \
        "qdr" | \
        "qwc" | \
        "rak" | \
        "rap" | \
        "rb" | \
        "rc" | \
        "rcf" | \
        "rdg" | \
        "resourceconfig" | \
        "rsp" | \
        "rsx" | \
        "rta" | \
        "scc" | \
        "sch" | \
        "sconscript" | \
        "scp" | \
        "scpcfg" | \
        "sdc" | \
        "sdg" | \
        "set" | \
        "settingcontent-ms" | \
        "sgc" | \
        "siz" | \
        "soc" | \
        "spd" | \
        "spdesignconfig" | \
        "srf" | \
        "srv" | \
        "status" | \
        "sublime-workspace" | \
        "sup" | \
        "svy" | \
        "sxc" | \
        "sxcu" | \
        "sxp" | \
        "sydx" | \
        "t4" | \
        "tbr" | \
        "tc" | \
        "td" | \
        "td2" | \
        "tds" | \
        "tdw" | \
        "tf" | \
        "tfa" | \
        "tgb" | \
        "tim" | \
        "tll" | \
        "tm" | \
        "tmap" | \
        "top" | \
        "tsm" | \
        "tvc" | \
        "twc" | \
        "txm" | \
        "uae" | \
        "ubb" | \
        "ubr" | \
        "ucf" | \
        "und" | \
        "uvoptx" | \
        "vcf" | \
        "vcl" | \
        "vimrc" | \
        "vis" | \
        "vmc" | \
        "vpn" | \
        "vrf" | \
        "vsc" | \
        "vsh" | \
        "vue" | \
        "vv" | \
        "vvi" | \
        "wadcfg" | \
        "wbx" | \
        "wcf" | \
        "wcr" | \
        "wda" | \
        "wed" | \
        "wlm" | \
        "wsb" | \
        "wsp" | \
        "wti" | \
        "wxa" | \
        "wys" | \
        "x4k" | \
        "xcpad" | \
        "xdfl" | \
        "xilize" | \
        "xmc" | \
        "xnp" | \
        "xpl" | \
        "yaml" | \
        "ypf" | \
        "yt" | \
        "zc" | \
        "zcc" | \
        "zcfg" | \
        "zup" | \
        "zzb" | \
        "zzc" | \
        "zzd" | \
        "zze" | \
        "zzf" | \
        "zzk" | \
        "zzp" | \
        "zzt" )
            local coloured_file="$_FCYAN$bfn$_NOCOLOUR"
            [[ -h "$ffn" ]] && local coloured_file="$_BCYAN$_FWHITE$bfn$_NOCOLOUR"
            echo "$coloured_file" && return
            ;;
        "_02" | \
        "10" | \
        "16" | \
        "2" | \
        "2ch" | \
        "3ga" | \
        "7" | \
        "8svx" | \
        "aa3" | \
        "aaf" | \
        "aax" | \
        "abc" | \
        "abk" | \
        "abm" | \
        "ac7" | \
        "acd" | \
        "acid" | \
        "acm" | \
        "ad2" | \
        "ad3" | \
        "ad4" | \
        "adg" | \
        "adts" | \
        "afs" | \
        "ahx" | \
        "ajp" | \
        "alb" | \
        "alc" | \
        "als" | \
        "amxd" | \
        "amz" | \
        "ang" | \
        "aob" | \
        "ap4" | \
        "architect" | \
        "arf" | \
        "aria" | \
        "atp" | \
        "aud" | \
        "audio" | \
        "audionote" | \
        "aupreset" | \
        "ay" | \
        "azx" | \
        "bmu" | \
        "bmw" | \
        "bnk" | \
        "br25" | \
        "br27" | \
        "br28" | \
        "br29" | \
        "br4" | \
        "br5" | \
        "brr" | \
        "bvf" | \
        "bww" | \
        "camelsounds" | \
        "cdg" | \
        "cdo" | \
        "ckb" | \
        "ckf" | \
        "cmo" | \
        "cs3" | \
        "cvs" | \
        "cwb" | \
        "cwp" | \
        "dat" | \
        "dau" | \
        "dcf" | \
        "dig" | \
        "dkd" | \
        "dm1" | \
        "dmkit" | \
        "dmpatch" | \
        "dmptrn" | \
        "dmse" | \
        "dpdoc" | \
        "dra" | \
        "drx" | \
        "ds2" | \
        "dsd" | \
        "dsf" | \
        "dss" | \
        "dtm" | \
        "dtshd" | \
        "dva" | \
        "dvc" | \
        "dvf" | \
        "dvw" | \
        "dwp" | \
        "e2ev" | \
        "ea" | \
        "eac3" | \
        "elastik" | \
        "elp" | \
        "eol" | \
        "eop" | \
        "es" | \
        "esu" | \
        "evx" | \
        "exb" | \
        "fc4" | \
        "flm" | \
        "fnf" | \
        "fst" | \
        "ftc" | \
        "gbs" | \
        "gm" | \
        "gog" | \
        "gpbank" | \
        "gpx" | \
        "gtp" | \
        "h2p" | \
        "h2song" | \
        "hh" | \
        "hma" | \
        "hsb" | \
        "i3pack" | \
        "isb" | \
        "itz" | \
        "kam" | \
        "kar" | \
        "kfn" | \
        "kin" | \
        "kma" | \
        "koz" | \
        "krx" | \
        "la" | \
        "lme" | \
        "lms" | \
        "logicx" | \
        "lvp" | \
        "ly" | \
        "m2s" | \
        "m3a" | \
        "m3v" | \
        "mct" | \
        "mes" | \
        "mf3" | \
        "mfb" | \
        "mff" | \
        "mg2" | \
        "mgb" | \
        "mgu" | \
        "mia" | \
        "minibank" | \
        "mk1" | \
        "mkf" | \
        "mmjproject" | \
        "mmm" | \
        "mmpz" | \
        "mo3" | \
        "mogg" | \
        "moi" | \
        "mp_" | \
        "mp3" | \
        "mp3a" | \
        "mp3g" | \
        "mpc" | \
        "mpdp" | \
        "mscx" | \
        "mscz" | \
        "msv" | \
        "mt_" | \
        "mtd" | \
        "muk" | \
        "mus" | \
        "musx" | \
        "mv3" | \
        "mwk" | \
        "mww" | \
        "mx1" | \
        "mx4" | \
        "mx5" | \
        "mx6" | \
        "mxl" | \
        "my" | \
        "myr" | \
        "mz" | \
        "n3a" | \
        "nak" | \
        "nbkt" | \
        "nbs" | \
        "nfm8" | \
        "ngrr" | \
        "niff" | \
        "nki" | \
        "nmf" | \
        "nmsv" | \
        "npr" | \
        "nsla" | \
        "nsmp" | \
        "nsp" | \
        "nst" | \
        "nwp" | \
        "nxt" | \
        "ocdf" | \
        "odd" | \
        "oga" | \
        "oma" | \
        "omf" | \
        "omx" | \
        "opus" | \
        "ove" | \
        "oxm" | \
        "pc" | \
        "pcm" | \
        "plp" | \
        "pno" | \
        "psi" | \
        "ptb" | \
        "pttune" | \
        "ptx" | \
        "puma" | \
        "pw3" | \
        "qcp" | \
        "rcp" | \
        "rec" | \
        "record" | \
        "rex" | \
        "rf64" | \
        "rfl" | \
        "rgp" | \
        "rhl" | \
        "rhp" | \
        "rip" | \
        "rns" | \
        "rpp" | \
        "rsf" | \
        "rsn" | \
        "rso" | \
        "rta" | \
        "rtm" | \
        "rx2" | \
        "s48" | \
        "sa1" | \
        "sabl" | \
        "sabs" | \
        "sag" | \
        "sbg" | \
        "sbm" | \
        "sd2f" | \
        "sdat" | \
        "sesx" | \
        "sfz" | \
        "sg2" | \
        "sg4" | \
        "sgu" | \
        "sgw" | \
        "sib" | \
        "slx" | \
        "smf" | \
        "smfmf" | \
        "smp" | \
        "sn" | \
        "snd" | \
        "sng" | \
        "song" | \
        "sqt" | \
        "sri" | \
        "ssdl" | \
        "st3" | \
        "stem" | \
        "stem.mp4" | \
        "svd" | \
        "svq" | \
        "swa" | \
        "swv" | \
        "tak" | \
        "thd" | \
        "tks" | \
        "tl" | \
        "tn7" | \
        "tqd" | \
        "trm" | \
        "tsh" | \
        "tsl" | \
        "uvd" | \
        "uvn" | \
        "v8" | \
        "vbk" | \
        "vdj" | \
        "vdjsample" | \
        "vgm" | \
        "vif" | \
        "vig" | \
        "vm" | \
        "vmo" | \
        "vox" | \
        "voxal" | \
        "vsi" | \
        "vsq" | \
        "vsqx" | \
        "vst" | \
        "vy3" | \
        "vy4" | \
        "vyf" | \
        "w01" | \
        "w02" | \
        "w03" | \
        "w06" | \
        "w07" | \
        "waptt" | \
        "wave" | \
        "weba" | \
        "wem" | \
        "wpp" | \
        "wrf" | \
        "wrk" | \
        "wsx" | \
        "wv" | \
        "x3a" | \
        "x3v" | \
        "xkr" | \
        "xmz" | \
        "xpak" | \
        "xpf" | \
        "xsb" | \
        "xt" | \
        "xvag" | \
        "xwb" | \
        "xwma" | \
        "ym" | \
        "ytif" | \
        "zab" | \
        "zaf" | \
        "zax" | \
        "zik" | \
        "zvr" )
            local coloured_file="$_FPURPLE$bfn$_NOCOLOUR"
            [[ -h "$ffn" ]] && local coloured_file="$_BPURPLE$_FWHITE$bfn$_NOCOLOUR"
            echo "$coloured_file" && return
            ;;
        "avi" | \
        "261" | \
        "263" | \
        "265" | \
        "3gp_128x96" | \
        "44" | \
        "4xm" | \
        "603" | \
        "60d" | \
        "800" | \
        "890" | \
        "aec" | \
        "am2" | \
        "am7" | \
        "amc" | \
        "amv" | \
        "anydesk" | \
        "apz" | \
        "aqt" | \
        "arcut" | \
        "arf" | \
        "asdvdcrtproj" | \
        "aut" | \
        "avd" | \
        "avf" | \
        "avh" | \
        "avr" | \
        "axm" | \
        "bay" | \
        "bbv" | \
        "bdav" | \
        "bdmv" | \
        "bdtp" | \
        "bix" | \
        "biz" | \
        "bnk" | \
        "bs4" | \
        "bu" | \
        "bub" | \
        "buy" | \
        "bvr" | \
        "cak" | \
        "cam" | \
        "camproj" | \
        "camrec" | \
        "cine" | \
        "clk" | \
        "cpk" | \
        "cpvc" | \
        "crec" | \
        "crv" | \
        "cvc" | \
        "cx3" | \
        "d2v" | \
        "dash" | \
        "dav" | \
        "dc8" | \
        "dce" | \
        "dcf" | \
        "dcr" | \
        "demo" | \
        "demo4" | \
        "dfxp" | \
        "dgw" | \
        "djanimations" | \
        "dmsd" | \
        "dmsm" | \
        "dmss" | \
        "dmx" | \
        "dof" | \
        "doink-gs" | \
        "dpg" | \
        "drc" | \
        "dscf" | \
        "dsm" | \
        "dtcp-ip" | \
        "dtv" | \
        "dv4" | \
        "dv5" | \
        "dv-avi" | \
        "dvddata" | \
        "dvdmedia" | \
        "dvdrip" | \
        "dvm" | \
        "dvt" | \
        "dvx" | \
        "dwz" | \
        "dxa" | \
        "el8" | \
        "encm" | \
        "epj" | \
        "epm" | \
        "es3" | \
        "eti" | \
        "etrg" | \
        "ev2" | \
        "eva" | \
        "evo" | \
        "exo" | \
        "eye" | \
        "ezp" | \
        "eztv" | \
        "fbr" | \
        "fcp" | \
        "fcpxml" | \
        "film" | \
        "flc" | \
        "flexolibrary" | \
        "flh" | \
        "fli" | \
        "fli_" | \
        "flux" | \
        "flvat" | \
        "fm2" | \
        "fmv" | \
        "fsv" | \
        "ftvx" | \
        "fvt" | \
        "g2m" | \
        "g64" | \
        "g64x" | \
        "gfp" | \
        "gifv" | \
        "gir" | \
        "gmm" | \
        "grasp" | \
        "gts" | \
        "gvi" | \
        "gxf" | \
        "h260" | \
        "h263" | \
        "h265" | \
        "h3r" | \
        "h4v" | \
        "h64" | \
        "hav" | \
        "hbox" | \
        "hevc" | \
        "hgd" | \
        "hkv" | \
        "hls" | \
        "hlv" | \
        "hmt" | \
        "hmv" | \
        "hnm" | \
        "hq" | \
        "htd" | \
        "htp" | \
        "hup" | \
        "hvc1" | \
        "ifv" | \
        "iis" | \
        "ilm" | \
        "imovietrailer" | \
        "irf" | \
        "ismv" | \
        "iva" | \
        "ivf" | \
        "ivm" | \
        "ivs" | \
        "jmf" | \
        "jmm" | \
        "jpv" | \
        "jts" | \
        "jyk" | \
        "k3g" | \
        "kava" | \
        "kmv" | \
        "kux" | \
        "l3" | \
        "l32" | \
        "lrec" | \
        "lrv" | \
        "lsproj" | \
        "lsx" | \
        "lza" | \
        "m1s" | \
        "m21" | \
        "m2s" | \
        "m4f" | \
        "m4s" | \
        "m65" | \
        "mbv" | \
        "mcf" | \
        "mcv" | \
        "mep" | \
        "mepx" | \
        "mgv" | \
        "mhg" | \
        "mio" | \
        "mj2" | \
        "mjp" | \
        "mjp2" | \
        "m-jpeg" | \
        "mjpeg" | \
        "mjpg" | \
        "ml20" | \
        "mmp" | \
        "moff" | \
        "mp4" | \
        "mp4v" | \
        "mp4;v=1" | \
        "mp7" | \
        "mpeg1" | \
        "mpeg2" | \
        "mpeg4" | \
        "mpegps" | \
        "mpg2" | \
        "mpgv" | \
        "mpgx" | \
        "mpj" | \
        "mps" | \
        "mqv" | \
        "mts1" | \
        "mtv" | \
        "mv" | \
        "mv1" | \
        "mv2" | \
        "mvc" | \
        "mvd" | \
        "mvf" | \
        "mvr" | \
        "mvv" | \
        "mvy" | \
        "mxv" | \
        "mkv" | \
        "n3r" | \
        "nde" | \
        "nfv" | \
        "nmm" | \
        "noa" | \
        "npv" | \
        "nvc" | \
        "nvl" | \
        "nxv" | \
        "ogx" | \
        "osp" | \
        "otrkey" | \
        "p2" | \
        "par" | \
        "pds" | \
        "pgmx" | \
        "pmp" | \
        "ppp" | \
        "pproj" | \
        "ps" | \
        "pvr" | \
        "px" | \
        "pxm" | \
        "pxv" | \
        "pyv" | \
        "pz" | \
        "qcif" | \
        "qmx" | \
        "qtm" | \
        "qvt" | \
        "r3d" | \
        "rargb" | \
        "ratDVD" | \
        "ravi" | \
        "rca" | \
        "rcrec" | \
        "rdg" | \
        "rdt" | \
        "rec" | \
        "rec_part0" | \
        "rec_part1" | \
        "rec_part2" | \
        "rec_part3" | \
        "rki" | \
        "rmhd" | \
        "roq" | \
        "rpl" | \
        "rt4" | \
        "rtv" | \
        "rum" | \
        "rvl" | \
        "s11" | \
        "s2e" | \
        "s4ud" | \
        "san" | \
        "sbs" | \
        "scc" | \
        "scm" | \
        "scn" | \
        "scr" | \
        "screenrec" | \
        "sdr2" | \
        "sdv" | \
        "seq" | \
        "siv" | \
        "slc" | \
        "smv" | \
        "splash" | \
        "sqz" | \
        "ssif" | \
        "ssw" | \
        "st4" | \
        "stj" | \
        "stk" | \
        "strg" | \
        "stu" | \
        "svcd" | \
        "svi" | \
        "swi" | \
        "tdt2" | \
        "tgv" | \
        "theater" | \
        "tivo" | \
        "tmi" | \
        "tms" | \
        "tp0" | \
        "trec" | \
        "tridefmovie" | \
        "trn" | \
        "ts4" | \
        "tscproj" | \
        "tsp" | \
        "tts" | \
        "tv" | \
        "tvs" | \
        "tvv" | \
        "ty" | \
        "ub1" | \
        "um4" | \
        "urc" | \
        "usm" | \
        "uvs" | \
        "v264" | \
        "vc1" | \
        "vcd" | \
        "vcl" | \
        "vcm" | \
        "vcpf" | \
        "vcr" | \
        "vcv" | \
        "vdr" | \
        "veg" | \
        "vep" | \
        "vep4" | \
        "vf" | \
        "vfo" | \
        "vg" | \
        "vg2" | \
        "vghd" | \
        "vgx" | \
        "vgz" | \
        "vid" | \
        "video" | \
        "viewlet" | \
        "vmlf" | \
        "vmm" | \
        "vod" | \
        "vp3" | \
        "vp6" | \
        "vp7" | \
        "vp8" | \
        "vp9" | \
        "vpd" | \
        "vpg" | \
        "vpj" | \
        "vprj" | \
        "vproj" | \
        "vs2" | \
        "vs4" | \
        "vse" | \
        "vvf" | \
        "w32" | \
        "w3d" | \
        "wfp" | \
        "wfsp" | \
        "wm3" | \
        "wmv3" | \
        "wsve" | \
        "wve" | \
        "webm" | \
        "xba" | \
        "xlmv" | \
        "xmm" | \
        "xmv" | \
        "xpv" | \
        "xtodvd" | \
        "xvw" | \
        "y4m" | \
        "yify" | \
        "yts" | \
        "zeg" )
            local coloured_file="$_FDORANGE$bfn$_NOCOLOUR"
            [[ -h "$ffn" ]] && local coloured_file="$_BDORANGE$_FWHITE$bfn$_NOCOLOUR"
            echo "$coloured_file" && return
            ;;
        "7z" | \
        "7-zip" | \
        "7zip" | \
        "a20" | \
        "aar" | \
        "abbu" | \
        "ace" | \
        "adf" | \
        "afa" | \
        "air" | \
        "akp" | \
        "alz" | \
        "ap" | \
        "apple" | \
        "appv" | \
        "appxbundle" | \
        "arc" | \
        "arch00" | \
        "arj" | \
        "ark" | \
        "as4a" | \
        "asd" | \
        "asec" | \
        "atr" | \
        "axr" | \
        "b1" | \
        "b64" | \
        "ba" | \
        "bag" | \
        "bar" | \
        "bba" | \
        "bcz" | \
        "bee" | \
        "bel" | \
        "bh" | \
        "bin" | \
        "blb" | \
        "bma" | \
        "bnd" | \
        "boe" | \
        "boo" | \
        "btc" | \
        "bun" | \
        "bvx" | \
        "bz" | \
        "bz2" | \
        "ca1" | \
        "cab" | \
        "car" | \
        "carb" | \
        "caz" | \
        "cb7" | \
        "cbr" | \
        "cbt" | \
        "cbv" | \
        "cbz" | \
        "ccn" | \
        "cdoc" | \
        "cmp" | \
        "cpgz" | \
        "cpio" | \
        "cpk" | \
        "cpt" | \
        "crf" | \
        "csk" | \
        "cso" | \
        "ctp" | \
        "cv" | \
        "czip" | \
        "dak" | \
        "dar" | \
        "dax" | \
        "dbz" | \
        "dd" | \
        "deb" | \
        "desktop" | \
        "devpak" | \
        "dfl" | \
        "diagcab" | \
        "djprojects" | \
        "dl_" | \
        "dlc" | \
        "dms" | \
        "drs" | \
        "drz" | \
        "dtsx" | \
        "dtz" | \
        "dub" | \
        "dwz" | \
        "eappx" | \
        "ear" | \
        "edz" | \
        "egg" | \
        "emk" | \
        "enc4" | \
        "enlx" | \
        "enpack" | \
        "ex_" | \
        "fb" | \
        "fcxe" | \
        "flmod" | \
        "fmu" | \
        "fpk" | \
        "frp" | \
        "fwp" | \
        "gbx" | \
        "gca" | \
        "gip" | \
        "gpk" | \
        "gr_" | \
        "gro" | \
        "gta" | \
        "gtar" | \
        "gxx" | \
        "gz" | \
        "gzip" | \
        "ha" | \
        "hbc" | \
        "hpa" | \
        "hqx" | \
        "htmlz" | \
        "ice" | \
        "igz" | \
        "iha" | \
        "imoviemobile" | \
        "inv" | \
        "ipa" | \
        "isz" | \
        "iwa" | \
        "iwd" | \
        "ize" | \
        "ja" | \
        "jar" | \
        "jso" | \
        "kep" | \
        "kgb" | \
        "kge" | \
        "kz" | \
        "lg" | \
        "lha" | \
        "lime" | \
        "lrz" | \
        "lz" | \
        "lz4" | \
        "lzh" | \
        "lzo" | \
        "lzp" | \
        "lzs" | \
        "lzw" | \
        "lzx" | \
        "macbin" | \
        "maff" | \
        "mcp" | \
        "md5" | \
        "mdzip" | \
        "mou" | \
        "mpkg" | \
        "mpq" | \
        "ms_" | \
        "msa" | \
        "mshc" | \
        "msu" | \
        "mtf" | \
        "mva" | \
        "mvdx" | \
        "myo" | \
        "mzz" | \
        "nbh" | \
        "nfp" | \
        "nks" | \
        "nkx" | \
        "nmd" | \
        "nsarc" | \
        "nuget" | \
        "nupkg" | \
        "nw_" | \
        "nxm" | \
        "nz" | \
        "oap" | \
        "obr" | \
        "oiv" | \
        "opg" | \
        "oz" | \
        "pac" | \
        "pack" | \
        "pae" | \
        "paq" | \
        "pax" | \
        "pck" | \
        "pea" | \
        "phar" | \
        "piz" | \
        "pk1" | \
        "pka" | \
        "pkd" | \
        "pkg" | \
        "pkg_" | \
        "pma" | \
        "pn_" | \
        "ppk" | \
        "propdesc" | \
        "psa" | \
        "pug" | \
        "pup" | \
        "puz" | \
        "pwzip" | \
        "pzip" | \
        "qar" | \
        "qcf" | \
        "qif" | \
        "qze" | \
        "rar" | \
        "rar1" | \
        "rar5" | \
        "rarx" | \
        "rbz" | \
        "rev" | \
        "rez" | \
        "rfa" | \
        "rgss2a" | \
        "roo" | \
        "rpa" | \
        "rpm" | \
        "rwp" | \
        "rxx" | \
        "rz" | \
        "rzr" | \
        "s09" | \
        "sar" | \
        "saz" | \
        "sbc" | \
        "sea" | \
        "sfpack" | \
        "sh" | \
        "shar" | \
        "shr" | \
        "sip" | \
        "sisx" | \
        "sit" | \
        "sitx" | \
        "slf" | \
        "snappy" | \
        "snoop" | \
        "solitairetheme8" | \
        "soundpack" | \
        "spk" | \
        "spkg" | \
        "split" | \
        "srep" | \
        "srr" | \
        "sue" | \
        "swm" | \
        "tar" | \
        "tar.gz" | \
        "tar.xz" | \
        "tbz" | \
        "tg" | \
        "tgz" | \
        "tot" | \
        "tsk" | \
        "tx_" | \
        "txz" | \
        "tz" | \
        "u3p" | \
        "uax" | \
        "ufdr" | \
        "uha" | \
        "unitypackage" | \
        "uti" | \
        "utx" | \
        "uue" | \
        "uvz" | \
        "uzip" | \
        "vem" | \
        "vfs" | \
        "vl2" | \
        "vol1.egg" | \
        "vsi" | \
        "vsix" | \
        "vty" | \
        "wad" | \
        "wapt" | \
        "war" | \
        "warc" | \
        "wbpz" | \
        "wdz" | \
        "webarchive" | \
        "wlpk" | \
        "wmz" | \
        "wz" | \
        "xap" | \
        "xdelta" | \
        "xfl" | \
        "xip" | \
        "xsn" | \
        "xx" | \
        "xxl" | \
        "xz" | \
        "xzm" | \
        "y" | \
        "yar" | \
        "ymp" | \
        "yz" | \
        "z" | \
        "z20" | \
        "zab" | \
        "zap" | \
        "zar" | \
        "zds" | \
        "zfc" | \
        "zfs" | \
        "zfsendtotarget" | \
        "zi" | \
        "zim" | \
        "zip2" | \
        "zipx" | \
        "zl" | \
        "zlib" | \
        "zoo" | \
        "zpaq" | \
        "zsplit" | \
        "zx01" | \
        "zxp" | \
        "zz")
            local coloured_file="$_FMAGENTA$bfn$_NOCOLOUR"
            [[ -h "$ffn" ]] && local coloured_file="$_BMAGENTA$_FWHITE$bfn$_NOCOLOUR"
            echo "$coloured_file" && return
            ;;
        "appdata" | \
        "appicon" | \
        "appinfo" | \
        "avhd" | \
        "conf" | \
        "dsk" | \
        "efd" | \
        "fdd" | \
        "hds" | \
        "img" | \
        "kbd" | \
        "mem" | \
        "menudata" | \
        "ova" | \
        "pki" | \
        "psf" | \
        "pvc" | \
        "pvi" | \
        "pvm" | \
        "qcow" | \
        "qcow2" | \
        "qvm" | \
        "std" | \
        "syndarticle" | \
        "tvr" | \
        "vbox" | \
        "vbox-extpack" | \
        "vmac" | \
        "vmba" | \
        "vmcx" | \
        "vmdk-converttmp" | \
        "vmlog" | \
        "vmoapp" | \
        "vmpl" | \
        "vmt" | \
        "vmwarevm" | \
        "vpc6" | \
        "vpc7" | \
        "vswp" | \
        "xml-prev" | \
        "xva" | \
        "xvm" | \
        "zrp" | \
        "appdata" | \
        "appicon" | \
        "appinfo" | \
        "avhd" | \
        "conf" | \
        "dsk" | \
        "efd" | \
        "fdd" | \
        "hds" | \
        "img" | \
        "kbd" | \
        "mem" | \
        "menudata" | \
        "ova" | \
        "pki" | \
        "psf" | \
        "pvc" | \
        "pvi" | \
        "pvm" | \
        "qcow" | \
        "qcow2" | \
        "qvm" | \
        "std" | \
        "syndarticle" | \
        "tvr" | \
        "vbox" | \
        "vbox-extpack" | \
        "vmac" | \
        "vmba" | \
        "vmcx" | \
        "vmdk-converttmp" | \
        "vmlog" | \
        "vmoapp" | \
        "vmpl" | \
        "vmt" | \
        "vmwarevm" | \
        "vpc6" | \
        "vpc7" | \
        "vswp" | \
        "xml-prev" | \
        "xva" | \
        "xvm" | \
        "zrp" )
            local coloured_file="$_FSTEEL$bfn$_NOCOLOUR"
            [[ -h "$ffn" ]] && local coloured_file="$_BSTEEL$_FWHITE$bfn$_NOCOLOUR"
            echo "$coloured_file" && return
            ;;
    esac
    
    echo "$coloured_file"
)
