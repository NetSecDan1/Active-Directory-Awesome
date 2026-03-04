# Active Directory Performance Optimization

## AI Prompts for AD Performance Troubleshooting and Tuning

---

## Overview

Active Directory performance directly impacts user authentication speed, application responsiveness, and overall IT operations. Performance issues can stem from LDAP queries, replication load, hardware constraints, or configuration problems. This module provides AI prompts for diagnosing and optimizing AD performance.

---

## Section 1: Performance Assessment

### Prompt 1.1: AD Performance Baseline

```
I need to establish or assess AD performance baseline.

ENVIRONMENT:
- Number of DCs: [X]
- Users/computers: [Approximate counts]
- Peak usage times: [When]
- Current performance concerns: [Describe]

MONITORING AVAILABLE:
[Describe current monitoring capabilities]

Please provide:
1. Key AD performance metrics to baseline
2. Performance counter collection procedure
3. Normal vs. concerning threshold values
4. Tools for performance data collection
5. Baseline documentation template
6. Ongoing monitoring recommendations
7. Alerting thresholds to configure
```

### Prompt 1.2: DC Performance Troubleshooting

```
A domain controller is experiencing performance issues.

DC: [Name]
SYMPTOMS:
- Slow authentications: [Yes/No]
- High CPU: [Yes/No, percentage if known]
- High memory: [Yes/No, usage if known]
- Slow LDAP: [Yes/No]
- Disk bottleneck: [Yes/No]

CURRENT LOAD:
- Users serviced: [Approximate]
- Applications using DC: [List major ones]

Please provide:
1. Performance diagnostic procedure
2. Identifying the bottleneck type
3. Process-level analysis
4. LDAP query analysis
5. Quick wins for improvement
6. Long-term optimization recommendations
7. Capacity planning considerations
```

---

## Section 2: LDAP Performance

### Prompt 2.1: Slow LDAP Query Investigation

```
LDAP queries against AD are slow.

AFFECTED QUERIES:
[Describe query types or applications]

SYMPTOMS:
- Query response time: [X ms/seconds]
- Timeout errors: [Yes/No]
- Specific DCs affected: [All/Specific ones]

LDAP QUERY EXAMPLES:
[Paste sample queries if available]

Please provide:
1. LDAP query performance diagnostic steps
2. Identifying expensive queries
3. Query optimization techniques
4. Index analysis and creation
5. Query policy limits
6. Connection management
7. DC selection optimization
```

### Prompt 2.2: LDAP Query Optimization

```
I need to optimize LDAP queries for better performance.

QUERY DETAILS:
- Base DN: [Where query starts]
- Filter: [Query filter]
- Attributes requested: [List]
- Scope: [Base/OneLevel/Subtree]
- Current performance: [Response time]

FREQUENCY:
[How often query runs]

Please provide:
1. Query analysis and improvement suggestions
2. Filter optimization
3. Attribute selection optimization
4. Scope considerations
5. Index recommendations
6. Pagination for large results
7. Testing optimized query
```

### Prompt 2.3: LDAP Policies and Limits

```
I need to understand or modify LDAP policies.

CURRENT ISSUE:
[Describe - hitting limits, need to change defaults]

CURRENT SETTINGS:
[Known settings or "need to check"]

Please provide:
1. Default LDAP policy limits explained
2. How to view current policy settings
3. Impact of each limit
4. Safe modification procedure
5. Recommendations for each setting
6. Query policy vs. LDAP policies
7. Monitoring for limit hits
```

---

## Section 3: Authentication Performance

### Prompt 3.1: Slow Authentication Troubleshooting

```
User authentication is slow.

SYMPTOMS:
- Login time: [X seconds]
- Affected users: [Scope]
- Specific times: [Always/Peak hours/Random]
- Protocol: [Kerberos/NTLM/Both]

ENVIRONMENT:
- Client locations: [Local/Remote/VPN]
- DC locations: [Sites]

Please provide:
1. Authentication performance diagnostic steps
2. DC selection/locator analysis
3. Kerberos vs. NTLM performance
4. Network latency impact
5. DC performance check
6. Client-side optimizations
7. Site topology optimization
```

### Prompt 3.2: Kerberos Performance Optimization

```
I want to optimize Kerberos authentication performance.

ENVIRONMENT:
- Multi-domain: [Yes/No]
- Trusts: [Number and types]
- Average ticket size: [If known]
- Token size issues: [Yes/No]

CURRENT CONCERNS:
[Describe performance issues]

Please provide:
1. Kerberos performance factors
2. Ticket size optimization
3. Group membership optimization
4. SID compression benefits
5. Referral optimization
6. Clock skew prevention
7. KDC performance tuning
```

---

## Section 4: Replication Performance

### Prompt 4.1: Replication Performance Issues

```
AD replication is slow or causing performance issues.

SYMPTOMS:
- Replication latency: [X minutes/hours]
- Bandwidth consumption: [Concerns]
- DC performance during replication: [Issues]

TOPOLOGY:
- Sites: [Number]
- Site links: [Configuration]
- WAN bandwidth: [Available bandwidth]

Please provide:
1. Replication performance assessment
2. Identifying replication bottlenecks
3. Site link scheduling optimization
4. Compression settings
5. Change notification tuning
6. Replication bridgehead optimization
7. Bandwidth management
```

### Prompt 4.2: Large Environment Replication Optimization

```
I need to optimize replication for a large AD environment.

ENVIRONMENT SIZE:
- Objects: [X thousand/million]
- DCs: [X]
- Sites: [X]
- Geographic distribution: [Describe]

CURRENT CHALLENGES:
[Describe replication issues]

Please provide:
1. Large environment replication best practices
2. Topology optimization strategies
3. Site link cost and schedule tuning
4. Bridgehead server strategy
5. Universal group membership caching
6. RODC deployment considerations
7. Monitoring recommendations
```

---

## Section 5: Database Performance

### Prompt 5.1: NTDS Database Performance

```
AD database performance needs improvement.

DATABASE SIZE: [X GB]
LOG FILE SIZE: [X GB]
DISK SUBSYSTEM: [SSD/HDD, RAID level]

SYMPTOMS:
- Slow queries: [Yes/No]
- High disk I/O: [Yes/No]
- Database growth concerns: [Yes/No]

Please provide:
1. Database performance assessment
2. Disk I/O optimization
3. Database placement best practices
4. Defragmentation benefits and procedure
5. Transaction log management
6. ESE buffer tuning
7. Hardware recommendations
```

### Prompt 5.2: AD Search Performance

```
Active Directory searches are slow.

SEARCH TYPES AFFECTED:
[Global catalog, specific OUs, specific attributes]

SEARCH VOLUME:
[Approximate searches per minute/hour]

INDEXED ATTRIBUTES:
[Known indexed attributes or "default"]

Please provide:
1. Search performance diagnostics
2. Identifying expensive searches
3. Index evaluation
4. Creating custom indexes
5. GC vs. domain queries
6. Search scope optimization
7. Application query optimization
```

---

## Section 6: Memory and CPU

### Prompt 6.1: LSASS Performance Issues

```
LSASS is consuming high CPU or memory.

DC: [Name]
CPU USAGE: [Percentage]
MEMORY USAGE: [Amount]
DURATION: [Ongoing/Periodic]

CONCURRENT OPERATIONS:
[Describe load - authentications, LDAP, replication]

Please provide:
1. LSASS performance analysis
2. Identifying resource-intensive operations
3. Safe troubleshooting approaches
4. Memory sizing for LSASS
5. CPU optimization
6. Query identification and optimization
7. When to add DC capacity
```

### Prompt 6.2: DC Memory Optimization

```
I need to optimize memory usage on domain controllers.

DC SPECIFICATIONS:
- Total RAM: [X GB]
- Current usage: [X GB]
- LSASS usage: [X GB]
- ESE cache size: [If known]

WORKLOAD:
- Users/computers: [Count]
- LDAP-intensive apps: [Yes/No]

Please provide:
1. Memory requirements calculation
2. LSASS memory management
3. ESE database cache tuning
4. Schema cache sizing
5. DNS cache considerations
6. Monitoring memory pressure
7. Upgrade recommendations
```

---

## Section 7: Network Performance

### Prompt 7.1: AD Network Optimization

```
Network performance is affecting AD operations.

SYMPTOMS:
[Describe - slow DC locator, replication delays, auth timeouts]

NETWORK TOPOLOGY:
- Site link bandwidth: [Values]
- Latency between sites: [Values]
- Firewall/proxy: [Present between sites?]

Please provide:
1. Network requirements for AD
2. Site topology optimization
3. DC placement recommendations
4. Universal group caching
5. Read-Only DC considerations
6. Bandwidth optimization
7. Latency mitigation strategies
```

### Prompt 7.2: DC Locator Optimization

```
Clients are not selecting optimal domain controllers.

SYMPTOMS:
- Slow logins for certain users: [Describe]
- Wrong site DC selection: [Yes/No]
- Cross-site authentication: [Observed]

SITE/SUBNET CONFIGURATION:
[Describe current configuration]

Please provide:
1. DC locator process explained
2. Diagnosing DC selection issues
3. Subnet configuration verification
4. Site coverage configuration
5. DC weight and priority
6. Caching and refresh considerations
7. Verification after fixes
```

---

## Section 8: Capacity Planning

### Prompt 8.1: DC Capacity Planning

```
I need guidance on DC capacity planning.

CURRENT ENVIRONMENT:
- Users: [X]
- Computers: [X]
- DCs: [X]
- Growth rate: [X% per year]

WORKLOAD CHARACTERISTICS:
- Peak auth rate: [If known]
- LDAP query volume: [If known]
- Applications: [Major applications using AD]

Please provide:
1. DC sizing guidelines
2. CPU requirements calculation
3. Memory requirements calculation
4. Disk requirements
5. Network considerations
6. DCs per site recommendations
7. Growth planning
8. Virtualization considerations
```

### Prompt 8.2: Performance Testing

```
I want to perform AD performance testing.

PURPOSE:
[Baseline, capacity validation, change testing]

ENVIRONMENT:
- Production or test: [Which]
- Testing window: [Available time]

Please provide:
1. AD performance testing tools
2. Creating realistic test workloads
3. Metrics to collect during testing
4. Safe testing in production
5. Interpreting results
6. Documenting findings
7. Test-to-production correlation
```

---

## Quick Reference: Performance Counters

```
# Key AD Performance Counters

# LSASS Process
\Process(lsass)\% Processor Time
\Process(lsass)\Working Set

# NTDS Performance
\NTDS\LDAP Searches/sec
\NTDS\LDAP Successful Binds/sec
\NTDS\LDAP Active Threads
\NTDS\DRA Inbound Bytes Total/sec
\NTDS\DRA Outbound Bytes Total/sec
\NTDS\DS Threads In Use

# Database (ESE)
\Database(lsass)\Database Cache Size
\Database(lsass)\Database Page Faults/sec
\Database(lsass)\Log Bytes Write/sec

# Security
\Security System-Wide Statistics\Kerberos Authentications
\Security System-Wide Statistics\NTLM Authentications

# DNS (if on DC)
\DNS\Total Query Received/sec
\DNS\Total Response Sent/sec

# Disk
\LogicalDisk(C:)\Avg. Disk sec/Read
\LogicalDisk(C:)\Avg. Disk sec/Write
\LogicalDisk(*)\% Disk Time
```

---

## Performance Thresholds

| Metric | Normal | Warning | Critical |
|--------|--------|---------|----------|
| LDAP Search/sec | <1000 | 1000-5000 | >5000 |
| LSASS CPU % | <50% | 50-80% | >80% |
| Disk Queue Length | <2 | 2-5 | >5 |
| LDAP Response Time | <50ms | 50-200ms | >200ms |
| Auth Response Time | <100ms | 100-500ms | >500ms |

---

## Related Modules

- [Domain Controller Health](06-Domain-Controller-Health.md) - DC health and performance
- [Replication Issues](01-Replication-Issues.md) - Replication performance
- [DNS Integration](03-DNS-Integration.md) - DNS performance on DCs

---

[Back to Master Guide](00-AD-Master-Troubleshooting-Guide.md)
