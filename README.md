# Rewards

Logs all characters in on an account and claims their rewards.

It will automatically build a list of all characters active on an account from the simu authentication service's response.

This standalone tool is ideal for creating a daily login task that runs on a CI service such as [semaphore](https://semaphoreci.com/)

## Why?

Setting up lich on a ci service is really annoying and brittle with a lot of overhead that makes it run relatively slow, it will also not adapt as you activate, deactivate, or transfer characters for a given account meaning it requires a lot more hands on work than is necessary.

## Installation

download the latest release binary from the [releases tab](https://github.com/ondreian/rewards.cr/releases)

## Compiling your own binary

crystal build ./src/cli.cr -o rewards --release

## Usage

the `rewards` tool expects a csv with the columns in the form of `account,password`

```bash
./rewards accounts.csv
```

**IMPORTANT: ALWAYS ENCRYPT YOUR SECRETS WHEN USING A CI SERVICE**

This is an **example** csv with the appropriate format:

```csv
MyAccount,supersecretkeyboardcat
MyOtherAccount,supersupersecretkeyboardcat
```

## Contributing

1. Fork it (<https://github.com/ondreian/rewards.cr/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Benjamin Clos](https://github.com/ondreian) - creator and maintainer
