const hre = require("hardhat");

async function main() {
  // Deploying contracts
  const Hasher = await hre.ethers.getContractFactory("Hasher");
  const hasher = await Hasher.deploy();
  console.log(hasher);

  console.log("Hasher deployed at", hasher.address);
  
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
