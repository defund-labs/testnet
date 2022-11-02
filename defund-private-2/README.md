# Defund Private Testnet: defund-private-2
### Quick Links
Genesis: https://raw.githubusercontent.com/defund-labs/testnet/main/defund-private-2/genesis.json

Git tag: v0.1.0

Block explorer: **coming soon**

Seeds: `85279852bd306c385402185e0125dffeed36bf22@38.146.3.194:26656`

#### Hardware Requirements
Here are the minimal hardware configs required for running a validator/sentry node
 - 16GB RAM
 - 4vCPUs
 - 200GB Disk space

#### Software Requirements
- Ubuntu 20.04 or higher
- [Go v1.19.1](https://golang.org/doc/install)

### Installation Steps

#### Install Prerequisites 

The following are necessary to build defund from source. 

##### 1. Basic Packages

```sh
# update the local package list and install any available upgrades 
sudo apt-get update && sudo apt upgrade -y 
# install toolchain and ensure accurate time synchronization 
sudo apt-get install make build-essential gcc git jq chrony -y
```


##### 2. Install Go
Follow the instructions [here](https://golang.org/doc/install) to install Go.

Alternatively, for Ubuntu LTS, you can do:

```sh
wget https://golang.org/dl/go1.19.1.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.19.1.linux-amd64.tar.gz
```

Unless you want to configure in a non standard way, then set these in the `.profile` in the user's home (i.e. `~/`) folder.

```sh
cat <<EOF >> ~/.profile
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export GO111MODULE=on
export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
EOF
source ~/.profile
go version
```

Output should be: `go version go1.19.1 linux/amd64`


#### Install Defund from source

##### 1. Clone repository
```sh
git clone https://github.com/defund-labs/defund
cd defund
git checkout v0.1.0
make install
```

#### 2. Init chain
```sh
defundd init <moniker> --chain-id defund-private-2
```

#### 3. Add/recover keys
##### To create new keypair - make sure you save the mnemonics!
```sh
defundd keys add <key-name> 
```

#### 4. Download genesis file
The genesis file is how the node will know what network to connect to.
```sh
wget -O ~/.defund/config/genesis.json https://raw.githubusercontent.com/defund-labs/testnet/main/defund-private-2/genesis.json
```

#### 5. Set seeds
Seeds should be used in lieu of peers for network launch. Seeds generally are more stable, and will handle the peer exchange process for the node.
```sh
export SEEDS=85279852bd306c385402185e0125dffeed36bf22@38.146.3.194:26656
sed -i.bak -e "s/^seeds *=.*/seeds = \"$SEEDS\"/" ~/.defund/config/config.toml
```

#### 6. Set minimum gas prices
For RPC nodes and Validator nodes we recommend setting the following `minimum-gas-prices`.

In `$HOME/.defund/config/app.toml`, set minimum gas prices:
```sh:
sed -i.bak -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0.0025ufetf\"/" ~/.defund/config/app.toml
```

#### 7. Create a Defund service file
We need to create a service file which will run the node in the background. 

```sh
sudo cat <<EOF >> /etc/systemd/system/defundd.service
[Unit]
Description=Defund Service
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$HOME
ExecStart=$HOME/go/bin/defund start
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF
```

#### 8. Start Defund

Finall, we can enable and start the service.

```
sudo systemctl daemon-reload && systemctl enable defundd
sudo systemctl restart defundd && journalctl -o cat -fu defundd
```

