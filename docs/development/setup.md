# Setup

### Prerequisites

This project depends on:

- [Ruby](https://www.ruby-lang.org/)
- [Ruby on Rails](https://rubyonrails.org/)
- [NodeJS](https://nodejs.org/)
- [Yarn](https://yarnpkg.com/)
- [Postgres](https://www.postgresql.org/)

### Inital setup

- clone the repo
```shell
cd my-parent-directory
git clone https://github.com/ministryofjustice/laa-assure-hmrc-data.git
```

- run the setup script
```shell
bin/setup
```

- run the application
```shell
bin/dev
# OR
yarn build && yarn build:css # first time or when asset changes applied
bin/rails server
```

### Authentication with Azure AD

Retrieve/create local Azure AD secrets for yourself:

- copy `.env.sample` to `.env.development`
- login to [portal.azure.com](https://portal.azure.com/) using your `justice.gov.uk` account
- find the "App registration" called `laa-assure-hmrc-data [local]`
- copy the "Application (client) ID" and set its value as `OMNIAUTH_AZURE_CLIENT_ID` env var
- copy the "Application (tenant) ID" and set its value as `OMNIAUTH_AZURE_TENANT_ID` env var
- select "Certificates & secrets" from the sidebar
- click the "+ New client secret"
- name it `laa-assure-hmrc-data [my-name]`
- accept the default expiry
- click Add to complete
- copy the value of the new secret to `OMNIAUTH_AZURE_CLIENT_SECRET` env var

To run the app locally using Azure AD for authentication you will need to run the rails server over TLS

### Setup localhost to use self-signed certificate for TLS

see [rails development using self-signed certificate](https://madeintandem.com/blog/rails-local-development-https-using-self-signed-ssl-certificate/)

```sh
# create dir to store them, anywhere
mkdir ~/.ssl/

# generate self-signed cert and key, output to the dir created
# you will be asked a load of questions but can leave them blank
openssl req -x509 -sha256 -nodes -newkey rsa:2048 -days 365 -keyout ~/.ssl/localhost.key -out ~/.ssl/localhost.crt

# run rails server using the self-signed certificate
rails s -b "ssl://localhost:3000?key=$HOME/.ssl/localhost.key&cert=$HOME/.ssl/localhost.crt"
```
