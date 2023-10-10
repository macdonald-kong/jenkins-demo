## 3.2.2.1
**Release Date** 2023/04/03

### Fixes
* Fixed the Dynatrace implementation. Due to a build system issue, Kong Gateway 3.2.x packages prior to 3.2.2.1 didn't contain the debug symbols that Dynatrace requires.

### Deprecations
* **Alpine deprecation reminder:** Kong has announced our intent to remove support for Alpine images and packages later this year. These images and packages are available in 3.2 and will continue to be available in 3.3. We will stop building Alpine images and packages in Kong Gateway 3.4.


## 3.2.2.0
**Release Date** 2023/03/22

### Fixes 
#### Enterprise
* In Kong 3.2.1.0 and 3.2.1.1, alpine and ubuntu ARM64 artifacts incorrecty handled HTTP2 requests, causing the protocol to fail. These artifacts have been removed. 
* Added the default logrotate file /etc/logrotate.d/kong-enterprise-edition. This file was missing in all 3.x versions of Kong Gateway prior to this release.

#### Plugins
* [**SAML**](/hub/kong-inc/saml/) (saml)
    * The SAML plugin now works on read-only file systems.
    * The SAML plugin can now handle the field session_auth_ttl (removed since 3.2.0.0).

* Datadog Tracing plugin: We found some late-breaking issues with the Datadog Tracing plugin and elected to remove it from the 3.2 release. We plan to add the plugin back with the issues fixed in a later release. 

### Known issues
* Due to changes in GPG keys, using yum to install this release triggers a Public key for kong-enterprise-edition-3.2.1.0.rhel7.amd64.rpm is not installed error. The package *is* signed, however, it's signed with a different (rotated) key from the metadata service, which triggers the error in yum. To avoid this error, manually download the package from [download.konghq.com](https://download.konghq.com/) and install it. 
