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
