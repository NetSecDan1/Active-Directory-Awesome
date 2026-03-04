# Active Directory Certificate Services (AD CS) Troubleshooting

## AI Prompts for PKI and Certificate Issues in AD Environments

---

## Overview

Active Directory Certificate Services provides the foundation for enterprise PKI, enabling secure authentication, encryption, and digital signatures. Certificate issues can break smart card authentication, SSL/TLS, code signing, and many critical services. This module provides comprehensive AI prompts for AD CS troubleshooting.

---

## Section 1: CA Health Assessment

### Prompt 1.1: CA Infrastructure Health Check

```
I need to assess the health of my AD CS infrastructure.

CA ENVIRONMENT:
- Number of CAs: [X]
- CA hierarchy: [Single/Two-tier/Three-tier]
- Root CA type: [Enterprise/Standalone, Online/Offline]
- Issuing CAs: [List names and types]
- Key lengths: [RSA 2048/4096, etc.]

CURRENT CONCERNS:
[Describe any issues or reasons for assessment]

Please provide:
1. CA service health verification commands
2. Certificate database health check
3. CRL publication verification
4. AIA and CDP accessibility testing
5. CA certificate chain validation
6. Template configuration review
7. Priority issues checklist
```

### Prompt 1.2: Comprehensive PKI Audit

```
I need to perform a comprehensive PKI audit.

ENVIRONMENT:
- Forest/domain structure: [Describe]
- CA servers: [List]
- Certificate usage: [Smart cards, SSL, code signing, etc.]
- Integration points: [NDES, CEP, CES, etc.]

Please provide:
1. PKI infrastructure documentation checklist
2. Security audit points
3. Certificate lifecycle review
4. Key protection assessment
5. Disaster recovery readiness
6. Compliance verification (if applicable)
7. Improvement recommendations
```

---

## Section 2: Certificate Enrollment Issues

### Prompt 2.1: Autoenrollment Not Working

```
Certificate autoenrollment is not working.

TEMPLATE: [Template name]
TARGET: [Users/Computers/Both]
CA: [CA name]

SYMPTOMS:
[Describe - certificates not appearing, enrollment errors]

GROUP POLICY:
[Describe autoenrollment GPO settings]

EVENT LOG (Certificate Services Client):
[Paste relevant events]

Please provide:
1. Autoenrollment requirements checklist
2. Template permission verification
3. GPO configuration verification
4. CA accessibility from client
5. Common autoenrollment failures
6. Diagnosing specific enrollment errors
7. Verification after fixes
```

### Prompt 2.2: Manual Enrollment Failures

```
Manual certificate enrollment is failing.

ENROLLMENT METHOD: [MMC, certreq, web enrollment, etc.]
TEMPLATE: [Template name]
USER/COMPUTER: [Requesting entity]
CA: [Target CA]

ERROR MESSAGE:
[Paste exact error]

Please provide:
1. Enrollment prerequisites verification
2. Template availability check
3. Permission requirements
4. CA service accessibility
5. Error code interpretation
6. Resolution steps
7. Alternative enrollment methods
```

### Prompt 2.3: NDES/SCEP Enrollment Issues

```
Network Device Enrollment Service (NDES) is not working.

NDES SERVER: [Server name]
CA: [Associated CA]
DEVICES AFFECTED: [Network devices, MDM, etc.]

SYMPTOMS:
[Describe enrollment failures]

ERROR DETAILS:
[Paste errors from NDES, IIS, or device]

Please provide:
1. NDES health verification
2. Service account permissions
3. IIS configuration check
4. Challenge password issues
5. Certificate template for NDES
6. Troubleshooting device-side issues
7. Common NDES problems and fixes
```

---

## Section 3: CRL and OCSP Issues

### Prompt 3.1: CRL Publishing Failures

```
CRL publishing is failing or CRLs are not accessible.

CA: [CA name]
CDP LOCATIONS: [List CDP URLs]
PUBLISHING METHOD: [LDAP, HTTP, file share]

SYMPTOMS:
- CRL expired: [Yes/No]
- CRL not accessible: [From where]
- Publishing errors: [Describe]

EVENT LOG (CA):
[Paste relevant events]

Please provide:
1. CRL publishing diagnostics
2. CDP accessibility verification
3. File/folder permissions for publishing
4. LDAP publication to AD verification
5. Web server configuration for HTTP CDP
6. Manual CRL publishing procedure
7. Monitoring recommendations
```

### Prompt 3.2: OCSP Responder Issues

```
Online Certificate Status Protocol (OCSP) responder is not working.

OCSP SERVER: [Server name]
CA: [Associated CA]
AIA OCSP URL: [URL]

SYMPTOMS:
[Describe - revocation check failures, timeouts]

Please provide:
1. OCSP responder service verification
2. OCSP signing certificate check
3. Array configuration review
4. AIA extension verification
5. Client-side OCSP troubleshooting
6. Failover to CRL verification
7. Performance optimization
```

### Prompt 3.3: Revocation Check Failures

```
Certificate revocation checking is causing issues.

AFFECTED APPLICATION: [Browser, app, service]
CERTIFICATE: [For what service/site]
ERROR: [Revocation check failed, certificate revoked, etc.]

CLIENT ENVIRONMENT:
- Network access to CDP/OCSP: [Tested/Unknown]
- Proxy configuration: [If applicable]

Please provide:
1. Revocation check path diagnosis
2. CRL vs. OCSP troubleshooting
3. Network/firewall verification
4. Client revocation settings
5. Soft-fail vs. hard-fail configuration
6. Temporary workarounds (with security implications)
7. Permanent resolution
```

---

## Section 4: Certificate Template Issues

### Prompt 4.1: Certificate Template Configuration

```
I need to create or modify a certificate template.

PURPOSE: [What the certificate will be used for]
REQUIREMENTS:
- Key usage: [Describe]
- Subject requirements: [CN, SAN, etc.]
- Validity period: [Duration]
- Autoenrollment needed: [Yes/No]
- Who can enroll: [Groups/users]

EXISTING TEMPLATE (if modifying): [Template name]

Please provide:
1. Template design recommendations for this use case
2. Step-by-step creation/modification procedure
3. Security considerations
4. Key archival considerations
5. Publishing template to CAs
6. Permission configuration
7. Testing enrollment
```

### Prompt 4.2: Template Permission Issues

```
Users or computers cannot see or enroll for a certificate template.

TEMPLATE: [Name]
AFFECTED ENTITIES: [Users/computers/groups]
CA: [CA name]

EXPECTED BEHAVIOR: [What should happen]
ACTUAL BEHAVIOR: [What happens]

Please provide:
1. Template permission requirements
2. Checking current permissions
3. Read vs. Enroll vs. Autoenroll permissions
4. CA security settings impact
5. Fixing permission issues
6. Verification that template is accessible
7. Troubleshooting "template not found"
```

---

## Section 5: Smart Card and Certificate Authentication

### Prompt 5.1: Smart Card Authentication Failures

```
Smart card authentication is not working.

SMART CARD TYPE: [Physical card, virtual smart card]
CERTIFICATE TEMPLATE: [Template used for smart card certs]
AFFECTED USERS: [Scope]

SYMPTOMS:
[Describe - card not recognized, PIN issues, auth fails]

ERROR MESSAGES:
[Paste any errors]

Please provide:
1. Smart card infrastructure verification
2. Certificate validation on card
3. Certificate-to-user mapping check
4. DC certificate requirements (KDC)
5. Client-side troubleshooting
6. Common smart card issues
7. Event logs to review
```

### Prompt 5.2: PKINIT and KDC Certificate Issues

```
Domain controller Kerberos authentication using certificates is failing.

SYMPTOMS:
- Smart card login failures
- Certificate authentication errors
- PKINIT errors in event logs

DC CERTIFICATES:
[Describe current DC certificate status]

Please provide:
1. KDC certificate requirements
2. Verifying DC certificates are correct
3. Domain Controller certificate template
4. Certificate enrollment for DCs
5. NTAuth store verification
6. Strong certificate mapping (KB5014754)
7. Troubleshooting certificate chain
```

---

## Section 6: SSL/TLS Certificate Issues

### Prompt 6.1: Web Server Certificate Problems

```
SSL/TLS certificate issues on a web server.

WEB SERVER: [IIS, Apache, etc.]
CERTIFICATE: [Internal CA, public CA]
URL: [Affected URL]

SYMPTOMS:
[Describe - untrusted, name mismatch, expired]

CERTIFICATE DETAILS:
[Subject, SAN, issuer, expiration]

Please provide:
1. Certificate validation steps
2. Chain trust verification
3. Name matching verification
4. Binding configuration check
5. Intermediate certificate issues
6. SNI considerations
7. Renewal procedure
```

### Prompt 6.2: Internal SSL Certificate Deployment

```
I need to deploy SSL certificates from internal CA to servers.

SERVERS: [List or count]
CERTIFICATE TEMPLATE: [Template name]
DEPLOYMENT METHOD: [Manual, autoenrollment, script]

REQUIREMENTS:
- SAN names needed: [List]
- Validity period: [Duration]
- Key archival: [Yes/No]

Please provide:
1. Certificate template configuration for web servers
2. Enrollment procedure
3. Binding certificate to service
4. Chain distribution to clients
5. Monitoring for expiration
6. Renewal automation
7. Verification steps
```

---

## Section 7: CA Maintenance and Operations

### Prompt 7.1: CA Certificate Renewal

```
I need to renew a CA certificate.

CA: [CA name]
CA TYPE: [Root/Issuing]
CURRENT CERT EXPIRATION: [Date]
RENEW WITH SAME KEY: [Yes/No/Undecided]

SUBORDINATE CAs (if root): [List]
ISSUED CERTIFICATES COUNT: [Approximate]

Please provide:
1. CA renewal planning considerations
2. Same key vs. new key decision factors
3. Step-by-step renewal procedure
4. Updating CDP and AIA locations
5. Distributing new CA certificate
6. Impact on existing certificates
7. Validation after renewal
```

### Prompt 7.2: CA Database Maintenance

```
I need to perform maintenance on the CA database.

CA: [CA name]
DATABASE SIZE: [Size]
EXPIRED CERTS IN DB: [If known]
LAST MAINTENANCE: [When]

Please provide:
1. CA database maintenance best practices
2. Backing up CA database
3. Removing expired certificates
4. Database defragmentation
5. Certificate pruning considerations
6. Performance optimization
7. Verification after maintenance
```

### Prompt 7.3: CA Backup and Recovery

```
I need to backup or recover a Certificate Authority.

SCENARIO: [Backup planning / Active recovery needed]
CA: [CA name]
CA TYPE: [Root/Issuing]

IF RECOVERY:
- Available backups: [Describe]
- Disaster type: [Server failure, database corruption, etc.]

Please provide:
1. CA backup components checklist
2. Backup procedure using certutil
3. Backup procedure using Windows Backup
4. Private key backup (secure handling)
5. Recovery procedure step-by-step
6. Post-recovery verification
7. Testing backup integrity
```

---

## Section 8: CA Security

### Prompt 8.1: CA Security Hardening

```
I need to harden my CA infrastructure.

CURRENT STATE:
- CA type: [Root/Issuing]
- Online/Offline: [Status]
- HSM in use: [Yes/No]
- Current security measures: [Describe]

COMPLIANCE REQUIREMENTS: [If any]

Please provide:
1. CA security best practices
2. Physical security considerations
3. Key protection options (HSM)
4. CA administrative access controls
5. Audit logging configuration
6. Network segmentation
7. Security monitoring recommendations
```

### Prompt 8.2: Compromised CA Response

```
CRITICAL: CA compromise is suspected or confirmed.

CA AFFECTED: [CA name]
COMPROMISE TYPE: [Key theft, unauthorized issuance, server compromise]
EVIDENCE: [How was compromise detected]

SCOPE:
- Certificates potentially affected: [Estimate]
- Systems relying on CA: [Describe]

Please provide:
1. Immediate containment steps
2. Evidence preservation
3. Revocation strategy
4. Communication plan
5. Recovery procedure
6. New CA deployment if needed
7. Certificate reissuance
8. Post-incident security improvements
```

---

## Section 9: Troubleshooting Tools and Commands

### Prompt 9.1: PKI Diagnostic Script

```
Create a PowerShell script for comprehensive PKI diagnostics:

REQUIREMENTS:
1. Check CA service status
2. Verify CA certificate validity
3. Check CRL publishing status
4. Test CDP and AIA accessibility
5. List pending requests
6. Check certificate template availability
7. Generate HTML health report

Include error handling and documentation.
```

---

## Quick Reference: Certificate Commands

```powershell
# === CA SERVICE ===

# Check CA service status
Get-Service CertSvc

# CA configuration
certutil -getreg

# CA database info
certutil -view

# === CERTIFICATE REQUESTS ===

# View pending requests
certutil -view -out queue

# Issue pending request
certutil -resubmit RequestID

# Deny request
certutil -deny RequestID

# === CRL OPERATIONS ===

# Publish CRL manually
certutil -crl

# Check CRL
certutil -URL "http://crl-path/file.crl"

# Verify certificate revocation
certutil -verify -urlfetch certificate.cer

# === CERTIFICATE VALIDATION ===

# Verify certificate chain
certutil -verify certificate.cer

# Check certificate
certutil -dump certificate.cer

# View certificate in store
certutil -viewstore My

# === TEMPLATE OPERATIONS ===

# List templates on CA
certutil -CATemplates

# List templates in AD
certutil -Template

# === BACKUP/RESTORE ===

# Backup CA
certutil -backup C:\CABackup

# Backup CA keys only
certutil -backupKey C:\CABackup

# Restore CA
certutil -restore C:\CABackup

# === PKI HEALTH ===

# Enterprise PKI view (pkiview.msc command line)
certutil -v -config "CA\CAName" -ping

# Check CA info
certutil -CAInfo

# === ENROLLMENT ===

# Request certificate
certreq -new request.inf request.req
certreq -submit request.req certificate.cer
certreq -accept certificate.cer

# Force autoenrollment
certutil -pulse
```

---

## Common Certificate Event IDs

| Event ID | Source | Description |
|----------|--------|-------------|
| 64 | CertificateServicesClient | Autoenrollment failed |
| 65 | CertificateServicesClient | Autoenrollment succeeded |
| 82 | CertificationAuthority | Certificate issued |
| 21 | CertificationAuthority | CRL published |
| 22 | CertificationAuthority | CRL publish failed |
| 44 | CertificationAuthority | Template not found |
| 53 | CertificationAuthority | Request denied |

---

## Related Modules

- [Authentication & Kerberos](02-Authentication-Kerberos.md) - Certificate authentication
- [Security & Incident Response](10-Security-Incident-Response.md) - CA security incidents
- [Group Policy](04-Group-Policy.md) - Certificate autoenrollment GPO

---

[Back to Master Guide](00-AD-Master-Troubleshooting-Guide.md)
