# Release notes for version 0.9.10

**Release date:** 2023-10-12

![AppVersion: v1.94.0](https://img.shields.io/static/v1?label=AppVersion&message=v1.94.0&color=success&logo=)
![Helm: v3](https://img.shields.io/static/v1?label=Helm&message=v3&color=informational&logo=helm)

- Add license enforcement for vmbackupmanager in order to avoid running it without enterprise license key. See [these docs](https://docs.victoriametrics.com/enterprise.html) for details.
- Fix license flags not being passed to vmsingle when using StatefulSet.

