// enable stylesheets for mono ff
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("gnomeTheme.hideSingleTab", true);

// GENERIC
user_pref("browser.bookmarks.restore_default_bookmarks", false);
user_pref("browser.tabs.insertRelatedAfterCurrent", false);
user_pref("network.prefetch-next", false);
user_pref("browser.zoom.siteSpecific", false);
user_pref("browser.urlbar.maxRichResults", 25);
user_pref("browser.ctrltabs.previews", false);
user_pref("browser.sessionhistory.max_entries", 25);
user_pref("browser.sessionstore.interval", 60000);
user_pref("browser.cache.offline.capacity", 4096000);
user_pref("dom.security.https_only_mode", true);
// FF 106+ Disable firefox-view
user_pref("browser.tabs.firefox-view", false);
user_pref("browser.tabs.firefox-view", false);
user_pref("browser.firefox-view.view-count", 0);

// Disable uitour
user_pref("browser.uitour.enabled", false);

// Disable CTRL+Q
user_pref("browser.quitShortcut.disabled", true);

// PRIVACY
user_pref("geo.enabled", false); // might cause issue with specific sites; disable this if you get location issues
user_pref("dom.battery.enabled", false)
user_pref("browser.pocket.enabled", false);
user_pref("extensions.pocket.enabled", false);
user_pref("beacon.enabled", false);
user_pref("browser.urlbar.speculativeConnect.enabled", false);
user_pref("privacy.trackingprotection.enabled", true);

// everything below this line is found here:
// https://github.com/pyllyukko/user.js/blob/relaxed/user.js
user_pref("geo.wifi.logging.enabled", false);
user_pref("dom.mozTCPSocket.enabled", false);
ser_pref("dom.netinfo.enabled", false);
user_pref("dom.telephony.enabled", false);
user_pref("media.webspeech.synth.enabled", false);
user_pref("browser.send_pings.require_same_host", true);
user_pref("dom.vr.enabled", false);
user_pref("webgl.min_capability_mode", true);
user_pref("webgl.disable-extensions", true);
user_pref("webgl.enable-debug-renderer-info", false);
user_pref("dom.maxHardwareConcurrency", 4);
user_pref("camera.control.face_detection.enabled", false);
user_pref("intl.accept_languages", "en-US, en");
user_pref("intl.locale.matchOS", false);
user_pref("javascript.use_us_english_locale", true);
user_pref("network.manage-offline-status", false);
user_pref("general.buildID.override", "20100101");
user_pref("browser.startup.homepage_override.buildID", "20100101");

user_pref("security.dialog_enable_delay", 1000);

user_pref("browser.newtabpage.activity-stream.asrouter.userprefs.cfr", false);
user_pref("devtools.webide.enabled", false);
user_pref("devtools.webide.autoinstallADBHelper", false);
user_pref("devtools.webide.autoinstallFxdtAdapters", false);
user_pref("devtools.debugger.remote-enabled", false);
user_pref("devtools.chrome.enabled", false);
user_pref("devtools.debugger.force-local", true);
user_pref("toolkit.telemetry.enabled", false);
user_pref("toolkit.telemetry.unified", false);
user_pref("toolkit.telemetry.archive.enabled", false);
user_pref("experiments.supported", false);
user_pref("experiments.enabled", false);
user_pref("experiments.manifest.uri", "");
user_pref("network.allow-experiments", false);
user_pref("breakpad.reportURL",  ""); // A list of submitted crash reports can be found at about:crashes
user_pref("browser.tabs.crashReporting.sendReport", false);
user_pref("browser.crashReports.unsubmittedCheck.enabled", false);
user_pref("browser.safebrowsing.enabled", true); // Firefox < 50
user_pref("browser.safebrowsing.phishing.enabled", true); // firefox >= 50
user_pref("browser.safebrowsing.malware.enabled", true);

user_pref("browser.cache.disk_cache_ssl", false);
user_pref("signon.autofillForms.http", false);
user_pref("browser.pagethumbnails.capturing_disabled", true);
user_pref("browser.helperApps.deleteTempFileOnExit", true);

user_pref("security.insecure_password.ui.enabled", true);
user_pref("browser.newtabpage.enabled", false);
user_pref("browser.newtab.url",  "about:blank");
user_pref("browser.newtabpage.enhanced", false);
user_pref("browser.newtab.preload", false);
user_pref("browser.newtabpage.directory.ping", "");
user_pref("browser.newtabpage.directory.source", "data:text/plain,{}");
user_pref("browser.shell.checkDefaultBrowser", false);

user_pref("network.stricttransportsecurity.preloadlist", true);
user_pref("security.tls.version.min", 1);
user_pref("security.tls.version.max", 4);
user_pref("security.pki.sha1_enforcement_level", 1);

user_pref("security.ssl3.ecdh_ecdsa_rc4_128_sha", false);
user_pref("security.ssl3.ecdh_rsa_rc4_128_sha", false);
user_pref("security.ssl3.ecdhe_ecdsa_rc4_128_sha", false);
user_pref("security.ssl3.ecdhe_rsa_rc4_128_sha", false);
user_pref("security.ssl3.rsa_rc4_128_md5", false);
user_pref("security.ssl3.rsa_rc4_128_sha", false);
user_pref("security.tls.unrestricted_rc4_fallback", false);

user_pref("security.ssl3.dhe_dss_des_ede3_sha", false);
user_pref("security.ssl3.dhe_rsa_des_ede3_sha", false);
user_pref("security.ssl3.ecdh_ecdsa_des_ede3_sha", false);
user_pref("security.ssl3.ecdh_rsa_des_ede3_sha", false);
user_pref("security.ssl3.ecdhe_ecdsa_des_ede3_sha", false);
user_pref("security.ssl3.ecdhe_rsa_des_ede3_sha", false);
user_pref("security.ssl3.rsa_des_ede3_sha", false);
user_pref("security.ssl3.rsa_fips_des_ede3_sha", false);

user_pref("security.ssl3.ecdhe_ecdsa_chacha20_poly1305_sha256", true);
user_pref("security.ssl3.ecdhe_rsa_chacha20_poly1305_sha256", true);

user_pref("security.ssl3.dhe_rsa_camellia_256_sha", false);
user_pref("security.ssl3.dhe_rsa_aes_256_sha", false);
