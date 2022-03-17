import { ethers } from "hardhat";

async function main() {
    const [ deployer ] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", await deployer.getAddress());
    console.log("Account balance:", (await deployer.getBalance()).toString());
    console.log("Deploying...");

    const Ico = await ethers.getContractFactory("Ico", deployer);
    const ico = await Ico.deploy();

    await ico.deployed();

    console.log("Ico deployed to: ", ico.address);
    console.log("Token address: ", await ico.tokenAddress())

    console.log("Donating...");
    const options = { value: ethers.utils.parseEther('0.1') };
    const donateTx = await ico.connect(deployer).donate(options);
    await donateTx.wait();

    console.log("Resolving liqudity...");
    const resolveLiquidityTx = await ico.connect(deployer).resolveLiquidity();
    await resolveLiquidityTx.wait();

    console.log("Resolved succesfully")
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
