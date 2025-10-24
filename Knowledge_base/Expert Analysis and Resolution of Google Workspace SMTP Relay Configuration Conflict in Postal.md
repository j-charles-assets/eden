# Expert Analysis and Resolution of Google Workspace SMTP Relay Configuration Conflict in Postal

## I. Executive Summary and Definitive Resolution Confirmation

The configuration challenge involves integrating the Postal Mail Transfer Agent (MTA) with the Google Workspace SMTP Relay Service (`smtp-relay.gmail.com`). The persistent delivery failure, identified by the error code `550-5.7.1 Invalid credentials for relay... doesn't match the domain of the account this email is being sent from`, was a consequence of a security policy violation, specifically concerning the identity presented during the initial SMTP handshake. This policy failure occurred despite the successful configuration of IP whitelisting and valid SMTP authentication credentials.

### 1.1 Resolution Status: Validation of EHLO Hostname Correction (Step 5)

The analysis confirms that the user’s systematic troubleshooting correctly isolated the root cause to a misalignment between the hostname presented by the Postal server during the EHLO (Extended HELO) command and the verified primary domain within Google Workspace.

The final action taken in Step 5—modifying the Postal configuration file (`postal.yml`) to set `smtp_hostname: jcharlesassets.com`—is the definitive resolution. This change ensures that the sending MTA explicitly identifies itself to Google's receiving server using the root domain associated with the Google Workspace account. This action satisfies Google's explicit requirement that when using the SMTP relay, the sending mail server must "present one of your domain names in the HELO or EHLO command". By aligning the EHLO identifier with the primary registered Google Workspace domain, the tripartite validation requirements (IP source, authenticated user domain, and MTA identity) are met, thereby eliminating the  

`550-5.7.1` error related to the domain mismatch.

### 1.2 Definitive Best-Practice Configuration for Postal/Google Integration

The optimal configuration for highly available and reliable relaying via `smtp-relay.gmail.com` requires synchronization across three layers:

1. **Network Layer:** Whitelisting both IPv4 and IPv6 public addresses of the Postal server to prevent connection rejection due to modern network stack prioritization.
    
2. **MTA Identity Layer:** Configuring the Postal `smtp_hostname` parameter to explicitly present the primary Google Workspace domain (`jcharlesassets.com`) during the EHLO command.
    
3. **Authentication Layer:** Utilizing a valid Google Workspace App Password (since 2FA is generally required) via the Postal `smtp_relays` configuration URI.
    

This specific setup, leveraging the dedicated high-volume SMTP Relay Service, is critical for high-volume MTAs like Postal to maintain reliable delivery within Google's complex security framework.  

## II. Deconstructing the 550-5.7.1 "Invalid Credentials for Relay" Error

The `550-5.7.1` error, typically classified as a permanent security or policy rejection, served as a misleading diagnostic signal in this specific scenario. Understanding the context of the SMTP protocol validation is necessary to decode the true failure mechanism.

### 2.1 Protocol Context: The Role of EHLO/HELO in SMTP Authentication

The EHLO command initiates communication between a sending mail server and a receiving mail server. When Postal connects to  

`smtp-relay.gmail.com`, it first sends the EHLO command, declaring its Fully Qualified Domain Name (FQDN). This FQDN acts as the originating server’s identity.

Google’s mail infrastructure maintains strict security controls, particularly for the SMTP Relay Service, which is often used by third-party applications or infrastructure to bypass standard spam filtering. Google explicitly mandates that if the sender is not associated with one of the domains listed in the Workspace account, the system may modify the envelope sender, or the sending server must "present one of your domain names in the HELO or EHLO command".  

The failure experienced in Step 4 arose because Postal, in its default state or with the prior `smtp_hostname: mail.jcharlesassets.com`, presented an identity that Google’s policy engine determined was either generic, incomplete, or insufficiently authoritative to match the primary Workspace domain, even though the sending domain (`newsletter.jcharlesassets.com`) was a verified subdomain. This behavior has been observed in other third-party clients where the EHLO identity, if generic (such as an IP address representation or a non-primary FQDN), is rejected by `smtp-relay.gmail.com`.  

A crucial observation in this diagnostic path is the semantic misdirection inherent in the Google error message. The message states, "Invalid credentials for relay" and continues, "The IP address you've registered... doesn't match the domain of the account this email is being sent from". The administrator had provided valid credentials (the App Password) and had successfully whitelisted the source IP addresses. The failure was not a conventional authentication failure (wrong username/password) but rather a policy-based rejection where the identity presented by the MTA (via EHLO) did not reconcile with the authenticated user’s domain and the whitelisted source IP. Therefore, whenever administrators encounter this specific wording under a  

`550-5.7.1` classification, the primary technical focus must shift from checking the password or the IP list to verifying the EHLO/HELO hostname presented by the sending MTA. This security measure is used by Google to broadly categorize issues ranging from general spam rejection to specific protocol violations that compromise sender trustworthiness.  

### 2.2 Google Workspace Policy Interpretation: The Tripartite Validation Constraint

The user configured the Google Workspace SMTP Relay service with two concurrent requirements:

1. **IP Whitelisting:** Acceptance only from specified IP addresses (`178.156.206.220` and `2a01:4ff:f0:3c5c::1`).
    
2. **SMTP Authentication:** Enforcement of user authentication (using `jamesrogers@jcharlesassets.com` credentials).
    
3. **Allowed Senders:** Set to "Any addresses (not recommended)."
    

This combined setup creates a highly complex, hybrid authentication constraint. While IP whitelisting alone can suffice under certain configurations (Option 3, `aspmx.l.google.com`, or Option 1 with SMTP AUTH unchecked), forcing both IP trust and SMTP credentials requires Google’s system to validate all incoming identity signals simultaneously.  

The constraint dictates that the system must confirm three identity components align with the Google Workspace ownership: the source IP address, the domain of the authenticated user, and the FQDN provided in the EHLO command. In Step 4, the system successfully verified the IP and the SMTP credentials. However, because the EHLO hostname was either generic or misaligned, the system reported an identity inconsistency, resulting in the failure.  

The administrator's choice to employ this hybrid model results in the imposition of maximum security checks. If the objective is pure application relaying of messages originating from many different aliases or domains, a simplified configuration utilizing _IP Whitelisting only_ (with SMTP Authentication unchecked) is often preferred, provided that the `smtp_hostname` is correctly set to the registered domain name. However, since the user chose to retain SMTP AUTH, fixing the EHLO hostname was the only path to synchronize all three identity vectors and satisfy the stringent policy enforcement.  

## III. Architectural Analysis of Google Workspace SMTP Relay Options

The successful configuration hinges on the proper architectural selection of Google’s outbound mail services. The user correctly identified and utilized the dedicated SMTP Relay Service (Option 1).

### 3.1 Option 1: The SMTP Relay Service (`smtp-relay.gmail.com`)

The SMTP Relay Service is specifically designed for high-volume, organizational traffic originating from servers, applications, and network devices, such as the Postal MTA. This service supports higher daily sending limits, potentially up to 10,000 recipients per user per day, making it suitable for bulk and transactional email platforms.  

#### Configuration Settings Review:

- **Allowed Senders ("Any addresses"):** The selection of "Any addresses" is necessary for the Postal server, as it is relaying mail from different verified sender domains (e.g., `test@newsletter.jcharlesassets.com`). However, this setting requires increased identity assurance, which is why Google imposes the strict EHLO hostname validation.  
    
- **Authentication and Encryption:** The use of Port 587 with STARTTLS encryption is the standard and recommended practice for modern mail relaying over `smtp-relay.gmail.com`. The authentication utilizes an App Password, a critical requirement for non-OAuth clients accessing Workspace SMTP AUTH when Two-Factor Authentication is enabled on the service account.  
    

### 3.2 Architectural Distinction from Alternative Services

It is important to differentiate the chosen relay method from Google’s other outbound options to reinforce the architectural decision:

- **Option 2: The Gmail SMTP Server (`smtp.gmail.com`):** This service is designed for individual user access (e.g., desktop mail clients) and enforces strict per-user quotas, typically limited to 500 messages per day. It relies exclusively on SMTP AUTH. This architecture is unsuitable for a high-volume MTA like Postal.  
    
- **Option 3: Restricted SMTP Server (`aspmx.l.google.com`):** This service does not require TLS or authentication and relies solely on IP whitelisting. However, it only permits sending to recipients within Gmail or Google Workspace domains, limiting its utility for general transactional emailing.  
    

The user’s selection of the SMTP Relay Service (Option 1) correctly identifies the needed architectural path for a dedicated MTA. The challenge, therefore, was purely a configuration conflict within this chosen framework.

Table 2 provides a comparative overview of Google's outbound SMTP options.

Table 2: Google Workspace SMTP Relay Configuration Matrix

|**Google Option**|**Server Address**|**Primary Authentication**|**Daily Limit Policy**|**EHLO/HELO Criticality**|
|---|---|---|---|---|
|SMTP Relay Service (Option 1)|`smtp-relay.gmail.com`|IP Whitelist OR SMTP AUTH (Hybrid possible)|High (up to 10,000 recipients/day per user)|Critical for domain alignment, especially in hybrid or "Any addresses" mode|
|Gmail SMTP Server (Option 2)|`smtp.gmail.com`|SMTP AUTH (App Password required)|Low (500 messages/day per user)|Lower, as AUTH establishes user identity and domain|
|Restricted SMTP Server (Option 3)|`aspmx.l.google.com`|None (IP Whitelist only)|Google Workspace per-user limits apply|Low; restricted to internal Google/Workspace recipients|

 

## IV. Detailed Troubleshooting Chronology and Technical Rationale

The user’s diagnostic journey provides a comprehensive record of sequential failure analysis, culminating in the correct identification of the EHLO issue.

### 4.1 Review of Steps 1 and 2: Postal Configuration Syntax and Network Addressing

**Step 1 Failure: Syntax Error Analysis** The initial attempt failed due to an error in the structure of the `smtp_relays` configuration within `postal.yml`. Postal expects this parameter to be defined using a URI format, whereas the user provided a YAML hash/dictionary format (with separate `hostname`, `port`, `user`, and `password` fields), resulting in the error message `bad URI(is not URI?): "{...}"`. This confirms the necessity of strictly adhering to Postal’s documented URI configuration standard for external relays.

**Steps 2 and 3 Failure: IPv6/IPv4 Conflict and Resolution** After correcting the Postal configuration to the URI format: `smtp://jamesrogers%40jcharlesassets.com:ikzdtgydgisrmofq@smtp-relay.gmail.com:587`, the connection immediately failed with `Invalid credentials for relay [2a01:4ff:f0:3c5c::1]`.

The critical issue here was network addressing. The Postal server, residing on IP addresses `178.156.206.220` (IPv4) and `2a01:4ff:f0:3c5c::1` (IPv6), prioritized connecting to Google over IPv6. Since only the IPv4 address was initially registered in the Google Workspace whitelist, Google’s policy engine correctly rejected the connection attempt originating from the unauthorized IPv6 address. In modern, dual-stack network environments, MTAs frequently default to IPv6. Administrators must ensure that all potential source IPs, both IPv4 and IPv6, are exhaustively whitelisted to guarantee reliable connectivity. The user correctly resolved this by adding the IPv6 address to the Google Workspace whitelist in Step 3.  

### 4.2 Root Cause Analysis of Step 4 Failure: Domain and Identity Mismatch

With the IP whitelisting issue resolved (Steps 2 and 3), the underlying identity issue became the single point of failure: `550-5.7.1... doesn't match the domain of the account this email is being sent from`.

This error signaled a complex failure to reconcile sender identities. Postal was attempting to send mail with a `MAIL FROM` address of `test@newsletter.jcharlesassets.com` while authenticating using the credentials of the user `jamesrogers@jcharlesassets.com`. Google's policy, when "Any addresses" is selected, allows this difference in envelope sender domains but enforces strict confirmation that the identity of the sending mechanism is tied to the main Workspace domain (`jcharlesassets.com`).

The fundamental policy violation was ultimately rooted in the EHLO command. In Step 4, even after verifying the subdomain and ensuring DNS records were correct (SPF, DKIM, Return Path), the failure persisted. This strongly suggested that Postal was presenting an ambiguous or unauthorized EHLO hostname (which the user noted was previously `mail.jcharlesassets.com`). When Google performs its security check, particularly in the presence of whitelisted IPs and SMTP authentication, it requires the EHLO identity to match a high-trust domain. The use of a subdomain FQDN, or a generic identifier, failed to satisfy the EHLO verification layer, preventing mail transmission.  

### 4.3 The Resolution Endpoint: Defining `postal.smtp_hostname` (Step 5)

The correction applied in Step 5—setting `smtp_hostname: jcharlesassets.com` in `postal.yml`—directly addresses the protocol identity requirement. This configuration forces Postal to present `EHLO jcharlesassets.com` to the Google relay server.

This action satisfies Google’s specific documentation mandate to present a domain name in the HELO or EHLO command when attempting to relay mail from an organizationally owned domain. By explicitly setting the EHLO value to the primary, verified domain name of the Workspace account, the Postal MTA successfully reconciles the three required security elements: the whitelisted IP, the authenticated user's domain, and the MTA's declared identity.  

Table 1 provides a consolidated analysis of the systematic troubleshooting efforts.

Table 1: Troubleshooting Path Analysis (Steps and Protocol Impact)

|**Attempted Configuration Step**|**Identified Error / Failure Code**|**Root Cause (Protocol or Policy)**|**Supporting Policy Rationale**|
|---|---|---|---|
|1. Initial Hash Format `smtp_relays`|`bad URI(is not URI?): "{...}"`|Postal Configuration Syntax Error (Expected URI format).|Postal expects RFC-compliant URI structure for relays.|
|2. URI Format (IPv4 Only Whitelisted)|`550-5.7.1 Invalid credentials for relay [2a01:4ff:f0:3c5c::1]`|IP Mismatch: Postal connected via IPv6, but only IPv4 was whitelisted.|Google strictly validates source IP against the whitelist.|
|3. Added IPv6, Used SMTP AUTH|`550-5.7.1... doesn't match the domain of the account this email is being sent from`|Identity Mismatch (Layer 1): MAIL FROM domain misalignment with AUTH domain.|Google enforces sender domain association when using SMTP AUTH.|
|4. Verified Domains, EHLO remained `mail.jcharlesassets.com`|`550-5.7.1... still presenting wrong hostname in EHLO command`|Identity Mismatch (Layer 2): Postal’s EHLO FQDN failed to satisfy Google’s validation of the core Workspace domain.|Fails explicit Google mandate to present a registered domain in EHLO/HELO.|
|5. Changed `smtp_hostname: jcharlesassets.com`|Success Confirmed Post-Testing|Resolution: Explicit EHLO hostname now satisfies Google’s requirement for domain identification, aligning all three components (IP, AUTH, EHLO).|Fulfills the requirement to present a registered domain in the HELO/EHLO command.|

 

## V. Hardening the Postal Configuration for Deliverability and Compliance

Achieving reliable relaying with Google requires meticulous attention to the Postal configuration syntax and foundational DNS health, ensuring not only connection acceptance but also long-term email deliverability.

### 5.1 Postal Configuration Deep Dive and Syntax

The use of an external SMTP relay in Postal is managed through the `smtp_relays` parameter. The successful connection string adheres to the standard URI format: `smtp://jamesrogers%40jcharlesassets.com:ikzdtgydgisrmofq@smtp-relay.gmail.com:587`

It is imperative that the username uses URL encoding (`%40` for the `@` symbol) if the library handling the URI parsing requires it, although modern MTA configurations often tolerate the literal `@` within the username field. Crucially, the password component (`ikzdtgydgisrmofq`) must be an App Password generated after enabling 2FA on the `jamesrogers@jcharlesassets.com` account, as Google mandates this higher security standard for non-OAuth applications.  

The resolution hinges on the `smtp_hostname` parameter, which is dedicated to controlling the FQDN presented in the initial EHLO command. For external relay compliance, this must match the primary domain of the Google Workspace account.

### 5.2 DNS Health Check: Deliverability vs. Relay Policy

The user correctly undertook comprehensive domain verification in Step 4, including adding DNS records for MX, DKIM, Return Path CNAME, and updating the SPF record.

The importance of these DNS records must be understood in the context of the failure chronology. The initial problem was a connection refusal (`550-5.7.1`) at the policy layer. This refusal happens _before_ Google evaluates the MAIL FROM domain's SPF and DKIM records. Thus, while correctly configured SPF (to include both the Postal server and Google's SPF) and DKIM (`postal-clitdu._domainkey`) records are non-negotiable for **deliverability** (ensuring mail is trusted by downstream recipients and avoids spam folders) , they did not resolve the immediate EHLO identity failure. The EHLO hostname correction serves as the gatekeeper to connection acceptance, establishing MTA trust, while DNS records secure the trustworthiness of the email content itself.  

The SPF record, specifically, must authorize both the Postal server's outbound IP ranges and Google's outbound mail servers (`_spf.google.com`), as the mail flow now traverses two distinct infrastructure layers.  

### 5.3 Long-Term Stability: Alternative Configuration Recommendation

While the hybrid configuration (IP Whitelist + SMTP AUTH) is now functioning, administrators managing large-scale MTA operations like Postal should consider simplifying the authentication mechanism for enhanced stability.

For servers relaying mail from numerous applications, aliases, or potentially external domains (if permitted by the "Any addresses" setting), the most architecturally sound approach under Google Workspace SMTP Relay (Option 1) is to rely solely on **IP Whitelisting**.

The recommended simplified configuration is:

1. **Google Workspace Settings:** Set **Authentication** to "Only accept mail from the specified IP addresses" and ensure "Require SMTP Authentication" is **UNCHECKED**.  
    
2. **Postal Configuration:** Remove the username and password from the `smtp_relays` URI (e.g., `smtp://smtp-relay.gmail.com:587`).
    
3. **EHLO Alignment:** Retain the critical `smtp_hostname: jcharlesassets.com` setting.
    

This IP-only configuration reduces the risk of authentication errors related to user credentials, simplifies the identity reconciliation process for the Google policy engine, and fully utilizes the IP whitelisting capacity of the service. Even in this simplified setup, the mandatory requirement to present a verified domain name in the EHLO command remains paramount, confirming the enduring significance of the corrective action taken in Step 5.  

## VI. Conclusion and Actionable Recommendations

The inability to relay mail, signaled by the `550-5.7.1` error, was not a failure of credentials or IP whitelisting in isolation, but rather a policy rejection caused by the misaligned MTA identity presented in the EHLO command. By setting the Postal `smtp_hostname` parameter to the primary Google Workspace domain (`jcharlesassets.com`), the administrator correctly synchronized all required identity components (Source IP, SMTP AUTH domain, and EHLO domain), resolving the protocol-level security conflict.

### Recommendations for Hardened Configuration:

1. **Verify EHLO Alignment:** Maintain `postal.yml` with `smtp_hostname: jcharlesassets.com` to guarantee compliance with Google’s mandate for domain identification during the EHLO handshake.
    
2. **Maintain Dual-Stack Whitelisting:** Continuously ensure both the Postal server's IPv4 (`178.156.206.220`) and IPv6 (`2a01:4ff:f0:3c5c::1`) addresses are listed in the Google Workspace SMTP Relay whitelist to prevent future connection failures due to network stack routing.  
    
3. **Use App Passwords:** Ensure the authenticated user employs a Google App Password for all SMTP AUTH connections, adhering to modern security standards, as traditional passwords are no longer supported for 2FA-enabled accounts.  
    
4. **Confirm DNS Integrity:** Regularly audit SPF, DKIM, and Return Path DNS records. While these did not cause the connection failure, they are essential for ensuring mail accepted by the relay ultimately achieves high deliverability rates.  
    
5. **Consider Simplification:** Evaluate switching the Google Workspace SMTP Relay configuration to IP Whitelisting only (unchecking SMTP Authentication) if the purpose of the Postal MTA is primarily generic application relaying, as this reduces policy friction associated with hybrid authentication.
    

Sources used in the report

[

![](https://t3.gstatic.com/faviconV2?url=https://support.google.com/&client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL)

support.google.com

SMTP relay service error messages - Google Workspace Admin Help

Opens in a new window](https://support.google.com/a/answer/6140680?hl=en)[

![](https://t3.gstatic.com/faviconV2?url=https://support.google.com/&client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL)

support.google.com

Route outgoing SMTP relay messages through Google - Google Workspace Admin Help

Opens in a new window](https://support.google.com/a/answer/2956491?hl=en)[

![](https://t3.gstatic.com/faviconV2?url=https://support.google.com/&client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL)

support.google.com

Send email from a printer, scanner, or app - Google Workspace Admin Help

Opens in a new window](https://support.google.com/a/answer/176600?hl=en)[

![](https://t0.gstatic.com/faviconV2?url=https://help.nextcloud.com/&client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL)

help.nextcloud.com

Started getting SMTP errors from Gmail relay - Nextcloud community

Opens in a new window](https://help.nextcloud.com/t/started-getting-smtp-errors-from-gmail-relay/107694)[

![](https://t0.gstatic.com/faviconV2?url=https://stackoverflow.com/&client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL)

stackoverflow.com

Issues sending email through Google's SMTP Relay - Stack Overflow

Opens in a new window](https://stackoverflow.com/questions/73362999/issues-sending-email-through-googles-smtp-relay)[

![](https://t1.gstatic.com/faviconV2?url=https://github.com/&client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL)

github.com

Can not send mail using an SMTP relay without authentication · Issue #4686 - GitHub

Opens in a new window](https://github.com/mealie-recipes/mealie/issues/4686)[

![](https://t3.gstatic.com/faviconV2?url=https://support.google.com/&client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL)

support.google.com

Gmail SMTP errors and codes - Google Workspace Admin Help

Opens in a new window](https://support.google.com/a/answer/3726730?hl=en)[

![](https://t2.gstatic.com/faviconV2?url=https://help.gohighlevel.com/&client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL)

help.gohighlevel.com

Common Unsuccessful Email errors in Conversation - HighLevel Support Portal

Opens in a new window](https://help.gohighlevel.com/support/solutions/articles/48001209322-email-error-library-for-supported-smtps)[

![](https://t3.gstatic.com/faviconV2?url=https://www.warmy.io/&client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL)

warmy.io

SMTP Error 550 5.7.1 | How to solve your issue quickly | Full Guide - Warmy.io

Opens in a new window](https://www.warmy.io/blog/how-to-fix-smtp-email-error-550-5-7-1-solved/)[

![](https://t3.gstatic.com/faviconV2?url=https://www.warmy.io/&client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL)

warmy.io

Gmail SMTP Settings: A Step-by-Step Guide to Configuring Your Gmail SMTP - Warmy.io

Opens in a new window](https://www.warmy.io/blog/gmail-smtp-settings-guide-configuring-gmail-smtp/)[

![](https://t3.gstatic.com/faviconV2?url=https://printing.its.uiowa.edu:9192/&client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL)

printing.its.uiowa.edu

Configure an SMTP server for Google Workspace - PaperCut Login for University of Iowa

Opens in a new window](https://printing.its.uiowa.edu:9192/content/help/common/topics/sys-notifications-configure-smtp-google-workspace.html)[

![](https://t0.gstatic.com/faviconV2?url=https://help.front.com/&client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL)

help.front.com

Configuring Google Workspace accounts to send via Gmail SMTP Relay - Front Help Center

Opens in a new window](https://help.front.com/en/articles/2324)[

![](https://t2.gstatic.com/faviconV2?url=https://www.reddit.com/&client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL)

reddit.com

SMTP relay alternative now that Google workspace no longer supports passwords? - Reddit

Opens in a new window](https://www.reddit.com/r/homelab/comments/1kp108s/smtp_relay_alternative_now_that_google_workspace/)[

![](https://t0.gstatic.com/faviconV2?url=https://sites.google.com/site/whatisthesmtpserverforgmaiil/what-is-the-smtp-server-for-gmail-help-1-888-588-2108/&client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL)

sites.google.com

How to Use the Gmail SMTP Server to Send Emails for Free - Google Sites

Opens in a new window](https://sites.google.com/site/whatisthesmtpserverforgmaiil/what-is-the-smtp-server-for-gmail-help-1-888-588-2108)[

![](https://t3.gstatic.com/faviconV2?url=https://reply.io/&client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL)

reply.io

The Ultimate Guide to Gmail SMTP Settings in 2025 - Reply.io

Opens in a new window](https://reply.io/blog/gmail-smtp-settings/)[

![](https://t3.gstatic.com/faviconV2?url=https://kb.binalyze.com/&client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL)

kb.binalyze.com

Whitelisting for Relay Server - AIR Knowledge Base

Opens in a new window](https://kb.binalyze.com/air/setup/relay-server/whitelisting-for-relay-server)[

![](https://t3.gstatic.com/faviconV2?url=https://support.google.com/&client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL)

support.google.com

Google IP address ranges for outbound mail servers - Google Workspace Admin Help

Opens in a new window](https://support.google.com/a/answer/60764?hl=en)

Sources read but not used in the report

[](https://www.reddit.com/r/k12sysadmin/comments/13snad5/smtp_relay_for_gmail_got_it_working/)