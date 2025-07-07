# Stage - 2
## Harvester
On uninstall of tailscale-operator, it leaves ConfigMaps behind. Delete them, if you will re-deploy, otherwise operator won't start