export ANVIL_PK=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
export ANVIL_RPC=http://127.0.0.1:8545
export PLAYER_PK=0x0f98b3a5774fbfdf19646dba94a6c08f13f4c341502334a57724de46497192c3
export PLAYER_ADDR=0x915f794B36Fd328D362445e3BD66ae4f3A894389


deploy:
	rm -rf broadcast/ && \
	forge script script/$(CTF)/$(CHALL)/Deploy.s.sol:Deploy --private-key $(ANVIL_PK) --rpc-url $(ANVIL_RPC) --broadcast

solve:
	forge script script/$(CTF)/$(CHALL)/Solve.s.sol:Solve --private-key $(PLAYER_PK) --rpc-url $(ANVIL_RPC) --broadcast

run-solution:
	forge script script/$(CTF)/$(CHALL)/solution/Solve.s.sol:Solve --private-key $(PLAYER_PK) --rpc-url $(ANVIL_RPC) --broadcast


anvil:
	anvil -a 1 --balance 1000000000000000000 --disable-code-size-limit