cleos wallet unlock --password XXXXXXXXXXXXXXXXXXXX...

#in another shell:
#rm -rf ~/.local/share/eosio/nodeos/data
#nodeos -e -p eosio --plugin eosio::chain_api_plugin --plugin eosio::history_api_plugin --contracts-console --verbose-http-errors

set -x

PUBLIC_KEY=EOS5CYr5DvRPZvfpsUGrQ2SnHeywQn66iSbKKXn4JDTbFFr36TRTX
EOSIO_DEV_KEY=EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV

######## create accounts ##############

cleos create account eosio alice $PUBLIC_KEY
cleos create account eosio yield $PUBLIC_KEY
cleos create account eosio eosio.token $PUBLIC_KEY # deploy token with eosio development key

######## deploy example token contract ##############

cleos set contract eosio.token /home/talbaneth/eos/eos_smart_contracts/contracts/Mock/Token Token.wasm --abi Token.abi -p eosio.token@active -f
cleos push action eosio.token create '[ "eosio.token", "1000000000.0000 SYS"]' -p eosio.token@active
cleos push action eosio.token issue '[ "alice", "100.0000 SYS", "deposit" ]' -p eosio.token@active

######## deploy yield contract ##############

eosio-cpp -o eosyield.wasm eosyield.cpp --abigen
cleos set contract yield . eosyield.wasm

######## give ownership over the yield contract to alice ##############
# Give yield account owner permission to eosio.code permission so that the contract itself can modify its own permission settings
cleos get account yield
# the public key here is yield's
cleos set account permission yield owner '{"threshold": 1,"keys": [{"key": "EOS5CYr5DvRPZvfpsUGrQ2SnHeywQn66iSbKKXn4JDTbFFr36TRTX", "weight": 1}],"accounts": [{"permission":{"actor":"yield","permission":"eosio.code"},"weight":1}]}' -p yield@owner
cleos get account yield
cleos push action yield setowner '["alice"]' -p yield@owner;

######## hand over control of the token contract to the yield contract ##############
#update authorities of eosio.token to be controlled solely by the yield account
cleos set account permission eosio.token active "{\"threshold\": 1, \"keys\":[] , \"accounts\":[{\"permission\":{\"actor\":\"yield\",\"permission\":\"active\"},\"weight\":1}], \"waits\":[] }" owner -p eosio.token@owner
cleos set account permission eosio.token owner "{\"threshold\": 1, \"keys\":[] , \"accounts\":[{\"permission\":{\"actor\":\"yield\",\"permission\":\"owner\"},\"weight\":1}], \"waits\":[] }" "" -p eosio.token@owner

######### make sure eosio.token is controlled solely by yield #############
cleos get account eosio.token

######### yield control for 2 seconds ############

cleos push action yield yieldcontrol '[2]' -p alice
cleos get account yield
sleep 3

######### check we can not control the token contract #############
echo "should fail:"
cleos set contract eosio.token /home/talbaneth/eos/eos_smart_contracts/contracts/Network Network.wasm --abi Network.abi -p eosio.token@active -f
cleos push action eosio.token issue '[ "alice", "100.0000 SYS", "deposit" ]' -p eosio.token@active

######### regaing control and make sure we have control ###########
cleos push action yield regain '[]' -p alice
echo "should succeed:"
cleos push action eosio.token issue '[ "alice", "100.0000 SYS", "deposit" ]' -p eosio.token@active
cleos set contract eosio.token /home/talbaneth/eos/eos_smart_contracts/contracts/Network Network.wasm --abi Network.abi -p eosio.token@active -f

#more optional commands
#cleos push action yield extend '[10]' -p alice
#cleos get table yield yield yieldinfo
#cleos push action yield regain


