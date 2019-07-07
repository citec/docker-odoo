FROM grupocitec/ubuntubase:16.04
MAINTAINER GrupoCITEC <ops@grupocitec.com>

RUN apt-get update
RUN apt-get install -y sudo

# Add the PostgreSQL PGP key to verify their Debian packages.
# It should be the same key as https://www.postgresql.org/media/keys/ACCC4CF8.asc
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8

# Add PostgreSQL's repository. It contains the most recent stable release of PostgreSQL, 
# install dependencies as distrib packages when system bindings are required
# some of them extend the basic odoo requirements for a better "apps" compatibility
# most dependencies are distributed as wheel packages at the next step
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
        apt-get -yq install \
            adduser \
            gettext-base \
            ghostscript \
            postgresql-client \
            libpq-dev \
            wget \
            unzip \
            python \
                python-dev \
                python-pip \
                libjpeg-dev libjpeg8-dev libfreetype6-dev zlib1g-dev libpng12-dev \
                python-imaging \
                python-pil \
                python-pychart python-libxslt1 xfonts-base xfonts-75dpi \
                libxrender1 libxext6 fontconfig \
                python-zsi \
                python-lasso \
                python-lxml \
                libxml2-dev libxslt1-dev \
                libldap2-dev libsasl2-dev libssl-dev

# Download and unzip odoo 8.0
RUN wget -O /tmp/odoo.zip https://github.com/odoo/odoo/archive/8.0.zip && \
    unzip -d /odoo /tmp/odoo.zip && \
    mv /odoo/odoo-8.0 /opt/odoo && \
    rm /tmp/odoo.zip

# Install odoo's python requirements
#ADD requirements.txt /app/requirements.txt
RUN pip install -r /opt/odoo/requirements.txt

# Install wkhtmltox
RUN mkdir /tmp/wkhtmltox
WORKDIR /tmp/wkhtmltox
RUN wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.3/wkhtmltox-0.12.3_linux-generic-amd64.tar.xz
RUN tar vxf wkhtmltox-0.12.3_linux-generic-amd64.tar.xz 
RUN cp wkhtmltox/bin/wk* /usr/local/bin/

# create the odoo user
RUN adduser --home=/opt/odoo --disabled-password --gecos "" --shell=/bin/bash odoo
RUN chown -R odoo:odoo /opt/odoo

# Odoo data folder
RUN mkdir /opt/odoo_data
RUN chown -R odoo:odoo /opt/odoo_data

# Additional requirements
RUN apt-get install -y  python-paramiko \
                        libcurl4-openssl-dev python-pycurl \
                        python-soappy \
                        python-mysqldb \
                        libffi-dev
RUN pip install --upgrade pip
RUN pip install xmltodict sqlalchemy pysftp pyinotify ipdb grequests

# Boot the environment up
USER 0
ADD sources/odoo.conf /etc/odoo/odoo.conf
WORKDIR /app
ADD bin /app/bin/
EXPOSE 8069 8072
