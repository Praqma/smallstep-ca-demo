# Behind The Firewall Certificate Authority (CA) Demo

The overall goal of this repository is to demonstrate automated SSL certificate **creation** and **renewal** for **behind the firewall** web services so that they can get that [LetsEncrypt](https://letsencrypt.org/) type of experience for automated deployments. **Specifically** for Continuous Integration and Continuous Delivery (CI/CD) situations where there are **hard security requirements** and there is **no access to the internet** from the internal network.

# Why
For web applications, communicating over SSL/HTTPS is a must. Unencrypted traffic over HTTP is a security risk. 

This is nothing new and it is hard to find a public web service in production which is not secured with SSL/HTTPS.

Non production environments is a completely different story though.

As a DevOps consultant I can't count the number of times I have seen **non production**, `dev`, `test`, `qa`, `staging`, environments running plain HTTP.

I think the main reasons for this, generally speaking, is: 

* These environments are often behind a firewall and **not** exposed to the external world. Therefor developers don't really feel the need to aquire a certificate as they feel *safe* on the intranet/LAN.
* The process of getting and renewing a certificate is often time consuming when [LetsEncrypt](https://letsencrypt.org/) cannot be used.
* The process is often manual which does not fit with development processes driven by CI/CD.

Ask any security expert and they will tell you that networks are comprimised all the time and unencrypted traffic is vulnerable. That feeling of safety is **false**.

Development teams who practice CI/CD work at speed. Release cycles are frequent for both old and new deliveries. Waiting on the creation of a certificate is not an option. That new service is going to be deployed to the internal environments. Just not with SSL/HTTPS.

In CI/CD the deployment process is automated. Having automated deployments and tests break while waiting for certificate renewal is not an option.

# Solution
The best way to ensure that any web service is running over HTTPS with a valid certificate is to make it as painless as possible and automated. When you deploy a web service it should just happen!

The solution demo here is a full Certificate Authority on the internal network using Smallstep's CA. 

* A lot of companies already have internal certificates they distribute to hosts on the internal network. The only piece that is missing is the ACME support. You can import existing root certificates into Smallsteps CA if needed.

* Distributing the certificates from one exposed ACME client to the hosts that needs them is just an added complexity.

* There is a CA, provided by [Smallstep](https://github.com/smallstep/certificates), which supports the [ACME](https://en.wikipedia.org/wiki/Automated_Certificate_Management_Environment) protocol. It is **open source**, light weight, and provides multiple ways to provision and manage certificates. 

* The Smallstep CA was built for DevOps and Modern Systems. It can packaged into a container, run on a K8's cluster, automated with provisioning tools like Chef, Ansible, Puppet, etc.

* The internal CA solution is inherently more secure as nothing needs to be exposed to the internet.

# Demo(s)

First off. Kudos to [Smallstep](https://smallstep.com/) for providing their CA as an **open source** implementation. I encourage you to take a look at there website and see what they have going on.

I have dockerized the CA and created docker-compose file to easily spin it up. There is an entrypoint script to initialize the CA with some values defined in a `.env` file. 

I have also dockerized and created docker-compose files for two proxies (Nginx and Traefik) to demonstrate how to get certificate generation and renewal for a simple hello world web service.

I chose Traefik because it has built in support for ACME. You just need to configure the compose file with the proper values (CA, challenge type, etc) and Traefik will handle everything including certificate renewal.

I chose Nginx because it **doesn't** have built in support for ACME. Smallstep also provides an ACME client which supports certifcate generation and renewal. I baked this into the Nginx image and created an entrypoint script to get the certificate generated and run the renewal daemon. The Nginx configuration just references the certificates that the Smallstep ACME client generates and renews. 

## Quick Start

1. Clone this repository and change directory into it.

    Add the follwoing to your /etc/hosts file. 

    ``` 
    127.0.0.1	helloworld.thedukedk.net
    127.0.0.1	internalCA.thedukedk.net
    ``` 

    **NOTE:** You can change the above values to anything you want. Just be sure to change the `SERVER_PROXY_NAME` and `DNS_NAMES` environment variables in the `.env` file to match, along with  `certificatesresolvers` on line 17 of the [traefik-compose.yaml file](clients/traefik/traefik-compose.yaml).

2. Run `docker-compose up -d`

3. Get the fingerprint from the CA by doing a `docker logs step-ca`.

    ``` 
    docker logs step-ca 

    No configuration file found at /home/step/config/ca.json

    Generating root certificate... 
    all done!

    Generating intermediate certificate... 
    all done!

    ✔ Root certificate: /home/step/certs/root_ca.crt
    ✔ Root private key: /home/step/secrets/root_ca_key
    ✔ Root fingerprint: 17096d30163602c2743f10032126f6a09a71cc0ea023879d980584cd4870c5f3  <---------------
    ✔ Intermediate certificate: /home/step/certs/intermediate_ca.crt
    ✔ Intermediate private key: /home/step/secrets/intermediate_ca_key
    ✔ Database folder: /home/step/db
    ✔ Default configuration: /home/step/config/defaults.json
    ✔ Certificate Authority configuration: /home/step/config/ca.json

    Your PKI is ready to go. To generate certificates for individual services see 'step help ca'.
    ``` 

    Add it to the `FINGERPRINT` environment variable in the `.env` file.

4. Copy the root and intermediate certificates from the container to your host and add them to the hosts trust store. I installed Smallstep's CLI on my host and used it to install the certificates in my computers trust store. It packs them into a .pem file for me so I do not have to do this myself.

    `step-cli ca bootstrap --ca-url https://internalCA.thedukedk.net:8443 --fingerprint <FINGERPRINT HERE> --install`

    This is something that would normally be handled by ITOP's and is different for OS's and dsitributions. So you will need to look it up for your OS and distribution.

5. Run one of the proxies to see the generated certificate.

    For Traefik - `docker-compose -f clients/traefik/traefik-compose.yaml up -d`

    The certificate can be found in the `acme.json` file. E.g. `docker exec traefik bash -c "cat acme.json"`

    For Nginx - `docker-compose -f clients/nginx/nginx-compose.yaml up -d`

    The certificate can be found in the `/acme-certificates` directory. E.g. `docker exec nginx bash -c "ls /acme-certificates"`

# Summary

It **is possible** to get automated certificate management for your `dev`, `test`, `QA`, `staging` environments when you are behind the firewall. I used Traefik and Nginx in this demo. But there are lots of ACME clients now. Certbot, Caddy, step-cli from Smallstep, acme.sh, etc. If you want to go down that road, there are even libraries for doing it programmatically.

I would suggest that you invest the time in an internal CA which supports ACME. 

* It is, obviously, more secure. So the security guys will be happier. 
* ITOP's doesn't have to use time manually handling certificates for internal web services. They are happier.
* Developers can automate the whole process and not give it much thought as it fits well with a CI/CD approach. Deployments and tests won't break due to out of date certificates. So they are happier.

All in all, I see this as a win/win/win scenario :-)
