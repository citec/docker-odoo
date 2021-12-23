FROM grupocitec/ubuntubase:20.04
MAINTAINER GrupoCITEC <ops@grupocitec.com>

RUN apt-get update
RUN apt-get install -y sudo
RUN apt-get install -y gnupg2

# Add the PostgreSQL PGP key to verify their Debian packages.
# It should be the same key as https://www.postgresql.org/media/keys/ACCC4CF8.asc
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8


# Add PostgreSQL's repository. It contains the most recent stable release of PostgreSQL, 
# install dependencies as distrib packages when system bindings are required
# some of them extend the basic odoo requirements for a better "apps" compatibility
# most dependencies are distributed as wheel packages at the next step
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ focal-pgdg main" > /etc/apt/sources.list.d/pgdg.list
RUN apt-get install -y postgresql-client-12

# Install python 2 and pip
RUN apt-get -yq install curl
RUN apt-get -yq install python2 python2-dev
RUN curl https://bootstrap.pypa.io/pip/2.7/get-pip.py --output get-pip.py
RUN python2 get-pip.py
RUN ln -s /usr/bin/python2.7 /usr/bin/python
RUN pip install ipython

RUN apt-get -yq install adduser
RUN apt-get -yq install gettext-base
RUN apt-get -yq install ghostscript
RUN apt-get -yq install libpq-dev
RUN apt-get -yq install wget
RUN apt-get -yq install unzip
RUN apt-get -yq install libjpeg-dev libjpeg8-dev libfreetype6-dev zlib1g-dev libpng-dev
RUN pip install pillow
RUN apt-get -yq install libxslt1-dev libxslt1.1
RUN apt-get -yq install xfonts-base xfonts-75dpi
RUN pip install Python-Chart
RUN apt-get -yq install libxrender1 libxext6 fontconfig
# RUN apt-get -yq install python-zsi
RUN pip install lasso
RUN apt-get -yq install libxml2-dev libxslt1-dev
RUN apt-get -yq install python-lxml
RUN apt-get -yq install libldap2-dev libsasl2-dev libssl-dev

# RUN apt-get -yq install \
#             adduser \
#             gettext-base \
#             ghostscript \
#             libpq-dev \
#             wget \
#             unzip \
#             python \
#                 python-dev \
#                 python-pip \
#                 libjpeg-dev libjpeg8-dev libfreetype6-dev zlib1g-dev libpng12-dev \
#                 python-imaging \
#                 python-pil \
#                 python-pychart python-libxslt1 xfonts-base xfonts-75dpi \
#                 libxrender1 libxext6 fontconfig \
#                 python-zsi \
#                 python-lasso \
#                 python-lxml \
#                 libxml2-dev libxslt1-dev \
#                 libldap2-dev libsasl2-dev libssl-dev

# Download and unzip odoo 8.0
RUN wget -O /tmp/odoo.zip https://github.com/odoo/odoo/archive/8.0.zip && \
    unzip -d /odoo /tmp/odoo.zip && \
    mv /odoo/odoo-8.0 /opt/odoo && \
    rm /tmp/odoo.zip

RUN apt-get -yq install build-essential

# Install odoo's python requirements
#ADD requirements.txt /app/requirements.txt
RUN pip install -r /opt/odoo/requirements.txt
RUN pip install psycopg2==2.7.3.2

# Install wkhtmltox
RUN apt-get install -y xvfb
RUN /usr/bin/curl -L https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.focal_amd64.deb > /tmp/wkhtmltox_0.12.6-1.focal_amd64.deb
RUN apt-get install -y libicu66 libicu-dev
RUN dpkg -i /tmp/wkhtmltox_0.12.6-1.focal_amd64.deb
RUN apt-get -f -y install
RUN mv /usr/local/bin/wkhtmltopdf /usr/local/bin/wkhtmltopdf_bin
RUN echo '#!/bin/bash' | tee /usr/local/bin/wkhtmltopdf >/dev/null
RUN echo 'xvfb-run -a -s "-screen 0 640x480x16" /usr/local/bin/wkhtmltopdf_bin "$@"' | tee -a /usr/local/bin/wkhtmltopdf >/dev/null
RUN chmod a+x /usr/local/bin/wkhtmltopdf

# create the odoo user
RUN adduser --home=/opt/odoo --disabled-password --gecos "" --shell=/bin/bash odoo
RUN chown -R odoo:odoo /opt/odoo

# Odoo data folder
RUN mkdir /opt/odoo_data
RUN chown -R odoo:odoo /opt/odoo_data

# Additional requirements
RUN pip install --upgrade pip
RUN pip install paramiko
RUN apt-get install -y  libcurl4-openssl-dev python-pycurl
RUN pip install --upgrade soappy
RUN apt-get install -y default-libmysqlclient-dev
RUN pip install soappy
RUN wget https://raw.githubusercontent.com/paulfitz/mysql-connector-c/master/include/my_config.h -P /usr/include/mysql/
RUN pip install MySQL-python
RUN apt-get install -y libffi-dev
RUN pip install xmltodict sqlalchemy pysftp pyinotify ipdb grequests

# Boot the environment up
USER 0
ADD sources/odoo.conf /etc/odoo/odoo.conf
WORKDIR /app
ADD bin /app/bin/
EXPOSE 8069 8072
