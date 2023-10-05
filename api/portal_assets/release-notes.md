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

## 3.2.1.0
**Release Date** 2023/02/28

### Deprecations

* Deprecated Alpine Linux images and packages. 
    
    Kong is announcing our intent to remove support for Alpine images and packages later this year. These images and packages are available in 3.2 and will continue to be available in 3.3. We will stop building Alpine images and packages in Kong Gateway 3.4.

### Breaking changes

* The default PostgreSQL SSL version has been bumped to TLS 1.2. In kong.conf:
   
    * The default [pg_ssl_version](/gateway/latest/reference/configuration/#postgres-settings)
    is now tlsv1_2.
    * Constrained the valid values of this configuration option to only accept the following: tlsv1_1, tlsv1_2, tlsv1_3 or any.

    This mirrors the setting ssl_min_protocol_version in PostgreSQL 12.x and onward. 
    See the [PostgreSQL documentation](https://postgresqlco.nf/doc/en/param/ssl_min_protocol_version/)
    for more information about that parameter.

    To use the default setting in kong.conf, verify that your Postgres server supports TLS 1.2 or higher versions, or set the TLS version yourself. 
    TLS versions lower than tlsv1_2 are already deprecated and considered insecure from PostgreSQL 12.x onward.
  
* Added the [allow_debug_header](/gateway/latest/reference/configuration/#allow_debug_header) 
configuration property to kong.conf to constrain the Kong-Debug header for debugging. This option defaults to off.

    If you were previously relying on the Kong-Debug header to provide debugging information, set allow_debug_header: on to continue doing so.

* [**JWT plugin**](/hub/kong-inc/jwt/) (jwt)
    
    * The JWT plugin now denies any request that has different tokens in the JWT token search locations.
      [#9946](https://github.com/Kong/kong/pull/9946)

* Sessions library upgrade [#10199](https://github.com/Kong/kong/pull/10199):
    * The [lua-resty-session](https://github.com/bungle/lua-resty-session) library has been upgraded to v4.0.0. This version includes a full rewrite of the session library, and is not backwards compatible.
      
      This library is used by the following plugins: [**Session**](/hub/kong-inc/session/), [**OpenID Connect**](/hub/kong-inc/openid-connect/), and [**SAML**](/hub/kong-inc/saml/). This also affects any session configuration that uses the Session or OpenID Connect plugin in the background, including sessions for Kong Manager and Dev Portal.

      All existing sessions are invalidated when upgrading to this version.
      For sessions to work as expected in this version, all nodes must run Kong Gateway 3.2.x or later.
      For that reason, we recommend that during upgrades, proxy nodes with mixed versions run for
      as little time as possible. During that time, the invalid sessions could cause failures and partial downtime.
    
   * Parameters:
      * The new parameter idling_timeout, which replaces cookie_lifetime, now has a default value of 900. Unless configured differently, sessions expire after 900 seconds (15 minutes) of idling. 
      * The new parameter absolute_timeout has a default value of 86400. Unless configured differently, sessions expire after 86400 seconds (24 hours).
      * Many session parameters have been renamed or removed. Although your configuration will continue to work as previously configured, we recommend adjusting your configuration to avoid future unexpected behavior. Refer to the [upgrade guide for 3.2](/gateway/latest/upgrade/#session-library-upgrade) for all session configuration changes and guidance on how to convert your existing session configuration.
      
      
### Features

#### Core

* When router_flavor is set totraditional_compatible, Kong Gateway verifies routes created 
  using the expression router instead of the traditional router to ensure created routes
  are compatible.
  [#9987](https://github.com/Kong/kong/pull/9987)
* In DB-less mode, the /config API endpoint can now flatten all schema validation
  errors into a single array using the optional flatten_errors query parameter.
  [#10161](https://github.com/Kong/kong/pull/10161)
* The upstream entity now has a new load balancing algorithm option: [latency](/gateway/latest/how-kong-works/load-balancing/#balancing-algorithms).
  This algorithm chooses a target based on the response latency of each target
  from prior requests.
  [#9787](https://github.com/Kong/kong/pull/9787)
* The Nginx charset directive can now be configured with Nginx directive injections.
    Set it in Kong Gateway's configuration with [nginx_http_charset](/gateway/latest/reference/configuration/#nginx_http_charset)
    [#10111](https://github.com/Kong/kong/pull/10111)
* The services upstream TLS configuration is now extended to the stream subsystem.
  [#9947](https://github.com/Kong/kong/pull/9947)
* Added the new configuration parameter [ssl_session_cache_size](/gateway/latest/reference/configuration/#ssl_session_cache_size), 
which lets you set the Nginx directive ssl_session_cache.
  This configuration parameter defaults to 10m.
  Thanks [Michael Kotten](https://github.com/michbeck100) for contributing this change.
  [#10021](https://github.com/Kong/kong/pull/10021)
* [status_listen](/gateway/latest/reference/configuration/#status_listen) now supports HTTP2. [#9919](https://github.com/Kong/kong/pull/9919)
* The shared Redis connector now supports username + password authentication for cluster connections, improving on the existing single-node connection support. This automatically applies to all plugins using the shared Redis configuration. [#4333](https://github.com/Kong/kong-ee/pull/4333)


#### Enterprise

* **FIPS Support**:
  * The OpenID Connect, Key Authentication - Encrypted, and JWT Signer plugins are now [FIPS 140-2 compliant](/gateway/latest/kong-enterprise/fips-support/). 

    If you are migrating from {{site.base_gateway}} 3.1 to 3.2 in FIPS mode and are using the key-auth-enc plugin, you should send [PATCH or POST requests](/hub/kong-inc/key-auth-enc/#create-a-key) to all existing key-auth-enc credentials to re-hash them in SHA256.
  * FIPS-compliant Kong Gateway packages now support PostgreSQL SSL connections. 

##### Kong Manager

* Improved the editor for expression fields. Any fields using the expression router now have syntax highlighting, autocomplete, and route validation.
* Improved audit logs by adding rbac_user_name and request_source. 
By combining the data in the new request_source field with the path field, you can now determine login and logout events from the logs. 
See the documentation for more detail on [interpreting audit logs](/gateway/latest/kong-enterprise/audit-log/#kong-manager-authentication).
* License information can now be copied or downloaded into a file from Kong Manager. 
* Kong Manager now supports the POST method for OIDC-based authentication.
* Keys and key sets can now be configured in Kong Manager.
* Optimized the color scheme for http method badges.

#### Plugins

* **Plugin entity**: Added an optional instance_name field, which identifies a
  particular plugin entity.
  [#10077](https://github.com/Kong/kong/pull/10077)

* [**Zipkin**](/hub/kong-inc/zipkin/) (zipkin)
  * Added support for setting the durations of Kong phases as span tags
  through the configuration property phase_duration_flavor.
  [#9891](https://github.com/Kong/kong/pull/9891)

* [**HTTP Log**](/hub/kong-inc/http-log/) (http-log)
  * The headers configuration parameter is now referenceable, which means it can be securely stored in a vault.
  [#9948](https://github.com/Kong/kong/pull/9948)

* [**AWS Lambda**](/hub/kong-inc/aws-lambda/) (aws-lambda)
  * Added the configuration parameter aws_imds_protocol_version, which
  lets you select the IMDS protocol version.
  This option defaults to v1 and can be set to v2 to enable IMDSv2.
  [#9962](https://github.com/Kong/kong/pull/9962)

* [**OpenTelemetry**](/hub/kong-inc/opentelemetry/) (opentelemetry)
  * This plugin can now be scoped to individual services, routes, and consumers.
  [#10096](https://github.com/Kong/kong/pull/10096)

* [**StatsD**](/hub/kong-inc/statsd/) (statsd)
  * Added the tag_style configuration parameter, which allows the plugin 
  to send metrics with [tags](https://github.com/prometheus/statsd_exporter#tagging-extensions).
  The parameter defaults to nil, which means that no tags are added to the metrics.
  [#10118](https://github.com/Kong/kong/pull/10118)
  
* [**Session**](/hub/kong-inc/session/) (session), [**OpenID Connect**](/hub/kong-inc/openid-connect/) (openid-connect), and [**SAML**](/hub/kong-inc/saml/) (saml)

  * These plugins now use lua-resty-session v4.0.0. 

    This update includes new session functionalities such as configuring audiences to manage multiple 
    sessions in a single cookie, global timeout, and persistent cookies.
  
    Due to this update, there are also a number of deprecated and removed parameters in these plugins. 
    See the invidividual plugin documentation for the full list of changed parameters in each plugin.
    * [Session changelog](/hub/kong-inc/session/#changelog)
    * [OpenID Connect changelog](/hub/kong-inc/openid-connect/#changelog)
    * [SAML changelog](/hub/kong-inc/saml/#changelog)

* [**GraphQL Rate Limiting Advanced**](/hub/kong-inc/graphql-rate-limiting-advanced/) (graphql-rate-limiting-advanced) and [**Rate Limiting Advanced**](/hub/kong-inc/rate-limiting-advanced/) (rate-limiting-advanced)
    * In hybrid and DB-less modes, these plugins now support sync_rate = -1 with any strategy, including the default cluster strategy.

* [**OPA**](/hub/kong-inc/opa/) (opa)
    * This plugin can now handle custom messages from the OPA server.

* [**Canary**](/hub/kong-inc/canary/) (canary)
    * Added a default value for the start field in the canary plugin. 
    If not set, the start time defaults to the current timestamp.
    
* **Improved Plugin Documentation**
    * Split the plugin compatibility table into a [technical compatibility page](/hub/plugins/compatibility/) and a [license tiers](hub/plugins/license-tiers) page. 
    * Updated the plugin compatibility information for more clarity on [supported network protocols](/hub/plugins/compatibility/#protocols) and on [entity scopes](/hub/plugins/compatibility/#scopes). 
    * Revised docs for the following plugins to include examples:
      * [CORS](/hub/kong-inc/cors/)
      * [File Log](/hub/kong-inc/file-log/)
      * [HTTP Log](/hub/kong-inc/http-log/)
      * [JWT Signer](/hub/kong-inc/jwt-signer/)
      * [Key Auth](/hub/kong-inc/key-auth/)
      * [OpenID Connect](/hub/kong-inc/openid-connect/)
      * [Rate Limiting Advanced](/hub/kong-inc/rate-limiting-advanced/)
      * [SAML](/hub/kong-inc/saml/)
      * [StatsD](/hub/kong-inc/statsd/)
  

### Fixes

#### Core 

* Added back PostgreSQL FLOOR function when calculating ttl, so ttl is always returned as a whole integer.
  [#9960](https://github.com/Kong/kong/pull/9960)
* Exposed PostreSQL connection pool configuration.
  [#9603](https://github.com/Kong/kong/pull/9603)
* **Nginx template**: The default charset is no longer added to the Content-Type response header when the upstream response doesn't contain it.
  [#9905](https://github.com/Kong/kong/pull/9905)
* Fixed an issue where, after a valid declarative configuration was loaded,
  the configuration hash was incorrectly set to the value 00000000000000000000000000000000.
  [#9911](https://github.com/Kong/kong/pull/9911)
* Updated the batch queues module so that queues no longer grow without bounds if
  their consumers fail to process the entries. Instead, old batches are now dropped
  and an error is logged.
  [#10247](https://github.com/Kong/kong/pull/10247)
* Fixed an issue where X-Kong-Upstream-Status couldn't be emitted when a response was buffered.
  [#10056](https://github.com/Kong/kong/pull/10056)
* Improved the error message for invalid JWK entries.
  [#9904](https://github.com/Kong/kong/pull/9904)
* Fixed an issue where the # character wasn't parsed correctly from environment variables and vault references.
  [10132](https://github.com/Kong/kong/pull/10132)
* Fixed an issue where control plane didn't downgrade configuration for the AWS Lambda and Zipkin plugins for older versions of data planes.
  [#10346](https://github.com/Kong/kong/pull/10346)
* Fixed an issue in DB-less mode, where validation of regex routes could be skipped when using a configuration format older than 3.0.
  [#10348](https://github.com/Kong/kong/pull/10348)

#### Enterprise

* Fixed an issue where the forward proxy between the data plane and the control plane didn't support telemetry port 8006.
* Fix the PostgreSQL mTLS error bad client cert type. 
* Fixed issues with the Admin API's /licenses endpoint:
    * The Enterprise license wasn't being picked up by other nodes in a cluster.
    * Vitals routes weren't accessible.
    * Vitals wasn't showing up in hybrid mode.
* Fixed RBAC issues:
  * Fixed an issue where workspace admins couldn't add rate limiting policies to consumer groups.
  * Fixed an issue where workspace admins in one workspace would have admin rights in other workspaces. 
    Workspace admins are now correctly restricted to their own workspaces.
  * Fixed a role precedence issue with RBAC. RBAC rules involving deny (negative) rules now correctly take precedence over allow (non-negative) roles.

##### Vitals

* Fixed an issue where Vitals wasn't tracking the status codes of service-less routes.
* Fixed the Admin API error /vitals/reports/:entity_type is not available.

##### Kong Manager

* Fixed an issue where 404 Not Found errors were triggered while updating the service, route, or consumer bound to a scoped plugin.
* Moved the tags field out of the advanced fields section for certificate, route, and upstream configuration pages. 
The tags field is now visible without needing to expand to see all fields.
* Improved the user interface for Keys and Key Sets entities. 
* You can now add tags for consumer groups in Kong Manager.
* Fixed an issue where the plugin **Copy JSON** button didn't copy the full configuration.
* Fixed an issue where the password reset form didn't check for matching passwords and allowed mismatched passwords to be submitted.
* Added a link to the upgrade prompt for Konnect or Enterprise. 
* Fixed an issue where any IdP user could log into Kong Manager, regardless of their role or group membership. 
These users could see the Workspaces Overview dashboard with the default workspace, but they couldn't do anything else.
Now, if IdP users with no groups or roles attempt to log into Kong Manager, they will be denied access.

#### Plugins

* [**Zipkin**](/hub/kong-inc/zipkin/) (zipkin)
  * Fixed an issue where the global plugin's sample ratio overrode the route-specific ratio.
  [#9877](https://github.com/Kong/kong/pull/9877)
  * Fixed an issue where trace-id and parent-id strings with decimals were not processed correctly.

* [**JWT**](/hub/kong-inc/jwt/) (jwt)
  * This plugin now denies requests that have different tokens in the JWT token search locations. 
  
    Thanks Jackson 'Che-Chun' Kuo from Latacora for reporting this issue.
    [#9946](https://github.com/Kong/kong/pull/9946)

* [**Datadog**](/hub/kong-inc/datadog/) (datadog),[**OpenTelemetry**](/hub/kong-inc/opentelemetry/) (opentelemetry), and [**StatsD**](/hub/kong-inc/statsd/) (statsd)
  * Fixed an issue in these plugins' batch queue processing, where metrics would be published multiple times. 
  This caused a memory leak, where memory usage would grow without limit.
  [#10052](https://github.com/Kong/kong/pull/10052) [#10044](https://github.com/Kong/kong/pull/10044)

* [**OpenTelemetry**](/hub/kong-inc/opentelemetry/) (opentelemetry)
  *  Fixed non-compliances to specification:
     * For http.uri in spans, the field is now the full HTTP URI.
      [#10036](https://github.com/Kong/kong/pull/10036)
     * http.status_code is now present on spans for requests that have a status code.
      [#10160](https://github.com/Kong/kong/pull/10160)
     * http.flavor is now a string value, not a double.
      [#10160](https://github.com/Kong/kong/pull/10160)
  * Fixed an issue with getting the traces of other formats, where the trace ID reported and propagated could be of incorrect length.
    This caused traces originating from Kong Gateway to incorrectly connect with the target service, causing Kong Gateway and the target service to submit separate traces.
    [#10332](https://github.com/Kong/kong/pull/10332)
  
* [**OAuth2**](/hub/kong-inc/oauth2/) (oauth2)
  * refresh_token_ttl is now limited to a range between 0 and 100000000 by the schema validator. 
  Previously, numbers that were too large caused requests to fail.
  [#10068](https://github.com/Kong/kong/pull/10068)

* [**OpenID Connect**](/hub/kong-inc/openid-connect/) (openid-connect)
  * Fixed an issue where it was not possible to specify an anonymous consumer by name.
  * Fixed an issue where the authorization_cookie_httponly and session_cookie_httponly parameters would always be set to true, even if they were configured as false.

* [**Rate Limiting Advanced**](/hub/kong-inc/rate-limiting-advanced/) (rate-limiting-advanced)
  * Matched the plugin's behavior to the Rate Limiting plugin.
    When an HTTP 429 status code was returned, rate limiting related headers were missed from the PDK module kong.response.exit(). 
    This made the plugin incompatible with other Kong components like the Exit Transformer plugin.

* [**Response Transformer**](/hub/kong-inc/response-transformer/) (response-transformer)
  * Fixed an issue where the allow.json configuration parameter couldn't use nested JSON object and array syntax.

* [**Mocking**](/hub/kong-inc/mocking/) (mocking)
  * Fixed UUID pattern matching. 

* [**SAML**](/hub/kong-inc/saml/) (saml)
  * Fixed an issue where the session_cookie_httponly parameter would always be set to true, even if it was configured as false.

* [**Key Authentication Encrypted**](/hub/kong-inc/key-auth-enc/) (key-auth-enc)
  * Fixed the ttl parameter. You can now set ttl for an encrypted key.
  * Fixed an issue where this plugin didn't accept tags.

### Dependencies

* Bumpedlua-resty-openssl from 0.8.15 to 0.8.17
* Bumped libexpat from 2.4.9 to 2.5.0
* Bumoed kong-openid-connect from v2.5.0 to v2.5.2
* Bumped openssl from 1.1.1q to 1.1.1t
* libyaml is no longer built with Kong Gateway. System libyaml is used instead.
* Bumped luarocks from 3.9.1 to 3.9.2
  [#9942](https://github.com/Kong/kong/pull/9942)
* Bumped atc-router from 1.0.1 to 1.0.5
  [#9925](https://github.com/Kong/kong/pull/9925)
  [#10143](https://github.com/Kong/kong/pull/10143)
  [#10208](https://github.com/Kong/kong/pull/10208)
* Bumped lua-resty-openssl from 0.8.15 to 0.8.17
  [#9583](https://github.com/Kong/kong/pull/9583)
  [#10144](https://github.com/Kong/kong/pull/10144)
* Bumped lua-kong-nginx-module from 0.5.0 to 0.5.1
  [#10181](https://github.com/Kong/kong/pull/10181)
* Bumped lua-resty-session from 3.10 to 4.0.0
  [#10199](https://github.com/Kong/kong/pull/10199)
  [#10230](https://github.com/Kong/kong/pull/10230)
* Bumped libxml from 2.10.2 to 2.10.3 to resolve [CVE-2022-40303](https://nvd.nist.gov/vuln/detail/cve-2022-40303) and [CVE-2022-40304](https://nvd.nist.gov/vuln/detail/cve-2022-40304)
