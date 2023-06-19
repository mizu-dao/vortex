#!/bin/bash
for i in {0..35}
do
ETH_FROM=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 cast call 0x0355B7B8cb128fA5692729Ab3AAa199C1753f726 "computeSubroot(uint256)" $i
done