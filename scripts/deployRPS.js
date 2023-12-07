const hre = require("hardhat");

async function main() {
  // Deploying contracts
  const RPS = await hre.ethers.getContractFactory("RPS");
  const rps = await RPS.deploy();
  console.log(rps);

  console.log("RPS deployed at", rps.address);
  
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
