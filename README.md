# dotfiles
My personal dotfiles. Probably xplatform.

### Paths

```
FIREFOX:
    about:config 
        ---general---
        browser.sessionstore.restore_pinned_tabs_on_demand = true
        browser.tabs.insertRelatedAfterCurrent = false 
        network.prefetch-next = false 
        browser.zoom.siteSpecific = false 
        browser.urlbar.maxRichResults = 20 (FOR 1080p) 
        browser.ctrltabs.previews = false 
        dom.ipc.processCount = 12 (SET SAME NUMBER OF CORES) 
        browser.sessionhistory.max_entries = 25 
        browser.sessionstore.interval = 60000 
        browser.cache.offline.capacity = 4096000
        dom.security.https_only_mode = true
        --- privacy ---
        geo.enabled = false
        dom.battery.enabled = false
        extensions.pocket.enabled = false
        beacon.enabled = false
        browser.urlbar.speculativeConnect.enabled = false
        privacy.trackingprotection.enabled = true
        
        
    userChrome.css
        toolkit.legacyUserProfileCustomizations.stylesheets = true
        /home/<user>/.mozilla/firefox/<profile>/chrome/userChrome.css
```
