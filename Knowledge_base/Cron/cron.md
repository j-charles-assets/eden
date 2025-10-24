You have zeroed in on the most complex aspect of time-aware marketing: enforcing a delivery _window_ (8:00 AM to 7:00 PM) based on a contact's _local time_, while simultaneously throttling the overall daily volume.

As identified in the previous analysis, the platform natively supports delivery at a contact's local time, but it **does not** natively support time window enforcement.1 To achieve this, you must adopt the "Time-Gated Dynamic Segmentation" strategy, which relies on synchronized, high-frequency cron jobs.

Below is the full, prescribed cron job schedule for your Hetzner Docker environment, which combines the necessary maintenance tasks with the specialized input/output throttling required to maintain the 4,000-per-day rate within the 11-hour local time window.

---

## Recommended CRON Schedule for Time-Gated Drip Campaign

This schedule is engineered to achieve a maximum daily send rate of **3,960 emails per day** (6 emails per minute for 660 minutes) **during the 8:00 AM – 7:00 PM local window.**

The recommended approach for a Dockerized environment is to run the cron jobs from a dedicated `mautic_cron` service, using `docker exec` commands initiated by the Docker host's standard cron service, or by running a dedicated cron daemon inside the `mautic_cron` container itself.3

### Phase 1: High-Frequency Drip Control (Every 5 Minutes)

To manage your large segment size ($50,000$) and enforce the strict 4,000/day limit, we use a dual-throttled approach every five minutes. The effective hourly limit is **360 emails per hour** ($6 \text{ emails/min} \times 60 \text{ min/hr}$).

|**Schedule (Host Time)**|**Command**|**Parameter**|**Purpose**|
|---|---|---|---|
|**`* 8-18 * * *`**|`mautic:emails:send`|`--message-limit=30`|**Email Dispatch (Output Throttling):** This command pulls messages from the queue (spool) and attempts to send them to the Google SMTP server. The limit is set to 30 messages every minute (since it runs every minute of the hour, from 8 AM to 6 PM, this is equivalent to $5 \times 6 = 30$ per 5-minute block). _Correction:_ To run every 5 minutes within the window, the cron expression is better defined as `*/5 8-18 * * *`. The `--message-limit` is then set to **30**. This ensures a smooth drip. 4|
|**`*/5 8-18 * * *`**|`mautic:emails:send`|`--message-limit=30`|**RATE ENFORCEMENT (OUTPUT):** Runs every 5 minutes from 8 AM through 6:55 PM. Pulls and sends **30 emails** (5 minutes $\times$ 6 emails/min) from the queue to the MTA. This maintains the maximum 3,960 daily drip rate. 4|
|**`*/5 8-18 * * *`**|`mautic:campaigns:trigger`|`--campaign-limit=30`|**INPUT CONTROL (SPOOLING):** Runs every 5 minutes, processing only **30 contacts** per execution. This prevents Mautic from spooling all 50,000 emails at once, avoiding server resource spikes.6 The limit must match the output limit for tight queue control.7|

### Phase 2: Essential Campaign Maintenance (Every 15 Minutes)

The following commands are computationally heavy and are segregated into a longer 15-minute interval to avoid resource contention with the high-frequency drip commands.8

|**Schedule (Host Time)**|**Command**|**Parameter**|**Purpose**|
|---|---|---|---|
|**`*/15 * * * *`**|`mautic:segments:update`|`--batch-limit=900`|Keeps dynamic segments current, evaluating contact filters. Running every 15 minutes is standard best practice.10|
|**`*/15 * * * *`**|`mautic:campaigns:update`|`--batch-limit=300`|Adds newly eligible contacts to the campaign flow (but does not execute actions).10|
|**`0 * * * *`**|`mautic:broadcasts:send`|(No limit specified)|Sends scheduled Segment Emails (Newsletters). Runs hourly on the hour (e.g., 8:00, 9:00, etc.).11|

### Phase 3: Daily Housekeeping

|**Schedule (Host Time)**|**Command**|**Parameter**|**Purpose**|
|---|---|---|---|
|**`0 2 * * *`**|`mautic:maintenance:cleanup`|(No limit specified)|Executes daily database maintenance, cache clearing, and log rotation (scheduled for 2:00 AM Host Time).12|

---

## Timezone and Delivery Window Notes

The biggest consideration remains the **Time-Gated Dynamic Segmentation** strategy required to respect the _recipient’s local time_ and window.1

1. **CRON Job Time Zone:** The cron schedule listed above (`*/5 8-18 * * *`) runs based on the time zone configured on your Hetzner host machine.
    
2. **The Time-Gating Requirement:** For the 8:00 AM – 7:00 PM constraint to work for recipients in different time zones (e.g., Eastern Time vs. Pacific Time), you cannot rely on the cron schedule alone. You must implement the following:
    
    - **Segment Creation:** Create separate segments for each major US time zone cluster (e.g., `Segment_EASTERN_TIME_US`, `Segment_PACIFIC_TIME_US`).
        
    - **External Time-Gating:** You need external tooling or a custom script run by the host's cron to **unpublish** the segments at 7:00 PM local time for that cluster and **republish** them at 8:00 AM local time for that cluster.1 This manually creates the window boundary.
        
    - **CRON_TZ Feature:** If your Linux distribution supports the `CRON_TZ` variable (like `cronie`), you can configure the external scheduling script to run according to the target time zone, simplifying management and handling Daylights Saving Time shifts 14:
        
    
    Bash
    
    ```
    # Example for Eastern Time Segment Publishing (Run this on the host machine)
    CRON_TZ=America/New_York
    0 8 * * * /path/to/mautic/bin/console mautic:segments:publish --segment-name=Segment_EASTERN_TIME_US
    0 19 * * * /path/to/mautic/bin/console mautic:segments:unpublish --segment-name=Segment_EASTERN_TIME_US
    ```
    
3. **Mautic Internal Time Zone:** Ensure Mautic's internal system timezone (Configuration $\rightarrow$ System Settings) is correctly set to maintain consistency across campaign logs and user interface displays.15