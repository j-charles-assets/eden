# U-Green

# Mautic is an open-source marketing automation platform that helps businesses and organizations manage, automate, and optimize their marketing campaigns across various channels like email, social media, and text messages. It provides tools for lead management, campaign automation, landing page creation, customer segmentation, and performance tracking. As an open-source solution, Mautic is free to use, customizable, and allows businesses to own their data and avoid vendor lock-in. In this step by step guide I will show you how to install **Mautic 6** on your **UGREEN NAS** using Docker and Portainer.

# **💡Note:** This guide works perfectly with the latest [**Mautic 6.0.6**](https://github.com/mautic/mautic/releases/tag/6.0.6) release.

# 💡**Note:** Check out my guide on how to [**Install Mautic 6 on Your Synology NAS](https://mariushosting.com/how-to-install-mautic-6-on-your-synology-nas/).**

# **STEP 1**

# [**Please Support My work by Making a Donation**](https://mariushosting.com/support-my-work/).

# **STEP 2**

# Install [**Portainer using my step by step guide**](https://mariushosting.com/how-to-install-portainer-on-your-ugreen-nas/). If you already have Portainer installed on your UGREEN NAS, skip this STEP. **Attention**: [**Make sure you have installed the latest Portainer version**](https://mariushosting.com/ugreen-nas-how-to-update-portainer/).

# **STEP 3**

# **⚠️Mandatory**: [**Enable HTTPS on your UGREEN NAS**](https://mariushosting.com/how-to-enable-https-on-your-ugreen-nas/).

# **STEP 4**

# **Create a new hostname on the noip website** using your noip account. For example, I have created **mariustic** as Host and I use the free **ddns.net** domain. In the IP Address area, type in your **own IPV4 IP address from your ISP**, then click **Create**. Follow the instructions in the image below.

# 

![Mautic UGREEN NAS Set up 1](https://mariushosting.com/wp-content/uploads/2025/09/Mautic-UGREEN-NAS-Set-up-1.png)

# **STEP 5**

# Go to **Files** and open the docker folder. Inside the docker folder, create one new folder and name it **mautic**. Follow the instructions in the image below.

**Note**: Be careful to enter only lowercase, not uppercase letters.

# 

![Mautic UGREEN NAS Set up 2](https://mariushosting.com/wp-content/uploads/2025/09/Mautic-UGREEN-NAS-Set-up-2.png)

# **STEP 6**

# Now create seven new folders inside the **mautic** folder that you have previously created at **STEP 5** and name them **config**, **cron**, **db**, **files**, **images**, **logs**, **var**. Follow the instructions in the image below.

**Note**: Be careful to enter only lowercase, not uppercase letters.

# 

![Mautic UGREEN NAS Set up 3](https://mariushosting.com/wp-content/uploads/2025/09/Mautic-UGREEN-NAS-Set-up-3.png)

# **STEP 7**

# Log into Portainer using your username and password. On the left sidebar in Portainer, click on **Home** then **Live connect**. Follow the instructions in the image below.

# 

![Portainer Add Stack NAS 1](https://mariushosting.com/wp-content/uploads/2025/02/Portainer-Add-Stack-NAS-1.png)

# On the left sidebar in Portainer, click on **Stacks** then **+ Add stack**. Follow the instructions in the image below.

# 

![Portainer Add Stack NAS 2](https://mariushosting.com/wp-content/uploads/2025/02/Portainer-Add-Stack-NAS-2.png)

# **STEP 8**

# In the Name field type in **mautic**. Follow the instructions in the image below.

# **Note:** Copy Paste the code below in the Portainer Stacks **Web editor**.

# `services: db: image: mysql:8.0 container_name: Mautic-DB healthcheck: test: mysqladmin -p$$MYSQL_ROOT_PASSWORD ping -h localhost interval: 20s start_period: 10s timeout: 10s retries: 3 hostname: mautic_db environment: MYSQL_ROOT_PASSWORD: rootpass MYSQL_DATABASE: mautic MYSQL_USER: mauticuser MYSQL_PASSWORD: mauticpass volumes: - /volume1/docker/mautic/db:/var/lib/mysql:rw restart: on-failure:5 mautic_web: image: mautic/mautic:6-apache container_name: Mautic-WEB healthcheck: test: timeout 10s bash -c ':> /dev/tcp/127.0.0.1/80' || exit 1 interval: 10s timeout: 5s retries: 3 start_period: 90s ports: - 4280:80 environment: MAUTIC_DB_HOST: mautic_db MAUTIC_INSTALL_FORCE: 1 MAUTIC_DB_PORT: 3306 MAUTIC_DB_NAME: mautic MAUTIC_DB_USER: mauticuser MAUTIC_DB_PASSWORD: mauticpass MAUTIC_ADMIN_EMAIL: **yourown@email** MAUTIC_ADMIN_USERNAME: **marius** MAUTIC_ADMIN_PASSWORD: **Mariushosting84@@marius** MAUTIC_URL: **https://mariustic.ddns.net** DOCKER_MAUTIC_ROLE: mautic_web DOCKER_MAUTIC_WORKERS_CONSUME_EMAIL: 2 #or more DOCKER_MAUTIC_WORKERS_CONSUME_HIT: 2 #or more DOCKER_MAUTIC_WORKERS_CONSUME_FAILED: 2 #or more volumes: - /volume1/docker/mautic/config:/var/www/html/config:rw - /volume1/docker/mautic/logs:/var/www/html/var/logs:rw - /volume1/docker/mautic/files:/var/www/html/docroot/media/files:rw - /volume1/docker/mautic/images:/var/www/html/docroot/media/images:rw - /volume1/docker/mautic/cron:/opt/mautic/cron:rw - /volume1/docker/mautic/var:/var/www/html/var:rw depends_on: db: condition: service_healthy restart: on-failure:5 mautic_worker: image: mautic/mautic:6-apache container_name: Mautic-WORKER volumes: - /volume1/docker/mautic/config:/var/www/html/config:rw - /volume1/docker/mautic/logs:/var/www/html/var/logs:rw - /volume1/docker/mautic/files:/var/www/html/docroot/media/files:rw - /volume1/docker/mautic/images:/var/www/html/docroot/media/images:rw - /volume1/docker/mautic/cron:/opt/mautic/cron:rw - /volume1/docker/mautic/var:/var/www/html/var:rw environment: MAUTIC_DB_HOST: mautic_db MAUTIC_INSTALL_FORCE: 1 MAUTIC_DB_PORT: 3306 MAUTIC_DB_NAME: mautic MAUTIC_DB_USER: mauticuser MAUTIC_DB_PASSWORD: mauticpass MAUTIC_ADMIN_EMAIL: **yourown@email** MAUTIC_ADMIN_USERNAME: **marius** MAUTIC_ADMIN_PASSWORD: **Mariushosting84@@marius** MAUTIC_URL: **https://mariustic.ddns.net** DOCKER_MAUTIC_ROLE: mautic_worker DOCKER_MAUTIC_WORKERS_CONSUME_EMAIL: 2 DOCKER_MAUTIC_WORKERS_CONSUME_HIT: 2 DOCKER_MAUTIC_WORKERS_CONSUME_FAILED: 2 depends_on: - db restart: on-failure:5 mautic_cron: image: mautic/mautic:6-apache container_name: Mautic-CRON volumes: - /volume1/docker/mautic/config:/var/www/html/config:rw - /volume1/docker/mautic/logs:/var/www/html/var/logs:rw - /volume1/docker/mautic/files:/var/www/html/docroot/media/files:rw - /volume1/docker/mautic/images:/var/www/html/docroot/media/images:rw - /volume1/docker/mautic/cron:/opt/mautic/cron:rw - /volume1/docker/mautic/var:/var/www/html/var:rw environment: MAUTIC_DB_HOST: mautic_db MAUTIC_INSTALL_FORCE: 1 MAUTIC_DB_PORT: 3306 MAUTIC_DB_NAME: mautic MAUTIC_DB_USER: mauticuser MAUTIC_DB_PASSWORD: mauticpass MAUTIC_ADMIN_EMAIL: **yourown@email** MAUTIC_ADMIN_USERNAME: **marius** MAUTIC_ADMIN_PASSWORD: **Mariushosting84@@marius** MAUTIC_URL: **https://mariustic.ddns.net** DOCKER_MAUTIC_ROLE: mautic_cron depends_on: - db restart: on-failure:5
**CLICK TO COPY 🐋**`

# **Note**: Before you paste the code above in the Web editor area below, change the value for **MAUTIC_ADMIN_EMAIL**. Type in your own Administrator Email. You will need this email later at **STEP 18**.

**Note**: Before you paste the code above in the Web editor area below, change the value for **MAUTIC_ADMIN_USERNAME**. Type in your own username. marius is an example for a username. You will need this username later at **STEP 18**.

**Note**: Before you paste the code above in the Web editor area below, change the value for **MAUTIC_ADMIN_PASSWORD**. Type in your own password. Mariushosting84@@marius is an example for a password. You will need this password later at **STEP 18**. ⚠️**Warning**: Your password must combine uppercase letters (A-Z), lowercase letters (a-z), numbers (0-9), and special characters (e.g., !, @, #, $).

**Note**: Before you paste the code above in the Web editor area below, change the value for **MAUTIC_URL** and type in your own NO IP DDNS address that you have previously created at **STEP 4**, **with** https:// at the beginning.

# 

![Mautic UGREEN NAS Set up 4](https://mariushosting.com/wp-content/uploads/2025/09/Mautic-UGREEN-NAS-Set-up-4.png)

# **STEP 9**

# Scroll down on the page until you see a button named **Deploy the stack**. Click on it. Follow the instructions in the image below. The installation process can take up to a few minutes. It will depend on your Internet speed connection.

# 

![Mautic UGREEN NAS Set up 5](https://mariushosting.com/wp-content/uploads/2025/09/Mautic-UGREEN-NAS-Set-up-5.png)

# **STEP 10**

# If everything goes right, you will see the following message at the top right of your screen: “**Success Stack successfully deployed**“.

# 

![Portainer Success Stack NAS](https://mariushosting.com/wp-content/uploads/2025/02/Portainer-Success-Stack-NAS.png)

# **STEP 11**

# Open your Nginx Proxy Manager container that you have previously installed at **STEP 3**. Click **Add Proxy Host**. A new pop up window will open. Add the following details:

# **Domain Names**: Type in your own **noip domain name** that you have previously created at **STEP 4**.

**Scheme**: **http**

**Forward Hostname/IP**: Type in the **local NAS IP** of your UGREEN NAS.

**Forward Port**: Type in the **Mautic local Port** that is **4280**

**Check** Block Common Exploits

**Check** Websockets Support

Click the **SSL** tab. Follow the instructions in the image below.

# 

![Mautic UGREEN NAS Set up 6](https://mariushosting.com/wp-content/uploads/2025/09/Mautic-UGREEN-NAS-Set-up-6.png)

# **STEP 12**

# After you click the **SSL** tab, add the following details:

# **SSL Certificate**: Request a new SSL Certificate

**Check**: Force SSL

**Check**: HSTS Enabled

**Check**: HTTP/2 Support

**Email Address for Let’s Encrypt**: Type in your own Email Address.

**Check**: I Agree to the Let’s Encrypt Terms of Service.

Click **Save**. Follow the instructions in the image below.

# 

![Mautic UGREEN NAS Set up 7](https://mariushosting.com/wp-content/uploads/2025/09/Mautic-UGREEN-NAS-Set-up-7.png)

# **STEP 13**

# In the Proxy Hosts area, if everything goes right, you will see that your **mautic hostname** has been generated. **Click on it**. Follow the instructions in the image below.

# 

![Mautic UGREEN NAS Set up 8](https://mariushosting.com/wp-content/uploads/2025/09/Mautic-UGREEN-NAS-Set-up-8.png)

# **STEP 14**

# [**🟢Please Support My work by Making a Donation**](https://mariushosting.com/support-my-work/). Almost **99,9%** of the people that install something using my guides **forget to support my work**, or just **ignore STEP 1**. I’ve been very honest about this aspect of my work since the beginning: I don’t run any ADS, I don’t require subscriptions, paid or otherwise, I don’t collect IPs, emails, and I don’t have any referral links from Amazon or other merchants. I also don’t have any POP-UPs or COOKIES. I have repeatedly been told over the years how much I have contributed to the community. It’s something I love doing and have been honest about my passion since the beginning. But **I also Need The Community to Support me Back** to be able to continue doing this work.

# **STEP 15**

# Now open your browser and type in your HTTPS/SSL certificate like this **https://mautic.ddns.net** In my case it’s **https://mariustic.ddns.net** If everything goes right, you will see the **Mautic 6** installation page. Click **Next Step**. Follow the instructions in the image below.

# 

![Mautic UGREEN NAS Set up 9](https://mariushosting.com/wp-content/uploads/2025/09/Mautic-UGREEN-NAS-Set-up-9.png)

# **STEP 16**

# In the Database Setup page, add the following:

# **Database Host**: **mautic_db**

**Database Port**: **3306**

**Database Name**: **mautic**

**Database Prefix**: Leave it empty.

**Database Username**: **mauticuser**

**Database Password**: **mauticpass**

**Backup existing tables**: **Yes**.

**Prefix for backup tables**: **bak_**

# Click **Next Step**. Follow the instructions in the image below.

# 

![Mautic UGREEN NAS Set up 10](https://mariushosting.com/wp-content/uploads/2025/09/Mautic-UGREEN-NAS-Set-up-10.png)

# **STEP 17**

# **Wait** some minutes until the database is created. Go to the next STEP.

# 

![Mautic UGREEN NAS Set up 11](https://mariushosting.com/wp-content/uploads/2025/09/Mautic-UGREEN-NAS-Set-up-11.png)

# **STEP 18**

# Add your Administrator user. Type in the following:

# **Admin Username**: Type in your own (MAUTIC_ADMIN_USERNAME) that you have previously added at **STEP 8**.

**Admin Password**:  Type in your own (MAUTIC_ADMIN_PASSWORD) that you have previously added at **STEP 8**.

**E-Mail Address**: Type in your own (MAUTIC_ADMIN_EMAIL) that you have previously added at **STEP 8**.

# Follow the instructions in the image below.

# 

![Mautic UGREEN NAS Set up 12](https://mariushosting.com/wp-content/uploads/2025/09/Mautic-UGREEN-NAS-Set-up-12.png)

# **STEP 19**

# Type in your own **Email Address** and **Password** that you have previously added at **STEP 18**. Click **Login**. Follow the instructions in the image below.

# 

![Mautic UGREEN NAS Set up 13](https://mariushosting.com/wp-content/uploads/2025/09/Mautic-UGREEN-NAS-Set-up-13.png)

# **STEP 20**

# At the top right of the page, click on the **user icon** then **Account**. On the left sidebar, click **Appearance**. Select your **favorite theme** combination. Click **Save**. Follow the instructions in the image below.

# 

![Mautic UGREEN NAS Set up 14](https://mariushosting.com/wp-content/uploads/2025/09/Mautic-UGREEN-NAS-Set-up-14.png)

# **STEP 21**

# Your **Mautic 6** dashboard at a glance!

# 

![Mautic UGREEN NAS Set up 16](https://mariushosting.com/wp-content/uploads/2025/09/Mautic-UGREEN-NAS-Set-up-16.png)

# **STEP 22**

# [**Step by step guide on how to Set up Email Notifications on Mautic 6**](https://mariushosting.com/synology-set-up-email-notifications-on-mautic-v6/).

# Enjoy Mautic 6!

#