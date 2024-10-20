import { Box, Button, Card, Spinner } from "@radix-ui/themes";
import styles from "../styles/Deposits.module.css";
import { useState } from "react";
import { readContract, writeContract, getAccount } from "@wagmi/core";
import { config } from "../wagmi";
import { erc20Abi } from "viem";
import Staking from "../../abis/Staking.json";

export const Withdraw24Hours = () => {
  const StakingAddress: `0x${string}` =
    "0xDBb750B077Fd6303060c92B330A01e63DDAd8e5c";
  const USDCAddress: `0x${string}` =
    "0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8";
  const mUSDAddress: `0x${string}` =
    "0xCE5Ab14A50b661B8679BF4c55d3397d52F7A9bB4";

  const [flagTypeAction, setFlagTypeAction] = useState<string>("nothing");

  const [amountUSD, setAmountUSD] = useState<number>(0);

  const unstakingUSDC = async () => {
    const amountToDeposit = (
      document.getElementById("amountToDeposit") as HTMLInputElement
    ).value;
    const amountToDepositWei = BigInt(Number(amountToDeposit) * 10 ** 6);
    setFlagTypeAction("waitUnstaking");
    writeContract(config, {
      abi: Staking.abi,
      address: StakingAddress,
      functionName: "unstaking24HoursUSDC",
      args: [amountToDepositWei],
    })
      .then(() => {
        setFlagTypeAction("nothing");
      })
      .catch(() => {
        setFlagTypeAction("nothing");
      });
  };

  return (
    <main className={styles.main}>
      <Box maxWidth="100%">
        <Card>
          <div className={styles.cardContainer}>
            <Box>
              <Card>
                <div className={styles.cardData}>
                  <h3>Cantidad a retirar: </h3>{" "}
                  <div className={styles.cardData__containerTokenInfo}>
                    <p>$</p>
                    <input
                      type="number"
                      placeholder="0"
                      id="amountToDeposit"
                      onChange={(e) => setAmountUSD(Number(e.target.value))}
                    />
                    
                  </div>
                </div>
              </Card>
            </Box>
            <Box>
              <Card asChild>
                <div className={styles.cardData}>
                  <h3>Cantidad de unstake: </h3>
                  <div className={styles.cardData__containerTokenInfo}>
                    <p>{amountUSD}</p>
                    <div className={styles.selectData}>
                      <img src="./usdc.png" alt="token" />
                      <p>USDC</p>
                    </div>
                  </div>
                </div>
              </Card>
            </Box>
            {flagTypeAction === "nothing" ? (
              <Button
                color="indigo"
                variant="solid"
                size="4"
                onClick={unstakingUSDC}
              >
                Retirar
              </Button>
            ) : (
              <Button disabled color="indigo" variant="solid" size="4">
                <Spinner loading />
                Retirar
              </Button>
            )}
          </div>
        </Card>
      </Box>
    </main>
  );
};
