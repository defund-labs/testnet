# Joining the defund-private-4

### Install Dependencies

```
# basic dependencies
sudo apt-get update -y && sudo apt upgrade -y && sudo apt-get install make build-essential gcc git jq chrony -y

# install go (v1.19.0+ is required!)
wget https://golang.org/dl/go1.19.4.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.19.4.linux-amd64.tar.gz

# source go
cat <<EOF >> ~/.profile
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export GO111MODULE=on
export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
EOF

source ~/.profile
```

### Install the Defund binary

```
git clone https://github.com/defund-labs/defund
cd defund
git checkout v0.2.2
make install
```

## Initialize Defund Node

```bash
defundd config chain-id defund-private-4
defundd init NODE_NAME
```

Open up the config.toml to edit the seeds and persistent peers:

```bash
cd $HOME/.defund/config
nano config.toml
```

Use page down or arrow keys to get to the line that says seeds = "" and replace it with the following:

```bash
seeds = "d837b7f78c03899d8964351fb95c78e84128dff6@174.83.6.129:30791,f03f3a18bae28f2099648b1c8b1eadf3323cf741@162.55.211.136:26656,f8fa20444c3c56a2d3b4fdc57b3fd059f7ae3127@148.251.43.226:56656,70a1f41dea262730e7ab027bcf8bd2616160a9a9@142.132.202.86:17000,e47e5e7ae537147a23995117ea8b2d4c2a408dcb@172.104.159.69:45656,74e6425e7ec76e6eaef92643b6181c42d5b8a3b8@defund-testnet-seed.itrocket.net:443"
```

Next, add persistent peers:

```bash
persistent_peers = "d837b7f78c03899d8964351fb95c78e84128dff6@174.83.6.129:30791,f03f3a18bae28f2099648b1c8b1eadf3323cf741@162.55.211.136:26656,f8fa20444c3c56a2d3b4fdc57b3fd059f7ae3127@148.251.43.226:56656,70a1f41dea262730e7ab027bcf8bd2616160a9a9@142.132.202.86:17000,
e47e5e7ae537147a23995117ea8b2d4c2a408dcb@172.104.159.69:45656,74e6425e7ec76e6eaef92643b6181c42d5b8a3b8@defund-testnet-seed.itrocket.net:443"
```

Then press ```Ctrl+O``` then enter to save, then ```Ctrl+X``` to exit

## Optimize Defund

```bash
bash $HOME/testnet/scripts/optimize.sh
```

## Genesis State

Download and replace the genesis file:

```bash
cd $HOME/.defund/config

curl -s https://raw.githubusercontent.com/defund-labs/testnet/main/defund-private-4/genesis.json > ~/.defund/config/genesis.json

Please do not skip the next step. Run this command and ensure the right genesis is being used.
```

## Check The Genesis File (DO NOT SKIP)

```bash
# check genesis shasum
sha256sum ~/.defund/config/genesis.json
# output must be: db13a33fbb4048c8701294de79a42a2b5dff599d653c0ee110390783c833208b
# other wise you have an incorrect genesis file
```

Reset private validator file to genesis state:

```bash
defundd tendermint unsafe-reset-all
```

## Add/Recover Keys
To create new keypair - make sure you save the mnemonics!
```bash
defundd keys add <key-name> 
```
Restore existing wallet with mnemonic seed phrase. You will be prompted to enter mnemonic seed. 
```bash
defundd keys add <key-name> --recover
```
Request tokens in [DeFund Discord Faucet](https://discord.com/invite/QuXAdnd7Pc)

## Set Up Defund Service File

Set up a service to allow Defund node to run in the background as well as restart automatically if it runs into any problems:

```bash
sudo tee /lib/systemd/system/defund.service > /dev/null <<EOF
[Unit]
Description=Defund daemon
After=network-online.target
[Service]
User=$USER
ExecStart=${HOME}/go/bin/defundd start
Restart=always
RestartSec=3
LimitNOFILE=infinity
LimitNPROC=infinity
[Install]
WantedBy=multi-user.target
EOF
```


## Start Defund Service

Reload and start the service:

```bash
sudo systemctl daemon-reload
sudo systemctl restart systemd-journald
sudo systemctl start defund
```

Check the status of the service:

```bash
sudo systemctl status defund
```

To see live logs of the service:

```bash
journalctl -f -n 100 -u defund -o cat
```

## Create Validator

Show your public key to be used in the create-validator command below

```bash
defundd tendermint show-validator
```

Create your validator

```bash
defundd tx staking create-validator \
  --amount=1000000ufetf \
  --pubkey=$(defundd tendermint show-validator) \
  --moniker="choose a moniker" \
  --chain-id=defund-private-4 \
  --commission-rate="0.10" \
  --commission-max-rate="0.20" \
  --commission-max-change-rate="0.01" \
  --min-self-delegation="1000000" \
  --gas="auto" \
  --from=<key_name>
```

Confirm your validator is running by using this command

```bash
defundd query tendermint-validator-set | grep "$(defundd tendermint show-address)"
```

## Useful commands

valoper addr
```bash
defundd keys show <key_name> --bech val -a
```

balance
```bash
defundd q bank balances <key_addr>
```

get commission
```bash
defundd tx distribution withdraw-rewards <valoper_addr> --from <key_name> --commission --gas auto -y
```

get rewards
```bash
defundd tx distribution withdraw-all-rewards --from <key_name> --gas auto -y
```

validators (active set)
```bash
defundd q staking validators --limit=2000 -oj \
| jq -r '.validators[] | select(.status=="BOND_STATUS_BONDED") | [(.tokens|tonumber / pow(10;6)), .description.moniker] | @csv' \
| column -t -s"," | tr -d '"'| sort -k1 -n -r | nl
```

delegate
```bash
defundd tx staking delegate <valoper_addr> <amout_tokens>ufetf --from <key_name> --gas auto -y
```

send
```bash
defundd tx bank send <key_name> <wallet_addr> <amout_tokens>ufetf --gas auto -y
```


Happy Investing!
