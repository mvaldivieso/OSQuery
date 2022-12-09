/*************************** Sophos.com/RapidResponse ***************************\
| DESCRIPTION                                                                    |
| Detects suspicious commands that might be associated with webshell activity    |
|                                                                                |
| VARIABLES                                                                      |
| - start_time: (Type: DATE)                                                     |
| - end_time: (Type: DATE)                                                       |
|                                                                                |
| REFERENCE                                                                      |
| https://attack.mitre.org/techniques/T1505/003/                                 |
|                                                                                |
| Version: 1.0                                                                   |
| Author: The Rapid Response Team                                                |
| github.com/SophosRapidResponse                                                 |
\********************************************************************************/

SELECT 
    strftime('%Y-%m-%dT%H:%M:%SZ',datetime(spj.time,'unixepoch')) AS date_time,
    CAST (spj.process_name AS TEXT) process_name,
    spj.cmd_line,
    spj.sophos_pid, 
    strftime('%Y-%m-%dT%H:%M:%SZ',datetime(spj.process_start_time,'unixepoch')) AS process_start_time, 
    CASE WHEN spj.end_time = 0 THEN '' ELSE strftime('%Y-%m-%dT%H:%M:%SZ',datetime(spj.end_time,'unixepoch')) END AS process_end_time, 
    users.username,
    spj.sid,
    spj.parent_sophos_pid,
    CAST ( (Select spj2.process_name from sophos_process_journal spj2 where spj2.sophos_pid = spj.parent_sophos_pid) AS text) parent_process,
    CAST ( (Select spj2.cmd_line from sophos_process_journal spj2 where spj2.sophos_pid = spj.parent_sophos_pid) AS text) parent_cmd_line,
    'Process Journal/Users' AS Data_Source,
    'Webshell Activity' AS Query 
FROM sophos_process_journal spj
LEFT JOIN users ON spj.sid = users.uuid
WHERE (parent_process = 'w3wp.exe' OR parent_process = 'httpd.exe' OR parent_process LIKE 'tomcat%.exe' OR parent_process = 'nginx.exe' OR parent_process = 'beasvc.exe' OR parent_process = 'coldfusion.exe' OR parent_process = 'visualsvnserver.exe' OR parent_process = 'java.exe')
    AND (process_name = 'cmd.exe' OR process_name = 'powershell.exe' OR process_name = 'powershell_ise.exe' OR process_name = 'certutil.exe')
    AND spj.time >= $$start_time$$ 
    AND spj.time <= $$end_time$$
